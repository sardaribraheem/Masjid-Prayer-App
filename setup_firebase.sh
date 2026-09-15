#!/bin/bash

# 🕌 Masjid Prayer App - Firebase Configuration Script
# This script guides you through Firebase setup step by step

echo "🚀 Masjid Prayer App - Firebase Setup"
echo "===================================="
echo ""

# Step 1: Check if flutterfire is in PATH
echo "📋 Step 1: Checking FlutterFire CLI..."
if ~/.pub-cache/bin/flutterfire --version > /dev/null 2>&1; then
    echo "✅ FlutterFire CLI is available"
else
    echo "❌ FlutterFire CLI not found. Adding to PATH..."
    export PATH="$PATH":"$HOME/.pub-cache/bin"
fi

echo ""
echo "📋 Step 2: Firebase Project Setup"
echo "===================================="
echo ""
echo "IMPORTANT: You need a Firebase project to proceed."
echo ""
echo "Choose one:"
echo "  A) I have a Firebase project already"
echo "  B) I need to create a new Firebase project"
echo ""
echo "If you chose B, follow these steps:"
echo "  1. Go to: https://console.firebase.google.com"
echo "  2. Click 'Create a project'"
echo "  3. Enter project name: 'Masjid Prayer App'"
echo "  4. Follow the setup wizard"
echo "  5. Come back and run this script again"
echo ""
read -p "Press ENTER when ready to configure Firebase..."

echo ""
echo "📋 Step 3: Running FlutterFire Configure"
echo "========================================"
echo ""
echo "A browser window will open asking you to:"
echo "  1. Select your Google account"
echo "  2. Select your Firebase project"
echo "  3. Authorize the connection"
echo ""
echo "This will automatically:"
echo "  ✅ Connect your app to Firebase"
echo "  ✅ Generate iOS/Android configuration"
echo "  ✅ Add necessary dependencies"
echo ""

# Run flutterfire configure
cd /Users/arslananwar/masjid_app
~/.pub-cache/bin/flutterfire configure --project=default

echo ""
echo "📋 Step 4: Enable Firestore Database"
echo "===================================="
echo ""
if [ $? -eq 0 ]; then
    echo "✅ Firebase configured successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Go to: https://console.firebase.google.com"
    echo "  2. Click on your project"
    echo "  3. Left sidebar → Build → Firestore Database → Create Database"
    echo "  4. Start in Test Mode (for development)"
    echo "  5. Choose your region"
    echo "  6. Click Enable"
    echo ""
    read -p "Press ENTER once Firestore is enabled..."
    
    echo ""
    echo "📋 Step 5: Set Firestore Security Rules"
    echo "======================================"
    echo ""
    echo "In Firebase Console:"
    echo "  1. Firestore Database → Rules tab"
    echo "  2. Replace with this:"
    echo ""
    cat << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /masjids/{id} {
      allow read: if true;
      allow write: if true;
    }
  }
}
EOF
    echo ""
    echo "  3. Click Publish"
    echo ""
    read -p "Press ENTER once rules are published..."
    
    echo ""
    echo "✅ Firebase Setup Complete!"
    echo ""
    echo "You can now run the app with:"
    echo "  flutter run"
    echo ""
    echo "To run on Chrome (web):"
    echo "  flutter run -d chrome"
else
    echo "❌ Firebase configuration failed."
    echo "Please check your Google account permissions and try again."
fi
