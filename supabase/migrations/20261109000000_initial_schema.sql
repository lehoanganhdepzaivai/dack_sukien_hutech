-- ============================================================================
-- HUTECH EVENT INTELLIGENCE — SUPABASE SCHEMA MIGRATION (PHASE 1)
-- ============================================================================
-- Mô tả: Khởi tạo toàn bộ cấu trúc bảng, RLS, Storage Buckets, Triggers,
-- và RPC functions cho hệ thống Quản lý Sự kiện Sinh viên HUTECH.
-- ============================================================================

-- Bật extension pgcrypto (hỗ trợ gen_random_uuid())
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. BẢNG PHÂN QUYỀN (ROLES & USER_ROLES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Dữ liệu vai trò chuẩn
INSERT INTO public.roles (code, name, description)
VALUES 
    ('admin', 'Quản trị viên', 'Quản lý toàn bộ hệ thống'),
    ('organizer', 'Ban tổ chức', 'Quản lý và tổ chức các sự kiện được phân công'),
    ('student', 'Sinh viên', 'Đăng ký, tham gia và theo dõi sự kiện'),
    ('guest', 'Khách', 'Xem thông tin sự kiện công khai')
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- 2. KHOA/VIỆN & CHUYÊN NGÀNH (FACULTIES & MAJORS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.faculties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.majors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID NOT NULL REFERENCES public.faculties(id) ON DELETE CASCADE,
    code VARCHAR(50) UNIQUE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 3. HỒ SƠ NGƯỜI DÙNG (PROFILES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL DEFAULT '',
    student_code VARCHAR(30) UNIQUE,
    phone VARCHAR(20) DEFAULT '',
    faculty_id UUID REFERENCES public.faculties(id) ON DELETE SET NULL,
    major_id UUID REFERENCES public.majors(id) ON DELETE SET NULL,
    cohort VARCHAR(20) DEFAULT '',
    career_goal TEXT DEFAULT '',
    preferred_venue VARCHAR(100) DEFAULT 'HUTECH khu E',
    available_start_minutes INT DEFAULT 420,
    available_end_minutes INT DEFAULT 1320,
    avatar_url TEXT DEFAULT '',
    interests TEXT[] DEFAULT '{}',
    skills TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, role_id)
);

-- ============================================================================
-- 4. ĐƠN VỊ TỔ CHỨC, DANH MỤC & ĐỊA ĐIỂM
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    faculty_id UUID REFERENCES public.faculties(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    kind VARCHAR(50) DEFAULT 'Khoa/Viện',
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.event_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    campus VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    capacity INT DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 5. SỰ KIỆN & BAN TỔ CHỨC SỰ KIỆN (EVENTS & EVENT_ORGANIZERS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE,
    title TEXT NOT NULL,
    subtitle TEXT DEFAULT '',
    description TEXT DEFAULT '',
    category_id UUID REFERENCES public.event_categories(id) ON DELETE SET NULL,
    category_name TEXT DEFAULT '',
    organization_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
    organization_name TEXT DEFAULT '',
    venue_id UUID REFERENCES public.venues(id) ON DELETE SET NULL,
    venue_name TEXT NOT NULL,
    cover_image TEXT DEFAULT '',
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    registration_deadline TIMESTAMPTZ NOT NULL,
    capacity INT NOT NULL DEFAULT 50 CHECK (capacity >= 0),
    status VARCHAR(30) NOT NULL DEFAULT 'draft' CHECK (
        status IN (
            'draft', 'pending', 'published', 'registration_open', 
            'full', 'registration_closed', 'ongoing', 'completed', 
            'canceled', 'archived'
        )
    ),
    is_featured BOOLEAN DEFAULT FALSE,
    skills TEXT[] DEFAULT '{}',
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.event_organizers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.event_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    is_cover BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 6. LỊCH HỌC SINH VIÊN (SCHEDULES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_name TEXT NOT NULL,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 2 AND 8),
    start_period INT NOT NULL CHECK (start_period BETWEEN 1 AND 16),
    end_period INT NOT NULL CHECK (end_period >= start_period AND end_period <= 16),
    room TEXT DEFAULT '',
    venue TEXT DEFAULT 'HUTECH khu E',
    term_start DATE,
    term_end DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 7. ĐĂNG KÝ, HÀNG CHỜ VÀ YÊU THÍCH (REGISTRATIONS, WAITLIST, FAVORITES)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL CHECK (status IN ('confirmed', 'waitlisted', 'canceled', 'attended')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    queue_position INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, event_id)
);

CREATE TABLE IF NOT EXISTS public.event_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    viewed_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 8. THÔNG BÁO & AUDIT LOG (NOTIFICATIONS & AUDIT_LOGS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'general',
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(50) NOT NULL,
    entity_id TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 9. INDEXES NÂNG CAO HIỆU NĂNG
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_events_status_start ON public.events(status, start_at);
CREATE INDEX IF NOT EXISTS idx_events_category ON public.events(category_id);
CREATE INDEX IF NOT EXISTS idx_events_venue ON public.events(venue_id);
CREATE INDEX IF NOT EXISTS idx_registrations_user ON public.registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_registrations_event ON public.registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_schedules_user ON public.schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_action ON public.audit_logs(user_id, action);

-- ============================================================================
-- 10. HÀM KIỂM TRA PHÂN QUYỀN (SECURITY HELPER FUNCTIONS)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.current_user_has_role(role_name text)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = auth.uid()
          AND r.code = role_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
    RETURN public.current_user_has_role('admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_organizer_for_event(target_event_id uuid)
RETURNS boolean AS $$
BEGIN
    IF public.is_admin() THEN
        RETURN TRUE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.event_organizers eo
        WHERE eo.event_id = target_event_id
          AND eo.user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 11. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faculties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.majors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_organizers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 11.1 Profiles
CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- 11.2 Roles & User Roles
CREATE POLICY "Roles are readable by everyone"
    ON public.roles FOR SELECT
    TO authenticated, anon
    USING (true);

CREATE POLICY "User roles viewable by everyone"
    ON public.user_roles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins can modify user roles"
    ON public.user_roles FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 11.3 Metadata (Faculties, Majors, Categories, Venues, Organizations)
CREATE POLICY "Metadata viewable by everyone"
    ON public.faculties FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Majors viewable by everyone"
    ON public.majors FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Categories viewable by everyone"
    ON public.event_categories FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Venues viewable by everyone"
    ON public.venues FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Organizations viewable by everyone"
    ON public.organizations FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Only admins manage faculties" ON public.faculties FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Only admins manage majors" ON public.majors FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Only admins manage categories" ON public.event_categories FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Only admins manage venues" ON public.venues FOR ALL TO authenticated USING (public.is_admin());
CREATE POLICY "Only admins manage organizations" ON public.organizations FOR ALL TO authenticated USING (public.is_admin());

-- 11.4 Events
CREATE POLICY "Public events readable by everyone"
    ON public.events FOR SELECT
    TO authenticated, anon
    USING (
        deleted_at IS NULL AND (
            status NOT IN ('draft', 'pending', 'archived')
            OR public.is_admin()
            OR (auth.uid() IS NOT NULL AND EXISTS (
                SELECT 1 FROM public.event_organizers eo 
                WHERE eo.event_id = events.id AND eo.user_id = auth.uid()
            ))
        )
    );

CREATE POLICY "Admins have full access to events"
    ON public.events FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "Organizers can update assigned events"
    ON public.events FOR UPDATE
    TO authenticated
    USING (public.is_organizer_for_event(id))
    WITH CHECK (public.is_organizer_for_event(id));

-- 11.5 Event Organizers
CREATE POLICY "Event organizers readable by authenticated users"
    ON public.event_organizers FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins can manage event organizers"
    ON public.event_organizers FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 11.6 Schedules
CREATE POLICY "Users can only read and manage their own schedules"
    ON public.schedules FOR ALL
    TO authenticated
    USING (user_id = auth.uid() OR public.is_admin())
    WITH CHECK (user_id = auth.uid());

-- 11.7 Registrations & Waitlist
CREATE POLICY "Users can view their own registrations, admins & organizers view event registrations"
    ON public.registrations FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid() 
        OR public.is_admin() 
        OR public.is_organizer_for_event(event_id)
    );

CREATE POLICY "Users can register themselves"
    ON public.registrations FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can cancel their registration"
    ON public.registrations FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid() OR public.is_admin() OR public.is_organizer_for_event(event_id))
    WITH CHECK (user_id = auth.uid() OR public.is_admin() OR public.is_organizer_for_event(event_id));

-- 11.8 Favorites
CREATE POLICY "Users manage their own favorites"
    ON public.favorites FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- 11.9 Notifications
CREATE POLICY "Users view and read their own notifications"
    ON public.notifications FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- 11.10 Audit Logs
CREATE POLICY "Audit logs only viewable by admins"
    ON public.audit_logs FOR SELECT
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Audit logs insertable by system or users"
    ON public.audit_logs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ============================================================================
-- 12. TRIGGER TỰ ĐỘNG TẠO PROFILE KHI ĐĂNG KÝ QUA SUPABASE AUTH
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
    default_role_id uuid;
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
    );

    SELECT id INTO default_role_id FROM public.roles WHERE code = 'student';
    IF default_role_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (new.id, default_role_id);
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 13. STORAGE BUCKETS (CẤU HÌNH QUA SQL)
-- ============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('event-images', 'event-images', true),
    ('avatars', 'avatars', true),
    ('event-documents', 'event-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Policy cho storage event-images (ai cũng xem được, chỉ admin/organizer tải lên)
CREATE POLICY "Public view event images"
    ON storage.objects FOR SELECT
    TO authenticated, anon
    USING (bucket_id = 'event-images');

CREATE POLICY "Admin and organizers upload event images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'event-images' AND (
            public.is_admin() OR public.current_user_has_role('organizer')
        )
    );
