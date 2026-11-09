-- ============================================================================
-- HUTECH EVENT INTELLIGENCE — PHASE 5, 8 & 10:
-- KHẢO SÁT, PHẢN HỒI, CHỨNG NHẬN, HỎI ĐÁP & CƠ SỞ HUTECH
-- ============================================================================

-- ============================================================================
-- 1. CƠ SỞ HUTECH (HUTECH CAMPUSES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.campuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    description TEXT DEFAULT '',
    image_url TEXT DEFAULT '',
    travel_instructions TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Dữ liệu cơ sở HUTECH chính thức
INSERT INTO public.campuses (code, name, address, description, travel_instructions)
VALUES 
    ('CAMPUS_AB', 'Trụ sở Điện Biên Phủ (Khu A & B)', '475A Điện Biên Phủ, P.25, Q. Bình Thạnh, TP.HCM', 'Khu trung tâm hành chính, hội trường lớn A-08.20', 'Tuyến xe buýt: 08, 19, 54, 104; Trạm xe buýt Ngã tư Hàng Xanh.'),
    ('CAMPUS_E', 'Trung tâm Đào tạo Nhân lực CLC (Khu E)', 'Khu Công nghệ cao TP.HCM, Xa lộ Hà Nội, P. Long Thạnh Mỹ, TP. Thủ Đức', 'Viện Công nghệ cao, Không gian sáng tạo và Maker Space', 'Tuyến Metro số 1 Bến Thành - Suối Tiên; Xe buýt 55, 56, 150.')
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- 2. KHẢO SÁT & ĐÁNH GIÁ TRƯỚC/SAU SỰ KIỆN (SURVEYS & FEEDBACKS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.event_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    registration_id UUID NOT NULL REFERENCES public.registrations(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.event_surveys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    survey_type VARCHAR(30) NOT NULL CHECK (survey_type IN ('pre_event', 'post_event')),
    deadline TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.survey_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID NOT NULL REFERENCES public.event_surveys(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(30) NOT NULL CHECK (question_type IN ('single_choice', 'multiple_choice', 'text', 'scale')),
    options JSONB DEFAULT '[]'::jsonb,
    sort_order INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.survey_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID NOT NULL REFERENCES public.event_surveys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    answers JSONB NOT NULL DEFAULT '{}'::jsonb,
    score NUMERIC(5,2),
    submitted_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(survey_id, user_id)
);

-- ============================================================================
-- 3. MINH CHỨNG KỸ NĂNG & CHỨNG NHẬN (SKILL EVIDENCE & CERTIFICATES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.skill_evidences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    evidence_source TEXT NOT NULL DEFAULT 'HUTECH Event Attendance',
    level VARCHAR(30) DEFAULT 'Cơ bản',
    verified_at TIMESTAMPTZ DEFAULT now(),
    verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status VARCHAR(30) DEFAULT 'verified' CHECK (status IN ('pending', 'verified', 'revoked')),
    UNIQUE(user_id, event_id, skill_name)
);

CREATE TABLE IF NOT EXISTS public.event_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_code VARCHAR(100) UNIQUE NOT NULL,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    registration_id UUID NOT NULL REFERENCES public.registrations(id) ON DELETE CASCADE,
    issued_at TIMESTAMPTZ DEFAULT now(),
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_reason TEXT,
    revoked_at TIMESTAMPTZ,
    UNIQUE(event_id, user_id)
);

-- ============================================================================
-- 4. HỎI ĐÁP THEO SỰ KIỆN THỜI GIAN THỰC (REALTIME EVENT Q&A)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.event_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    attachment_url TEXT,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.event_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.event_questions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.campuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skill_evidences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_answers ENABLE ROW LEVEL SECURITY;

-- Campuses
CREATE POLICY "Campuses viewable by everyone" ON public.campuses FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Admins manage campuses" ON public.campuses FOR ALL TO authenticated USING (public.is_admin());

-- Feedbacks: chỉ sinh viên tham dự mới được gửi phản hồi
CREATE POLICY "Feedbacks viewable by admins and organizers"
    ON public.event_feedbacks FOR SELECT
    TO authenticated
    USING (public.is_admin() OR public.is_organizer_for_event(event_id) OR user_id = auth.uid());

CREATE POLICY "Attendees can submit feedback"
    ON public.event_feedbacks FOR INSERT
    TO authenticated
    WITH CHECK (
        user_id = auth.uid() AND EXISTS (
            SELECT 1 FROM public.registrations r 
            WHERE r.id = registration_id AND r.user_id = auth.uid() AND r.status = 'attended'
        )
    );

-- Certificates: sinh viên xem chứng nhận của mình, kiểm tra mã chứng nhận công khai
CREATE POLICY "Certificates viewable by owner or verified by code"
    ON public.event_certificates FOR SELECT
    TO authenticated, anon
    USING (user_id = auth.uid() OR public.is_admin() OR is_revoked = FALSE);

-- Q&A
CREATE POLICY "Questions viewable by authenticated users"
    ON public.event_questions FOR SELECT
    TO authenticated
    USING (is_hidden = FALSE OR public.is_admin() OR public.is_organizer_for_event(event_id));

CREATE POLICY "Authenticated users can ask questions"
    ON public.event_questions FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Answers viewable by authenticated users"
    ON public.event_answers FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users and organizers can answer"
    ON public.event_answers FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());
