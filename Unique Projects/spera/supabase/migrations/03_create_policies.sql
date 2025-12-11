-- STEP 3: ENABLE RLS AND CREATE POLICIES
-- Run this after indexes
-- Enable RLS
ALTER TABLE knowledge_requests ENABLE ROW LEVEL SECURITY;


ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;


-- Drop existing policies if any
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


-- KNOWLEDGE REQUESTS POLICIES
CREATE POLICY "Users can read own requests" ON knowledge_requests FOR
SELECT
  USING (auth.uid () = user_id);


CREATE POLICY "Users can create requests" ON knowledge_requests FOR
INSERT
WITH
  CHECK (auth.uid () = user_id);


CREATE POLICY "Admin can read all requests" ON knowledge_requests FOR
SELECT
  USING (auth.jwt () ->> 'email' = 'appdev827@gmail.com');


CREATE POLICY "Admin can update requests" ON knowledge_requests FOR
UPDATE USING (auth.jwt () ->> 'email' = 'appdev827@gmail.com');


CREATE POLICY "Admin can delete requests" ON knowledge_requests FOR DELETE USING (auth.jwt () ->> 'email' = 'appdev827@gmail.com');


-- USER REPORTS POLICIES
CREATE POLICY "Users can read own reports" ON user_reports FOR
SELECT
  USING (auth.uid () = user_id);


CREATE POLICY "Users can create reports" ON user_reports FOR
INSERT
WITH
  CHECK (auth.uid () = user_id);


CREATE POLICY "Admin can read all reports" ON user_reports FOR
SELECT
  USING (auth.jwt () ->> 'email' = 'appdev827@gmail.com');


CREATE POLICY "Admin can update reports" ON user_reports FOR
UPDATE USING (auth.jwt () ->> 'email' = 'appdev827@gmail.com');


CREATE POLICY "Admin can delete reports" ON user_reports FOR DELETE USING (auth.jwt () ->> 'email' = 'appdev827@gmail.com');