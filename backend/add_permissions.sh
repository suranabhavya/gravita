#!/bin/bash

# Script to add permissions columns to users and invitations tables

echo "🔧 Adding permissions columns to database..."

if [ -z "$DATABASE_URL" ]; then
  echo "❌ Error: DATABASE_URL not set in environment"
  echo "Please set DATABASE_URL in your .env file or export it"
  exit 1
fi

echo "📝 Running SQL to add permissions columns..."

psql "$DATABASE_URL" <<EOF
-- Add permissions column to users table
ALTER TABLE "users" 
ADD COLUMN IF NOT EXISTS "permissions" jsonb DEFAULT '{}'::jsonb;

-- Add permissions column to invitations table
ALTER TABLE "invitations" 
ADD COLUMN IF NOT EXISTS "permissions" jsonb DEFAULT '{}'::jsonb;

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'permissions';

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'invitations' AND column_name = 'permissions';
EOF

if [ $? -eq 0 ]; then
  echo "✅ Permissions columns added successfully!"
  echo "🔄 Please restart your backend server"
else
  echo "❌ Failed to add columns. Please check your database connection."
  exit 1
fi

