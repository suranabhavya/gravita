#!/bin/bash

# Script to reset database and run migrations from scratch
# WARNING: This will delete ALL data in your database!

echo "⚠️  WARNING: This will delete ALL data in your database!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Get database connection details
if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL not set in environment"
  exit 1
fi

echo "📦 Dropping all tables and types..."
psql "$DATABASE_URL" <<EOF
-- Drop all tables (in reverse dependency order)
DROP TABLE IF EXISTS "activity_logs" CASCADE;
DROP TABLE IF EXISTS "listing_approvals" CASCADE;
DROP TABLE IF EXISTS "listing_status_history" CASCADE;
DROP TABLE IF EXISTS "material_listings" CASCADE;
DROP TABLE IF EXISTS "notifications" CASCADE;
DROP TABLE IF EXISTS "user_roles" CASCADE;
DROP TABLE IF EXISTS "team_members" CASCADE;
DROP TABLE IF EXISTS "department_teams" CASCADE;
DROP TABLE IF EXISTS "department_hierarchy" CASCADE;
DROP TABLE IF EXISTS "departments" CASCADE;
DROP TABLE IF EXISTS "teams" CASCADE;
DROP TABLE IF EXISTS "invitations" CASCADE;
DROP TABLE IF EXISTS "email_verifications" CASCADE;
DROP TABLE IF EXISTS "roles" CASCADE;
DROP TABLE IF EXISTS "users" CASCADE;
DROP TABLE IF EXISTS "companies" CASCADE;
DROP TABLE IF EXISTS "material_categories" CASCADE;

-- Drop all enums
DROP TYPE IF EXISTS "approval_action" CASCADE;
DROP TYPE IF EXISTS "company_type" CASCADE;
DROP TYPE IF EXISTS "invitation_status" CASCADE;
DROP TYPE IF EXISTS "listing_status" CASCADE;
DROP TYPE IF EXISTS "scope_type" CASCADE;
DROP TYPE IF EXISTS "status" CASCADE;
EOF

echo "✅ Database reset complete!"
echo ""
echo "🔄 Running migrations..."

# Run migrations
npm run db:migrate

echo ""
echo "✅ Done! Your database is now fresh with all migrations applied."

