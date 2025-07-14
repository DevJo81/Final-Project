import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final Map<String, List<String>> tipsByTopic = {
    'Budgeting': [
      'Create a simple budget and stick to it.',
      'Track your daily spending to identify unnecessary expenses.',
      'Plan for short-term goals like books, groceries, or transport.',
      'Compare prices before making purchases.',
    ],
    'Saving': [
      'Save regularly in your mobile wallet (M-Pesa, Tigo Pesa, Airtel Money, etc.).',
      'Set aside a portion of your allowance or loan for emergencies.',
      'Use mobile banking apps to monitor your balances and transactions.',
    ],
    'Spending': [
      'Avoid taking loans from untrusted sources or predatory lenders.',
      'Track your daily spending to identify unnecessary expenses.',
      'Compare prices before making purchases.',
    ],
    'Education': [
      'Learn the basics of interest rates and how loans work.',
      'Ask for financial advice from trusted adults or mentors.',
    ],
  };

  final Set<String> _favorites = {};

  int get _selectedIndex => 3;
  void _onNavTap(int index) {
    final routes = ['/home', '/savings', '/budget', '/tips', '/insights'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Create an 'All' tab that combines all tips (removing duplicates)
    final allTips = <String>{};
    tipsByTopic.values.forEach(allTips.addAll);
    final topics = ['All', 'Favorites', ...tipsByTopic.keys];

    return DefaultTabController(
      length: topics.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Tips'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final topic in topics)
                Tab(text: topic),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // All tips tab
            _TipsList(
              tips: allTips.toList(),
              favorites: _favorites,
              onToggleFavorite: _toggleFavorite,
            ),
            // Favorites tab
            _TipsList(
              tips: _favorites.toList(),
              favorites: _favorites,
              onToggleFavorite: _toggleFavorite,
            ),
            // Topic-specific tabs
            for (final topic in tipsByTopic.keys)
              _TipsList(
                tips: tipsByTopic[topic]!,
                favorites: _favorites,
                onToggleFavorite: _toggleFavorite,
              ),
          ],
        ),
        bottomNavigationBar: BottomNav(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }

  void _toggleFavorite(String tip) {
    setState(() {
      if (_favorites.contains(tip)) {
        _favorites.remove(tip);
      } else {
        _favorites.add(tip);
      }
    });
  }
}

class _TipsList extends StatelessWidget {
  final List<String> tips;
  final Set<String> favorites;
  final void Function(String tip) onToggleFavorite;
  const _TipsList({required this.tips, required this.favorites, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return const Center(child: Text('No tips available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        final isFavorite = favorites.contains(tip);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.orange),
            title: Text(tip),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () => onToggleFavorite(tip),
              tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
            ),
          ),
        );
      },
    );
  }
} 