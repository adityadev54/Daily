-- STEP 1: Check if table exists and its structure
-- Run this first to see what columns exist:
SELECT
  column_name,
  data_type,
  is_nullable
FROM
  information_schema.columns
WHERE
  table_name = 'knowledge_requests';


-- If the table exists but is missing columns, or you want to start fresh:
-- OPTION A: DROP AND RECREATE (loses all data)
-- Uncomment the lines below:
-- DROP TABLE IF EXISTS knowledge_requests CASCADE;
-- DROP TABLE IF EXISTS user_reports CASCADE;
-- Then run 01_create_tables.sql again
-- OPTION B: ADD MISSING COLUMN (if table exists but missing 'description')
-- ALTER TABLE knowledge_requests ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
-- OPTION C: REFRESH SCHEMA CACHE
-- Go to Supabase Dashboard -> Settings -> API -> Click "Reload Schema"