-- ============================================
-- SPERA ADMIN TABLES FOR SUPABASE
-- Run this in your Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: CREATE TABLES FIRST
-- ============================================

-- KNOWLEDGE REQUESTS TABLE
CREATE TABLE IF NOT EXISTS knowledge_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('problem', 'skill', 'situation')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'matched', 'delivered', 'failed')),
    matched_drop_id TEXT,
    generated_drop_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estimated_delivery_minutes INTEGER,
    extracted_tags TEXT[] DEFAULT '{}'
);

-- USER REPORTS TABLE
CREATE TABLE IF NOT EXISTS user_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    drop_id TEXT NOT NULL,
    drop_title TEXT NOT NULL,
    issue_type TEXT NOT NULL CHECK (issue_type IN ('transcript_error', 'audio_problem', 'inaccurate_info', 'inappropriate_content', 'other')),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    admin_notes TEXT
);

-- ============================================
-- STEP 2: DROP EXISTING POLICIES (if any)
-- ============================================

DROP POLICY IF EXISTS "Users can read own requests" ON knowledge_requests;
DROP POLICY IF EXISTS "Users can create requests" ON knowledge_requests;
DROP POLICY IF EXISTS "Admin can read all requests" ON knowledge_requests;
DROP POLICY IF EXISTS "Admin can update requests" ON knowledge_requests;
DROP POLICY IF EXISTS "Admin can delete requests" ON knowledge_requests;

DROP POLICY IF EXISTS "Users can read own reports" ON user_reports;
DROP POLICY IF EXISTS "Users can create reports" ON user_reports;
DROP POLICY IF EXISTS "Admin can read all reports" ON user_reports;
DROP POLICY IF EXISTS "Admin can update reports" ON user_reports;
DROP POLICY IF EXISTS "Admin can delete reports" ON user_reports;

-- ============================================
-- STEP 3: CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_requests_user_id ON knowledge_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON knowledge_requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_created_at ON knowledge_requests(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reports_user_id ON user_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON user_reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON user_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_drop_id ON user_reports(drop_id);

-- ============================================
-- STEP 4: ENABLE RLS
-- ============================================

ALTER TABLE knowledge_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 5: CREATE POLICIES FOR knowledge_requests
-- ============================================

-- Users can read their own requests
CREATE POLICY "Users can read own requests"
    ON knowledge_requests
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create requests
CREATE POLICY "Users can create requests"
    ON knowledge_requests
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Admin can read all requests
CREATE POLICY "Admin can read all requests"
    ON knowledge_requests
    FOR SELECT
    USING (auth.jwt() ->> 'email' = 'appdev827@gmail.com');

-- Admin can update requests
CREATE POLICY "Admin can update requests"
    ON knowledge_requests
    FOR UPDATE
    USING (auth.jwt() ->> 'email' = 'appdev827@gmail.com');

-- Admin can delete requests
CREATE POLICY "Admin can delete requests"
    ON knowledge_requests
    FOR DELETE
    USING (auth.jwt() ->> 'email' = 'appdev827@gmail.com');

-- ============================================
-- STEP 6: CREATE POLICIES FOR user_reports
-- ============================================

-- Users can read their own reports
CREATE POLICY "Users can read own reports"
    ON user_reports
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create reports
CREATE POLICY "Users can create reports"
    ON user_reports
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Admin can read all reports
CREATE POLICY "Admin can read all reports"
    ON user_reports
    FOR SELECT
    USING (auth.jwt() ->> 'email' = 'appdev827@gmail.com');

-- Admin can update reports
CREATE POLICY "Admin can update reports"
    ON user_reports
    FOR UPDATE
    USING (auth.jwt() ->> 'email' = 'appdev827@gmail.com');

-- Admin can delete reports
CREATE POLICY "Admin can delete reports"
    ON user_reports
    FOR DELETE
    USING (auth.jwt() ->> 'email' = 'appdev827@gmail.com');

-- ============================================
-- STEP 7: UPDATED_AT TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_knowledge_requests_updated_at ON knowledge_requests;
CREATE TRIGGER update_knowledge_requests_updated_at
    BEFORE UPDATE ON knowledge_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
