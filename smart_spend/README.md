# 💸 Smart Spend

Welcome to **Smart Spend** – your personal finance companion, designed especially for students! 🎓💰

## 🚀 Description
Smart Spend helps students take control of their finances with ease. Track your spending, set savings goals, get personalized insights, and learn financial tips – all in one beautiful, easy-to-use app.

## ✨ Features
- 🎨 **Splash Screen**: Beautiful animated welcome screen with app branding
- 👛 **Dashboard**: See your balance, income, and expenses at a glance
- 🏦 **Savings Goals**: Set and track your savings targets (free users: up to 5, premium: unlimited)
- 📊 **Budgeting**: Create and manage budgets for different categories (free users: up to 5, premium: unlimited)
- 💡 **Financial Tips**: Get smart advice tailored for students 
- 📈 **Insights**: Visualize your spending and saving trends
- 🔐 **Authentication**: Secure login and sign-up with Supabase
- ⚙️ **Settings**: Manage your profile, preferences and premium subscriptions
- 💳 **Payments & Subscription**: Upgrade to Premium using Paystack (5000 TSH/month)
- 🌐 **Cross-Platform Support**: Works on web, Android, and iOS with platform-specific features
  
## 🌐 Live Demo & Pitch Deck
- [Live Demo](https://smart-spend-5ce225.netlify.app/)
- [SmartSpend UI Demo](https://drive.google.com/file/d/198NAQHI2GrV_RKyn3W2xyhyFhQwoLOBn/view?usp=drive_web)
- [Pitch Deck](https://www.canva.com/design/DAGoRO_1YTg/4dHndUmDcq7JHRx55GWkCg/edit?utm_content=DAGoRO_1YTg&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton)

## 🛠️ Tech Stack
- **Flutter** (cross-platform mobile & web app)
- **Supabase** (authentication & backend)
- **GoRouter** (navigation)
- **Paystack** (mobile payments)
- **shared_preferences** (local storage)
- **flutter_local_notifications** (reminders)
  
## 📁 Project Structure
```
smart_spend/
├── lib/
│   ├── main.dart                # App entry point & routing
│   ├── screens/                 # All main app screens
        ├── splash_screen.dart   # Welcome splash screen
│   │   ├── home_screen.dart     # Home/dashboard
│   │   ├── savings_screen.dart  # Savings goals
│   │   ├── budget_screen.dart   # Budgeting
│   │   ├── tips_screen.dart     # Financial tips wih favorites
│   │   ├── insights_screen.dart # Insights & analytics
│   │   ├── bottom_nav.dart      # Bottom navigation bar
│   ├── classes/
│   │   └── settings_screen.dart # Settings/profile, payment, premium gating
├── pubspec.yaml                 # Dependencies
├── README.md                    # This file!
```

## 💎 Premium Features
- **Unlimited Budgets** (free users: 5 max)
- **Unlimited Savings Goals** (free users: 5 max)
- **Advanced Analytics** & insights
- **Priority Customer Support**
- **Export Financial Reports**
- **Custom Budget Alerts**
- **Upgrade via Paystack** (5000 TSH/month)

## 🌐 Platform-Specific Features

### **Web Platform:**
- ✅ **Demo Mode**: Test premium features without payment
- ✅ **Enhanced Payment Dialog**: Beautiful UI explaining mobile app requirement
- ✅ **App Store Links**: Direct links to download mobile app
- ✅ **All Core Features**: Budgeting, savings, tips, insights
- ❌ **Real Payments**: Not available (mobile app required)

### **Mobile Platform (Android/iOS):**
- ✅ **Full Payment Integration**: Real Paystack payments
- ✅ **Push Notifications**: Budget alerts and reminders
- ✅ **Native App Experience**: Better performance and UX
- ✅ **All Premium Features**: Unlimited budgets and goals

## 🧑‍💻 Development & Testing

### **Running the Project:**
1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run` for mobile or `flutter run -d chrome` for web

### **Testing Premium Features:**
- **Web**: Use "Try Demo Mode" button in settings
- **Mobile**: Use real Paystack test payments
- **Test Cards**: `4084 0840 8408 4081`, any future expiry, any 3-digit CVV

## 🚀 Deployment

 ### **Web Deployment:**
  1. Run `flutter build web`.
  2. Deploy the contents of `build/web` to Netlify (drag-and-drop or CLI).
  3. Configure custom domain (optional)
     
 ### **Mobile Deployment:**
  1. **Android**: Build APK/AAB and upload to Google Play Console
  2. **iOS**: Build and upload to App Store Connect

## 🔧 Recent Updates

- ✅ **Splash Screen**: Professional welcome experience
- ✅ **Enhanced Web UX**: Better payment dialog and demo mode
- ✅ **Enhanced Web UI**:  Swipe-based navigation for smoother screen transitions and Floating action widget for quick access to savings and budget creation
- ✅ **Cross-Platform Support**: Works on web, Android, and iOS
- ✅ **Premium Gating**: Real limitations for free users
- ✅ **Payment Integration**: Paystack integration for mobile

## 👥 Team Members
- **Joan Francis** – Flutter Developer and Product Designer

## 🌱 Future Improvements
- 📱 Push notifications for reminders, spending alerts
- 🏦 Bank account integration
- 🌍 Multi-language support
- 📅 Calendar view for transactions
- 🤖 AI-powered financial advice
- 🧑‍🤝‍🧑 Social/group savings goals

---

> Made with 💚 by the Smart Spend Team. Happy saving!