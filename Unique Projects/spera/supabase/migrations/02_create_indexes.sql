-- STEP 2: CREATE INDEXES
-- Run this after tables are created
CREATE INDEX IF NOT EXISTS idx_requests_user_id ON knowledge_requests (user_id);


CREATE INDEX IF NOT EXISTS idx_requests_status ON knowledge_requests (status);


CREATE INDEX IF NOT EXISTS idx_requests_created_at ON knowledge_requests (created_at DESC);


CREATE INDEX IF NOT EXISTS idx_reports_user_id ON user_reports (user_id);


CREATE INDEX IF NOT EXISTS idx_reports_status ON user_reports (status);


CREATE INDEX IF NOT EXISTS idx_reports_created_at ON user_reports (created_at DESC);


CREATE INDEX IF NOT EXISTS idx_reports_drop_id ON user_reports (drop_id);