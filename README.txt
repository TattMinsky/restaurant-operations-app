Restaurant Operations PWA

This project is a mobile-first installable web app for restaurant operations.

Supabase connection has been configured using the project's URL and publishable key.
The Supabase JS client is loaded from jsDelivr and initialized in index.html.

IMPORTANT:
- This build initializes the Supabase client but does not yet sync app records or implement manager login.
- Keep secret/service-role keys out of this app.
- Cloud syncing and manager authentication are the next development steps.
- Records in this current prototype still save locally to each device.
- Confirm food safety limits and corrective actions with official restaurant policy.

To test locally, serve this folder over HTTPS or localhost. For installation on phones,
host it on an HTTPS web host and open it in the mobile browser to add to Home Screen.
