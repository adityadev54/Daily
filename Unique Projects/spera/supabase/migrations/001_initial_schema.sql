-- Supabase SQL Migration for Spera
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)

-- ============================================
-- 1. KNOWLEDGE DROPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS knowledge_drops (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  content_type TEXT NOT NULL CHECK (content_type IN ('audio', 'video')),
  category TEXT NOT NULL CHECK (category IN ('thinkingTools', 'realWorldProblems', 'skillUnlocks', 'decisionFrameworks', 'temporal')),
  difficulty TEXT NOT NULL CHECK (difficulty IN ('foundational', 'intermediate', 'advanced', 'expert')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'vaulted')),
  duration_seconds INTEGER NOT NULL,
  content_url TEXT,
  thumbnail_url TEXT,
  tags TEXT[] DEFAULT '{}',
  skills TEXT[] DEFAULT '{}',
  use_cases TEXT[] DEFAULT '{}',
  xp_reward INTEGER NOT NULL DEFAULT 50,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  required_rank TEXT CHECK (required_rank IN ('observer', 'analyst', 'strategist', 'architect')),
  prerequisite_ids TEXT[] DEFAULT '{}',
  related_ids TEXT[] DEFAULT '{}',
  display_order INTEGER DEFAULT 0
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_knowledge_drops_status ON knowledge_drops(status);
CREATE INDEX IF NOT EXISTS idx_knowledge_drops_category ON knowledge_drops(category);
CREATE INDEX IF NOT EXISTS idx_knowledge_drops_created_at ON knowledge_drops(created_at DESC);

-- ============================================
-- 2. TRANSCRIPTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS transcripts (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  drop_id TEXT NOT NULL REFERENCES knowledge_drops(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  start_time DECIMAL(10, 3) NOT NULL, -- seconds with milliseconds
  end_time DECIMAL(10, 3) NOT NULL,
  speaker TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster transcript lookups
CREATE INDEX IF NOT EXISTS idx_transcripts_drop_id ON transcripts(drop_id);
CREATE INDEX IF NOT EXISTS idx_transcripts_start_time ON transcripts(drop_id, start_time);

-- ============================================
-- 3. USER PROFILES TABLE (for future auth)
-- ============================================
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  total_xp INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_activity_date DATE,
  completed_drop_ids TEXT[] DEFAULT '{}',
  in_progress_drop_ids TEXT[] DEFAULT '{}',
  bookmarked_drop_ids TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 4. USER PROGRESS TABLE (detailed tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS user_progress (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  drop_id TEXT NOT NULL REFERENCES knowledge_drops(id) ON DELETE CASCADE,
  progress_seconds INTEGER NOT NULL DEFAULT 0,
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  xp_earned INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, drop_id)
);

CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_drop_id ON user_progress(drop_id);

-- ============================================
-- 5. KNOWLEDGE REQUESTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS knowledge_requests (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  question TEXT NOT NULL,
  context TEXT,
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'matched', 'delivered', 'failed')),
  matched_drop_id TEXT REFERENCES knowledge_drops(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_knowledge_requests_status ON knowledge_requests(status);
CREATE INDEX IF NOT EXISTS idx_knowledge_requests_user_id ON knowledge_requests(user_id);

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE knowledge_drops ENABLE ROW LEVEL SECURITY;
ALTER TABLE transcripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_requests ENABLE ROW LEVEL SECURITY;

-- Knowledge drops: Everyone can read active/archived, only admins can modify
CREATE POLICY "Anyone can read active knowledge drops" ON knowledge_drops
  FOR SELECT USING (status IN ('active', 'archived'));

-- Transcripts: Anyone can read
CREATE POLICY "Anyone can read transcripts" ON transcripts
  FOR SELECT USING (true);

-- User profiles: Users can read/update their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

-- User progress: Users can manage their own progress
CREATE POLICY "Users can view own progress" ON user_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON user_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- Knowledge requests: Users can manage their own requests
CREATE POLICY "Users can view own requests" ON knowledge_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create requests" ON knowledge_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 7. HELPER FUNCTIONS
-- ============================================

-- Function to update user XP when completing a drop
CREATE OR REPLACE FUNCTION update_user_xp()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.completed = true AND OLD.completed = false THEN
    UPDATE user_profiles
    SET total_xp = total_xp + NEW.xp_earned,
        completed_drop_ids = array_append(completed_drop_ids, NEW.drop_id),
        updated_at = NOW()
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update XP
CREATE TRIGGER on_progress_complete
  AFTER UPDATE ON user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_user_xp();

-- ============================================
-- 8. SAMPLE DATA (your existing drops)
-- ============================================

-- Insert First Principles Thinking
INSERT INTO knowledge_drops (
  id, title, description, content_type, category, difficulty, status,
  duration_seconds, content_url, thumbnail_url, tags, skills, use_cases, xp_reward
) VALUES (
  'drop_001',
  'First Principles Thinking',
  'Break down complex problems to their fundamental truths. Learn how Elon Musk and other innovators use this mental model.',
  'audio',
  'thinkingTools',
  'foundational',
  'active',
  300,
  'https://example.com/audio/first-principles.mp3',
  'https://picsum.photos/seed/principles/400/225',
  ARRAY['thinking', 'problem-solving', 'innovation'],
  ARRAY['Critical Thinking', 'Problem Decomposition'],
  ARRAY['Product decisions', 'Cost optimization', 'Innovation'],
  50
);

-- Insert Inversion Mental Model
INSERT INTO knowledge_drops (
  id, title, description, content_type, category, difficulty, status,
  duration_seconds, content_url, thumbnail_url, tags, skills, use_cases, xp_reward
) VALUES (
  'drop_002',
  'Inversion: Think Backwards',
  'Instead of asking how to succeed, ask how to fail. Then avoid those things. A powerful tool for risk management.',
  'audio',
  'thinkingTools',
  'foundational',
  'active',
  240,
  'https://example.com/audio/inversion.mp3',
  'https://picsum.photos/seed/inversion/400/225',
  ARRAY['thinking', 'risk', 'strategy'],
  ARRAY['Risk Assessment', 'Strategic Thinking'],
  ARRAY['Risk mitigation', 'Goal setting', 'Decision making'],
  50
);

-- Insert Managing Risk in Private Equity (VIDEO)
INSERT INTO knowledge_drops (
  id, title, description, content_type, category, difficulty, status,
  duration_seconds, content_url, thumbnail_url, tags, skills, use_cases, xp_reward
) VALUES (
  'drop_004',
  'Managing Risk in Private Equity',
  'Deep dive into risk management strategies for private equity investments.',
  'video',
  'realWorldProblems',
  'advanced',
  'active',
  380,
  'https://archive.org/download/managing-risk-in-private-equity/Managing%20Risk%20in%20Private%20Equity.mp4',
  'https://picsum.photos/seed/risk/400/225',
  ARRAY['finance', 'risk', 'private-equity'],
  ARRAY['Risk Management', 'Financial Analysis'],
  ARRAY['Investment decisions', 'Portfolio management'],
  80
);

-- Add more of your existing drops as needed...

-- ============================================
-- DONE! Your database is ready.
-- ============================================
