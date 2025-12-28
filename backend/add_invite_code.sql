-- Add invite_code column to invitations table
-- Run this SQL directly in your database

-- First, add the column as nullable (in case there are existing invitations)
ALTER TABLE "invitations" ADD COLUMN IF NOT EXISTS "invite_code" varchar(10);

-- Generate codes for any existing pending invitations (if any)
-- This is a simple approach - you may want to use the invite-code-generator logic
UPDATE "invitations" 
SET "invite_code" = UPPER(
  SUBSTRING(MD5(RANDOM()::TEXT || id::TEXT) FROM 1 FOR 4) || '-' || 
  SUBSTRING(MD5(RANDOM()::TEXT || id::TEXT) FROM 5 FOR 4)
)
WHERE "invite_code" IS NULL AND "status" = 'pending';

-- Now make it NOT NULL
ALTER TABLE "invitations" ALTER COLUMN "invite_code" SET NOT NULL;

-- Add unique constraint
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_invite_code_unique" UNIQUE("invite_code");

-- Add index for fast lookups
CREATE INDEX IF NOT EXISTS "idx_invitations_code" ON "invitations" USING btree ("invite_code") WHERE "invitations"."status" = 'pending';

