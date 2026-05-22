-- Add display_name to users table (run this on your Render DB)
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);

-- Add description to posts table
ALTER TABLE posts ADD COLUMN IF NOT EXISTS description TEXT;
