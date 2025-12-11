-- STEP 1: CREATE TABLES
-- Run this first

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
