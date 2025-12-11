-- FIX: Update policies to use auth.email() function
-- Run this to fix admin access
-- Drop existing admin policies
DROP POLICY IF EXISTS "Admin can read all requests" ON knowledge_requests;


DROP POLICY IF EXISTS "Admin can update requests" ON knowledge_requests;


DROP POLICY IF EXISTS "Admin can delete requests" ON knowledge_requests;


DROP POLICY IF EXISTS "Admin can read all reports" ON user_reports;


DROP POLICY IF EXISTS "Admin can update reports" ON user_reports;


DROP POLICY IF EXISTS "Admin can delete reports" ON user_reports;


-- Recreate with auth.email() instead of jwt
CREATE POLICY "Admin can read all requests" ON knowledge_requests FOR
SELECT
  USING (auth.email () = 'appdev827@gmail.com');


CREATE POLICY "Admin can update requests" ON knowledge_requests FOR
UPDATE USING (auth.email () = 'appdev827@gmail.com');


CREATE POLICY "Admin can delete requests" ON knowledge_requests FOR DELETE USING (auth.email () = 'appdev827@gmail.com');


CREATE POLICY "Admin can read all reports" ON user_reports FOR
SELECT
  USING (auth.email () = 'appdev827@gmail.com');


CREATE POLICY "Admin can update reports" ON user_reports FOR
UPDATE USING (auth.email () = 'appdev827@gmail.com');


CREATE POLICY "Admin can delete reports" ON user_reports FOR DELETE USING (auth.email () = 'appdev827@gmail.com');