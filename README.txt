GOLD STAR RESTAURANT OPERATIONS — MULTI-LOCATION AUTH UPDATE

Included:
- Email/password sign-in through Supabase Auth.
- Corporate, GM, and Shift Lead role model.
- Three seeded restaurant locations.
- Corporate location selector; GM/Shift Lead are restricted to assigned location.
- Row Level Security for access assignments and activity records.
- Cloud audit events for temperature submissions, checklist toggles, and logbook entries.

DEPLOYMENT / SETUP
1. In Supabase Dashboard > SQL Editor, run SUPABASE_MULTI_LOCATION_SETUP.sql.
2. The existing Auth user ID efdf695f-ade6-4697-bd17-5265de1c4d7c is bootstrapped as Corporate. Confirm that this is the intended Corporate administrator before running the SQL.
3. Deploy the contents of this folder to the existing GitHub repository root. Netlify should deploy from the same publish directory already configured.
4. Sign in with the existing Supabase Auth email/password for that user.
5. To invite a GM or Shift Lead, go to Supabase Authentication > Users and invite/create the user's email. Copy that user's UUID and run an INSERT into app_user_access, choosing role and location. Example SQL is at the bottom of SUPABASE_MULTI_LOCATION_SETUP.sql.

IMPORTANT CURRENT SCOPE
- Login and database-enforced location access are implemented.
- Temperature, checklist toggle, and logbook actions send audit events to app_activity_records.
- The existing legacy checklist/cleaning/temperature UI still keeps its working state in browser localStorage. This update does not yet migrate every old local record or make all views a fully cloud-synchronized shared source of truth. Cleaning and deployment actions are not yet cloud-audited.
- Account invitation and role assignment are performed by an administrator in Supabase; end-user self-registration is intentionally disabled so users cannot grant themselves roles or locations.
- Validate all restaurant food-safety thresholds and operational procedures before relying on the app as an official compliance record.
