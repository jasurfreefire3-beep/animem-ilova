import fs from 'fs';

// 1. We will use simple browser redirect to the server API, but the server needs Google OAuth.
// Wait, the client already provides Google token from Firebase or client-side? No, the user wants the APP to open browser.
// Let's implement a simple app-link handler or polling.
// The easiest for an app is: 
// 1. App opens a URL like: https://animem.uz/api/auth/google/app-login?sessionId=123
// 2. Browser handles Google OAuth.
// 3. Browser saves the user session to the sessionId in DB.
// 4. App polls the session status or enters the code manually.
// Actually, deep linking is the best: the browser redirects back to animem://auth?token=...
// But we need the intent filter in AndroidManifest.xml for that.

let manifest = fs.readFileSync('ilova/android/app/src/main/AndroidManifest.xml', 'utf8');

if (!manifest.includes('android:scheme="animem"')) {
    const intentFilter = `
            <!-- Deep linking for Google Auth Redirect -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="animem" android:host="auth" />
            </intent-filter>
`;
    manifest = manifest.replace('</activity>', intentFilter + '\n        </activity>');
    fs.writeFileSync('ilova/android/app/src/main/AndroidManifest.xml', manifest);
}
console.log('Manifest patched for Deep Linking');
