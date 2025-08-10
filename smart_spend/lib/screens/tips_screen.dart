import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TipsScreen extends StatefulWidget {
  final PageController? pageController;
  const TipsScreen({super.key, this.pageController});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final Map<String, List<Map<String, String>>> tipsByTopic = {
    'All': [
      {
        'title': 'Create a Simple Budget',
        'explanation': 'Start with a basic budget tracking your daily expenses like transport (dala dala), meals, and school supplies. Use a notebook or mobile app.',
      },
      {
        'title': 'Save in Mobile Money',
        'explanation': 'Use M-Pesa, Tigo Pesa, or Airtel Money to save small amounts regularly. Even TZS 1,000 per day adds up quickly.',
      },
      {
        'title': 'Avoid Predatory Lenders',
        'explanation': 'Stay away from quick loan apps and street lenders who charge high interest rates. They can trap you in debt.',
      },
      {
        'title': 'Track Your Spending',
        'explanation': 'Record every shilling you spend - from breakfast at school to transport costs. This helps identify where you can save.',
      },
      {
        'title': 'Compare Prices',
        'explanation': 'Compare prices at different shops and markets before buying. Prices can vary significantly for the same items.',
      },
    ],
    'Budgeting': [
      {
        'title': '50/30/20 Rule for Students',
        'explanation': 'Allocate 50% to needs (transport, food, school fees), 30% to wants (entertainment, shopping), and 20% to savings and emergencies.',
      },
      {
        'title': 'Track Daily Expenses',
        'explanation': 'Record all your spending including dala dala fares, lunch money, and school supplies. Use a simple notebook or mobile app.',
      },
      {
        'title': 'Plan for Short-term Goals',
        'explanation': 'Set aside money for books, school trips, or new uniforms. Plan ahead to avoid last-minute financial stress.',
      },
      {
        'title': 'Use Cash Envelopes',
        'explanation': 'Divide your money into envelopes for different purposes: transport, food, school supplies, and savings.',
      },
      {
        'title': 'Emergency Fund First',
        'explanation': 'Build a small emergency fund of TZS 50,000-100,000 for unexpected expenses like medical costs or school emergencies.',
      },
    ],
    'Saving': [
      {
        'title': 'Save Regularly in Mobile Wallet',
        'explanation': 'Use M-Pesa, Tigo Pesa, or Airtel Money to save small amounts daily. Even TZS 500-1,000 per day builds up quickly.',
      },
      {
        'title': 'Set Aside Allowance Portion',
        'explanation': 'Save 10-20% of your allowance or pocket money before spending anything. Treat savings like a bill you must pay.',
      },
      {
        'title': 'Use Mobile Banking Apps',
        'explanation': 'Monitor your balances and transactions using mobile banking apps. This helps you stay aware of your spending.',
      },
      {
        'title': 'Save Windfalls',
        'explanation': 'Put unexpected money like gifts, bonuses, or extra allowance directly into savings instead of spending it.',
      },
      {
        'title': 'Cut Unnecessary Expenses',
        'explanation': 'Identify and eliminate unnecessary spending like extra snacks, impulse purchases, or unused subscriptions.',
      },
    ],
    'Investing': [
      {
        'title': 'Start with Small Amounts',
        'explanation': 'Begin investing with small amounts you can afford to lose. Even TZS 5,000-10,000 can be a good start.',
      },
      {
        'title': 'Learn About Local Investment Options',
        'explanation': 'Research Tanzanian investment options like government bonds, SACCOs, or local stock market opportunities.',
      },
      {
        'title': 'Invest in Your Education',
        'explanation': 'Consider investing in additional courses, books, or skills that can increase your future earning potential.',
      },
      {
        'title': 'Understand Risk vs Reward',
        'explanation': 'Learn about different investment risks. Higher potential returns usually come with higher risks.',
      },
      {
        'title': 'Start Early with Compound Interest',
        'explanation': 'The earlier you start investing, the more time your money has to grow through compound interest.',
      },
      {
        'title': 'Diversify Your Investments',
        'explanation': 'Spread your investments across different types to reduce risk. Don\'t put all your money in one place.',
      },
    ],
    'Education': [
      {
        'title': 'Learn About Interest Rates',
        'explanation': 'Understand how interest rates work on loans and savings. This helps you make better financial decisions.',
      },
      {
        'title': 'Ask for Financial Advice',
        'explanation': 'Seek advice from trusted adults, teachers, or financial advisors about managing your money.',
      },
      {
        'title': 'Read Financial Books',
        'explanation': 'Read books about personal finance, budgeting, and money management to improve your financial literacy.',
      },
      {
        'title': 'Attend Financial Workshops',
        'explanation': 'Look for financial literacy workshops or seminars in your community or school.',
      },
      {
        'title': 'Practice Budgeting Skills',
        'explanation': 'Practice creating and sticking to budgets with small amounts to develop good financial habits.',
      },
    ],
    'Debt': [
      {
        'title': 'Avoid High-Interest Loans',
        'explanation': 'Stay away from quick loan apps and street lenders who charge very high interest rates.',
      },
      {
        'title': 'Pay Off High-Interest Debt First',
        'explanation': 'If you have multiple debts, focus on paying off the ones with the highest interest rates first.',
      },
      {
        'title': 'Negotiate Better Terms',
        'explanation': 'Contact your creditors to request lower interest rates or better payment terms if you\'re struggling.',
      },
      {
        'title': 'Avoid New Debt',
        'explanation': 'Stop taking on new debt while paying off existing obligations to avoid getting deeper in debt.',
      },
      {
        'title': 'Create a Debt Payoff Plan',
        'explanation': 'Develop a systematic approach to eliminate your debts one by one, starting with the highest interest rates.',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tipsByTopic.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Tips'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.pageController != null) {
                widget.pageController!.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                context.go('/home');
              }
            },
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final topic in tipsByTopic.keys)
                Tab(text: topic),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final topic in tipsByTopic.keys)
              _TipsList(tips: tipsByTopic[topic]!),
          ],
        ),
      ),
    );
  }
}

class _TipsList extends StatelessWidget {
  final List<Map<String, String>> tips;
  const _TipsList({required this.tips});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return const Center(child: Text('No tips available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForTip(tip['title']!),
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip['title']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tip['explanation']!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForTip(String title) {
    switch (title) {
      case 'Create a Simple Budget':
        return Icons.rule;
      case 'Save in Mobile Money':
        return Icons.account_balance_wallet;
      case 'Avoid Predatory Lenders':
        return Icons.warning;
      case 'Track Your Spending':
        return Icons.receipt_long;
      case 'Compare Prices':
        return Icons.compare_arrows;
      case '50/30/20 Rule for Students':
        return Icons.rule;
      case 'Track Daily Expenses':
        return Icons.receipt_long;
      case 'Plan for Short-term Goals':
        return Icons.flag;
      case 'Use Cash Envelopes':
        return Icons.account_balance_wallet;
      case 'Emergency Fund First':
        return Icons.security;
      case 'Save Regularly in Mobile Wallet':
        return Icons.savings;
      case 'Set Aside Allowance Portion':
        return Icons.payment;
      case 'Use Mobile Banking Apps':
        return Icons.phone_android;
      case 'Save Windfalls':
        return Icons.celebration;
      case 'Cut Unnecessary Expenses':
        return Icons.cut;
      case 'Start with Small Amounts':
        return Icons.trending_up;
      case 'Learn About Local Investment Options':
        return Icons.school;
      case 'Invest in Your Education':
        return Icons.school;
      case 'Understand Risk vs Reward':
        return Icons.psychology;
      case 'Start Early with Compound Interest':
        return Icons.timer;
      case 'Diversify Your Investments':
        return Icons.pie_chart;
      case 'Learn About Interest Rates':
        return Icons.calculate;
      case 'Ask for Financial Advice':
        return Icons.people;
      case 'Read Financial Books':
        return Icons.book;
      case 'Attend Financial Workshops':
        return Icons.event;
      case 'Practice Budgeting Skills':
        return Icons.check_circle;
      case 'Avoid High-Interest Loans':
        return Icons.block;
      case 'Pay Off High-Interest Debt First':
        return Icons.priority_high;
      case 'Negotiate Better Terms':
        return Icons.phone;
      case 'Avoid New Debt':
        return Icons.block;
      case 'Create a Debt Payoff Plan':
        return Icons.assignment;
      default:
        return Icons.lightbulb_outline;
    }
  }
} 