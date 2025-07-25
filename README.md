# 💸 Smart Spend

Welcome to **Smart Spend** – your personal finance companion, designed especially for students! 🎓💰

## 🚀 Description
Smart Spend helps students take control of their finances with ease. Track your spending, set savings goals, get personalized insights, and learn financial tips – all in one beautiful, easy-to-use app.

## ✨ Features
- 👛 **Dashboard**: See your balance, income, and expenses at a glance
- 🏦 **Savings Goals**: Set and track your savings targets (free users: up to 5, premium: unlimited)
- 📊 **Budgeting**: Create and manage budgets for different categories (free users: up to 5, premium: unlimited)
- 💡 **Financial Tips**: Get smart advice tailored for students
- 📈 **Insights**: Visualize your spending and saving trends
- 🔐 **Authentication**: Secure login and sign-up with Supabase
- ⚙️ **Settings**: Manage your profile and preferences
- 💳 **Payments & Subscription**: Upgrade to Premium using Paystack (Android/iOS only)
- 🌐 **Web/Mobile Support**: Payment features are only available on Android/iOS. On web, payment/upgrade is hidden for compatibility.
  
## 🌐 Live Demo & Pitch Deck
- [Live Demo](https://smart-spend-c7a585.netlify.app/)
- [Pitch Deck](https://www.canva.com/design/DAGoRO_1YTg/4dHndUmDcq7JHRx55GWkCg/edit?utm_content=DAGoRO_1YTg&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton)

## 🛠️ Tech Stack
- **Flutter** (cross-platform mobile & web app)
- **Supabase** (authentication & backend)
- **GoRouter** (navigation)
- **Provider** (state management)
- **Paystack** (mobile payments)
- **shared_preferences** (local storage)
- **flutter_local_notifications** (reminders)
  
## 📁 Project Structure
```
smart_spend/
├── lib/
│   ├── main.dart                # App entry point & routing
│   ├── screens/                 # All main app screens
│   │   ├── home_screen.dart     # Home/dashboard
│   │   ├── savings_screen.dart  # Savings goals
│   │   ├── budget_screen.dart   # Budgeting
│   │   ├── tips_screen.dart     # Financial tips
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
- **Early Access to Features** (premium only)
- **Upgrade via Paystack** (Android/iOS only)

## 🧑‍💻 Development & Testing
- To test payments and premium features, run the app on Android/iOS (emulator or real device).
- On web (local or Netlify), payment/upgrade is hidden and Paystack is not initialized.
- Use Paystack test cards for payment testing:
  - Card: `4084 0840 8408 4081`, any future expiry, any 3-digit CVV, PIN: `0000` or `1234`
 
## ⚠️ Notes
- **Paystack and payment features are not available on web.**
- If you want to test payments, use a mobile device or emulator.
- If you update dependencies, you may need to patch `flutter_paystack` for Flutter 3.7+ compatibility (see code comments).


## 🚀 Deployment
- **Web:**
  1. Run `flutter build web`.
  2. Deploy the contents of `build/web` to Netlify (drag-and-drop or CLI).
- **Mobile:**
  - Build and deploy as a standard Flutter app (Android/iOS).


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
