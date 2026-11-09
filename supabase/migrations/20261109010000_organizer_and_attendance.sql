-- ============================================================================
-- HUTECH EVENT INTELLIGENCE — PHASE 2 & 3: ORGANIZER WORKFLOW & SECURE ATTENDANCE
-- ============================================================================

-- ============================================================================
-- 1. NHẬT KÝ DUYỆT SỰ KIỆN (EVENT APPROVAL LOGS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.event_approval_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL CHECK (
        action IN ('submitted', 'approved', 'rejected', 'revision_requested', 'revoked')
    ),
    comment TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_approval_event ON public.event_approval_logs(event_id);

-- ============================================================================
-- 2. PHIÊN ĐIỂM DANH (ATTENDANCE SESSIONS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.attendance_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    opened_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_attendance_sessions_event ON public.attendance_sessions(event_id, is_active);

-- ============================================================================
-- 3. VÉ ĐIỆN TỬ VÀ TOKEN ĐIỂM DANH MÃ HÓA (TICKET TOKENS & ATTENDANCE)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    registration_id UUID NOT NULL REFERENCES public.registrations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    session_id UUID REFERENCES public.attendance_sessions(id) ON DELETE SET NULL,
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_attended BOOLEAN DEFAULT FALSE,
    attended_at TIMESTAMPTZ,
    checked_in_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    method VARCHAR(30) CHECK (method IN ('qr', 'manual')),
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_records_token ON public.attendance_records(token_hash);
CREATE INDEX IF NOT EXISTS idx_attendance_records_event ON public.attendance_records(event_id, is_attended);

-- ============================================================================
-- 4. RPC FUNCTION: TIÊU THỤ TOKEN ĐIỂM DANH AN TOÀN (TRANSACTION CHECK-IN)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_in_ticket(
    p_event_id UUID,
    p_token_hash TEXT,
    p_operator_id UUID,
    p_method VARCHAR(30),
    p_reason TEXT DEFAULT ''
)
RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_record RECORD;
    v_event RECORD;
BEGIN
    -- 1. Kiểm tra sự kiện tồn tại
    SELECT * INTO v_event FROM public.events WHERE id = p_event_id AND deleted_at IS NULL;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Sự kiện không tồn tại.');
    END IF;

    -- 2. Kiểm tra phiên điểm danh đang mở
    SELECT * INTO v_session 
    FROM public.attendance_sessions 
    WHERE event_id = p_event_id AND is_active = TRUE 
    ORDER BY opened_at DESC 
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Phiên điểm danh chưa được mở cho sự kiện này.');
    END IF;

    -- 3. Tìm vé và token
    SELECT * INTO v_record 
    FROM public.attendance_records 
    WHERE event_id = p_event_id AND token_hash = p_token_hash;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Mã vé không hợp lệ hoặc không thuộc sự kiện này.');
    END IF;

    -- 4. Kiểm tra vé đã điểm danh chưa
    IF v_record.is_attended THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Vé này đã được điểm danh trước đó lúc ' || to_char(v_record.attended_at, 'HH24:MI:SS DD/MM/YYYY')
        );
    END IF;

    -- 5. Kiểm tra thời hạn token
    IF now() > v_record.expires_at THEN
        RETURN jsonb_build_object('success', false, 'message', 'Mã vé/QR đã hết hạn hiệu lực. Vui lòng làm mới vé.');
    END IF;

    -- 6. Cập nhật trạng thái điểm danh & đăng ký trong cùng transaction
    UPDATE public.attendance_records
    SET is_attended = TRUE,
        attended_at = now(),
        checked_in_by = p_operator_id,
        session_id = v_session.id,
        method = p_method,
        notes = p_reason
    WHERE id = v_record.id;

    UPDATE public.registrations
    SET status = 'attended',
        updated_at = now()
    WHERE id = v_record.registration_id;

    -- 7. Ghi audit log
    INSERT INTO public.audit_logs (user_id, action, entity, entity_id, details)
    VALUES (
        p_operator_id, 
        'CHECK_IN_ATTENDEE', 
        'attendance_records', 
        v_record.id::text, 
        jsonb_build_object(
            'event_id', p_event_id,
            'user_id', v_record.user_id,
            'method', p_method,
            'reason', p_reason
        )
    );

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Điểm danh thành công!', 
        'user_id', v_record.user_id,
        'attended_at', now()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS) CHO BẢNG MỚI
-- ============================================================================

ALTER TABLE public.event_approval_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Approval logs viewable by admins and organizers"
    ON public.event_approval_logs FOR SELECT
    TO authenticated
    USING (public.is_admin() OR public.is_organizer_for_event(event_id));

CREATE POLICY "Admins and organizers manage attendance sessions"
    ON public.attendance_sessions FOR ALL
    TO authenticated
    USING (public.is_admin() OR public.is_organizer_for_event(event_id))
    WITH CHECK (public.is_admin() OR public.is_organizer_for_event(event_id));

CREATE POLICY "Users view own attendance, organizers view event attendance"
    ON public.attendance_records FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid() 
        OR public.is_admin() 
        OR public.is_organizer_for_event(event_id)
    );
