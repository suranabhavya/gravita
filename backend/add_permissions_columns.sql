-- Add permissions column to users table
ALTER TABLE "users" 
ADD COLUMN IF NOT EXISTS "permissions" jsonb DEFAULT '{}'::jsonb;

-- Add permissions column to invitations table
ALTER TABLE "invitations" 
ADD COLUMN IF NOT EXISTS "permissions" jsonb DEFAULT '{}'::jsonb;

