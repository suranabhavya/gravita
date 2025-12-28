# Database Reset Instructions

## Option 1: Use db:push (Recommended - Simplest)

This will sync your current schema directly without worrying about migration history:

```bash
cd backend
npm run db:push
```

When prompted, type "Yes" to execute all statements.

## Option 2: Reset and Use Migrations (If you want proper migration history)

### Step 1: Drop all tables and types

Run this SQL in your database (via psql or your database client):

```sql
-- Drop all tables
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

-- Drop drizzle migration tracking table
DROP TABLE IF EXISTS "__drizzle_migrations" CASCADE;
```

### Step 2: Run migrations

```bash
cd backend
npm run db:migrate
```

## Quick One-Liner (if you have psql)

If you have `psql` installed and `DATABASE_URL` set:

```bash
cd backend
psql "$DATABASE_URL" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
npm run db:migrate
```

**WARNING:** This will delete ALL data in your database!

