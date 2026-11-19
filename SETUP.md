# Market Deals — setup guide

This is a mobile-friendly React/Vite marketplace starter with Supabase authentication and database support. The included preview works without credentials using sample listings; real sign-in and publishing require your own Supabase project.

## 1. Create the backend (Supabase)
1. Open https://supabase.com and create a project.
2. In your project, open **SQL Editor** → **New query**.
3. Copy all of `supabase/schema.sql` into the editor and run it.
4. Open **Project Settings → API**. Copy the Project URL and the `anon` / publishable key.
5. In the project folder, copy `.env.example` to `.env` and fill in:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
6. Never put the `service_role` key in a browser app or share it publicly.

## 2. Run the website
Install Node.js on a computer, then from this folder run:
```bash
npm install
npm run dev
```
Vite prints a local address. Open it in your browser. To make a production build:
```bash
npm run build
```
The finished website is in `dist/`.

## 3. Publish online
You can deploy the project using Vercel or Netlify:
- Import the project repository.
- Build command: `npm run build`
- Output folder: `dist`
- Add the two `VITE_SUPABASE_...` environment variables in the hosting dashboard.
- Redeploy after adding environment variables.

## Current features
- Responsive marketplace layout, categories, text search and availability filter.
- Demo product cards and listing age display.
- Supabase email/password sign-up and sign-in.
- Create listings for signed-in users.
- Supabase tables and Row Level Security policies for profiles, listings, conversations, messages and reviews.

## Important next modules before public launch
The UI currently shows a sample marketplace when Supabase is not configured. Messaging, calls, location sharing, image upload, checkout/transaction confirmation, and review submission still need their dedicated screens and server-side workflows. The database has starter conversation/message/review tables, but the chat interface is not yet wired up.

For calls, use WebRTC with authenticated Supabase Realtime signaling or a managed calling provider. For temporary location sharing, request browser permission only after both parties explicitly agree, show a clear sharing indicator, let either party stop sharing, and expire location data quickly. Do not publish a buyer's identity without their consent. Prefer meeting in busy public places and avoid sharing a home address.

## Before real users
- Add email confirmation, password reset and abuse reporting.
- Add image upload to a private/public Supabase Storage bucket with file type/size checks.
- Add a secure transaction-completion flow so a buyer cannot mark their own purchase as completed.
- Enforce review eligibility on the server (only a confirmed buyer of a sold listing may review).
- Add moderation, blocking, rate limits and privacy controls.
- Consider age-appropriate safeguards and avoid encouraging users to meet unknown people alone.
