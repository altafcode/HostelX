# HostelX Push Server

Free Firebase Cloud Functions alternative using a Vercel Serverless Function.

## Deploy

1. Create a Firebase service account:
   Firebase Console -> Project settings -> Service accounts -> Generate new private key.

2. Deploy this folder to Vercel:

```powershell
cd C:\Users\altaf\StudioProjects\hostelX\push-server
npm install
npx vercel login
npx vercel
```

3. Add these Vercel environment variables from the downloaded service account JSON:

```text
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
```

For `FIREBASE_PRIVATE_KEY`, paste the full private key value including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`.

4. Deploy production:

```powershell
npx vercel --prod
```

5. Copy the production URL and set it in the Flutter app's `PushConfig.pushEndpoint`.
