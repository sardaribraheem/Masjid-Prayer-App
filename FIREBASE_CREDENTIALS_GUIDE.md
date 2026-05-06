# 🔥 Manual Firebase Web Setup for Chrome Testing

## Step 1: Get Your Firebase Project Credentials

1. Go to: https://console.firebase.google.com
2. Select your **"Masjid Prayer App"** project
3. Look for the **gear icon** ⚙️ in the top left
4. Click **"Project Settings"**
5. Go to the **"General"** tab
6. Scroll down to find **"Your apps"** section
7. Click on the **Web icon** (</>) to add a web app

### If you already have a web app registered:
- Skip to Step 2

### If you need to add the web app:
1. Click **"Register app"** or **web icon**
2. App name: `Masjid Prayer App Web`
3. Click **"Register app"**
4. You'll get a **configuration object** - COPY THIS!

It will look like this (with YOUR actual values):
```javascript
{
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456",
  measurementId: "G-XXXXXXXXXX"
}
```

---

## Step 2: Get Firestore Database URL

1. In same Firebase Console, go to **Build** → **Firestore Database**
2. You should see your database URL (after you created it)
3. It looks like: `https://your-project.firebaseio.com`

---

## Step 3: What I'll Do Next

Once you provide me with the credentials above, I will:

1. ✅ Create a temporary `.env` file with your credentials
2. ✅ Update the web configuration
3. ✅ Run: `flutter run -d chrome`
4. ✅ Test the app functionality
5. ✅ Show you everything works

---

## Go Get Your Credentials Now! 

**Copy the JSON configuration from Firebase Console and paste it below in this format:**

```
apiKey: [YOUR_API_KEY]
authDomain: [YOUR_AUTH_DOMAIN]
projectId: [YOUR_PROJECT_ID]
storageBucket: [YOUR_STORAGE_BUCKET]
messagingSenderId: [YOUR_MESSAGING_SENDER_ID]
appId: [YOUR_APP_ID]
```

Send me these 6 values and I'll complete the setup! ✨
