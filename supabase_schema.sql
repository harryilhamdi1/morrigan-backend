-- ======================================================================================
-- SUPABASE SCHEMA INITIALIZATION SCRIPT (PHASE 4)
-- Copy and paste this entirely into Supabase -> SQL Editor -> New Query
-- Note: This will safely DROP existing tables in this schema before creating new ones!
-- ======================================================================================

DROP TABLE IF EXISTS dialogues CASCADE;
DROP TABLE IF EXISTS qualitative_feedback CASCADE;
DROP TABLE IF EXISTS granular_scores CASCADE;
DROP TABLE IF EXISTS journey_scores CASCADE;
DROP TABLE IF EXISTS kpi_scores CASCADE;
DROP TABLE IF EXISTS approvals CASCADE;
DROP TABLE IF EXISTS action_plans CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS stores CASCADE;

DROP TYPE IF EXISTS action_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- 1. Create specific custom ENUM types
CREATE TYPE action_status AS ENUM ('pending', 'in_progress', 'head_approved', 'approved');
CREATE TYPE user_role AS ENUM ('superadmin', 'admin', 'regional', 'branch', 'store');

-- 2. 🏢 STORES TABLE
-- Stores basic meta information about the branches and regions
CREATE TABLE stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_code TEXT UNIQUE, -- e.g., '2019'
    store_name TEXT NOT NULL UNIQUE,
    region TEXT NOT NULL,
    branch TEXT NOT NULL,
    liga TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 👥 PROFILES (Authentication Extension)
-- Links Supabase Auth Users to specific roles/stores.
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    rank TEXT,
    role user_role NOT NULL,
    region_scope TEXT,                  -- Set for regional, e.g., 'REGION 1'
    branch_scope TEXT,                  -- Set for branch, e.g., 'DKI 4'
    store_scope TEXT,                   -- Assigned Site Code (for store only), e.g., '2019'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 🎯 ACTION PLANS TABLE
-- Represents the tasks generated for a store. Links to the store's UUID.
CREATE TABLE action_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    category TEXT NOT NULL,             -- Core issue tag (e.g., Staff Availability)
    finding_source TEXT NOT NULL,       -- Original insight from AI
    action_required TEXT NOT NULL,      -- Suggested fix
    pic TEXT DEFAULT 'Head of Store',   -- Person In Charge
    timeline_week INTEGER NOT NULL,     -- Week 1, 2, 3, or 4
    status action_status DEFAULT 'pending', -- Current execution state
    execution_proof_link TEXT,          -- URL to Google Drive attachment
    execution_remarks TEXT,             -- Remarks typed by Store Head
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 📝 APPROVALS TABLE
-- Tracks the specific approval notes from Head of Branch and HCBP.
CREATE TABLE approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_plan_id UUID NOT NULL REFERENCES action_plans(id) ON DELETE CASCADE UNIQUE,
    hob_approved BOOLEAN DEFAULT FALSE,
    hob_remarks TEXT,
    hob_approved_at TIMESTAMP WITH TIME ZONE,
    hcbp_approved BOOLEAN DEFAULT FALSE,
    hcbp_remarks TEXT,
    hcbp_approved_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 📊 KPI SCORES TABLE
-- Stores overall wave scores per store
CREATE TABLE kpi_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    wave_name TEXT NOT NULL, -- e.g., 'Wave 1'
    wave_year INTEGER NOT NULL, -- e.g., 2024
    score NUMERIC(5,2),
    achieved_score NUMERIC(5,2),
    max_score NUMERIC(5,2),
    UNIQUE(store_id, wave_name, wave_year)
);

-- 7. 🗺️ JOURNEY SCORES TABLE
-- Stores Section A-L scores per wave
CREATE TABLE journey_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_score_id UUID NOT NULL REFERENCES kpi_scores(id) ON DELETE CASCADE,
    section_name TEXT NOT NULL, -- e.g., 'A. Tampilan Tampak Depan Outlet'
    section_letter TEXT NOT NULL, -- e.g., 'A'
    score NUMERIC(5,2),
    achieved_score NUMERIC(5,2),
    max_score NUMERIC(5,2),
    UNIQUE(kpi_score_id, section_letter)
);

-- 8. 📝 GRANULAR SCORES TABLE
-- Stores individual question scores (e.g., A.1, A.2)
CREATE TABLE granular_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_score_id UUID NOT NULL REFERENCES kpi_scores(id) ON DELETE CASCADE,
    section_letter TEXT NOT NULL, -- e.g., 'A'
    item_code TEXT NOT NULL,      -- e.g., '759146'
    item_name TEXT NOT NULL,      -- e.g., 'Kondisi Fasad Outlet...'
    score NUMERIC(5,2),           -- 1, 0, or null
    failed_reason TEXT,           -- Text reason if score is 0
    UNIQUE(kpi_score_id, item_code)
);

-- 9. 🗣️ QUALITATIVE FEEDBACK TABLE
-- Stores individual qualitative observations and feedback
CREATE TABLE qualitative_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_score_id UUID NOT NULL REFERENCES kpi_scores(id) ON DELETE CASCADE,
    feedback_text TEXT NOT NULL,
    sentiment TEXT,               -- 'positive', 'negative', 'neutral'
    category TEXT,
    themes TEXT[],                -- Array of identified themes
    staff_name TEXT,
    source_column TEXT
);

-- 10. 💬 DIALOGUES TABLE
-- Stores interaction dialogues (Customer Question & RA Answer)
CREATE TABLE dialogues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kpi_score_id UUID NOT NULL REFERENCES kpi_scores(id) ON DELETE CASCADE,
    customer_question TEXT,
    ra_answer TEXT,
    member_benefits TEXT,
    UNIQUE(kpi_score_id)
);

-- ======================================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ======================================================================================

ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE action_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE journey_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE granular_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE qualitative_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE dialogues ENABLE ROW LEVEL SECURITY;

-- 🛡️ PROFILES Policy
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Superadmins can update profiles" ON profiles FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'superadmin')
);

-- 🛡️ STORES Policy: Everyone can read stores
CREATE POLICY "Stores are viewable by everyone" ON stores FOR SELECT TO authenticated USING (true);
CREATE POLICY "Superadmins and Admins can insert/update stores" ON stores FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

-- 🛡️ KPI SCORES & JOURNEY SCORES Policy: Everyone can read (Dashboard needs it), Superadmin/Admin can edit
CREATE POLICY "KPI Scores viewable by everyone" ON kpi_scores FOR SELECT TO authenticated USING (true);
CREATE POLICY "Superadmins and Admins can manage KPI Scores" ON kpi_scores FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

CREATE POLICY "Journey Scores viewable by everyone" ON journey_scores FOR SELECT TO authenticated USING (true);
CREATE POLICY "Superadmins and Admins can manage Journey Scores" ON journey_scores FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

CREATE POLICY "Granular Scores viewable by everyone" ON granular_scores FOR SELECT TO authenticated USING (true);
CREATE POLICY "Superadmins and Admins can manage Granular Scores" ON granular_scores FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

CREATE POLICY "Qualitative Feedback viewable by everyone" ON qualitative_feedback FOR SELECT TO authenticated USING (true);
CREATE POLICY "Superadmins and Admins can manage Qualitative Feedback" ON qualitative_feedback FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

CREATE POLICY "Dialogues viewable by everyone" ON dialogues FOR SELECT TO authenticated USING (true);
CREATE POLICY "Superadmins and Admins can manage Dialogues" ON dialogues FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

-- 🛡️ ACTION PLANS Policy
-- Read: 
-- Superadmin/Admin: All
-- Regional: Only stores in their region
-- Branch: Only stores in their branch
-- Store: Only their store
CREATE POLICY "Action Plans Read Access" ON action_plans FOR SELECT TO authenticated USING (
    EXISTS (
        SELECT 1 FROM profiles p 
        WHERE p.id = auth.uid() AND (
            p.role IN ('superadmin', 'admin') OR
            (p.role = 'regional' AND EXISTS (SELECT 1 FROM stores s WHERE s.id = action_plans.store_id AND s.region = p.region_scope)) OR
            (p.role = 'branch' AND EXISTS (SELECT 1 FROM stores s WHERE s.id = action_plans.store_id AND s.branch = p.branch_scope)) OR
            (p.role = 'store' AND EXISTS (SELECT 1 FROM stores s WHERE s.id = action_plans.store_id AND s.site_code = p.store_scope))
        )
    )
);

-- Write/Update (Store Head changing status/uploading proof)
CREATE POLICY "Action Plans Store Update" ON action_plans FOR UPDATE TO authenticated USING (
    EXISTS (
        SELECT 1 FROM profiles p 
        JOIN stores s ON s.site_code = p.store_scope
        WHERE p.id = auth.uid() 
        AND s.id = action_plans.store_id 
        AND p.role = 'store'
    )
);
-- Superadmin/Admin can also manage action plans
CREATE POLICY "Action Plans Admin Management" ON action_plans FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

-- 🛡️ APPROVALS Policy
-- Read: Follows Action Plan logic implicitly or keep it simple
CREATE POLICY "Approvals Read Access" ON approvals FOR SELECT TO authenticated USING (true);

-- Update: HCBP (admin), HoB (branch), Superadmin
CREATE POLICY "Approvals Management Update" ON approvals FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin', 'branch'))
);
CREATE POLICY "Approvals Admin Management" ON approvals FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('superadmin', 'admin'))
);

-- 🌟 Create a shortcut view for the dashboard to aggregate easily
CREATE OR REPLACE VIEW vw_dashboard_metrics AS 
SELECT 
    s.region, 
    s.branch,
    s.store_name,
    COUNT(ap.id) as total_plans,
    COUNT(CASE WHEN ap.status = 'approved' THEN 1 END) as completed_plans,
    COUNT(CASE WHEN ap.status IN ('in_progress', 'head_approved') THEN 1 END) as in_progress_plans,
    COUNT(CASE WHEN ap.status = 'pending' THEN 1 END) as pending_plans
FROM stores s 
LEFT JOIN action_plans ap ON s.id = ap.store_id
GROUP BY s.region, s.branch, s.store_name;
