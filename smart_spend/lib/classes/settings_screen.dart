import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  String _email = '';
  String _plan = 'Free Basic';
  bool _isPremium = false;
  bool _loading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final response = await Supabase.instance.client
        .from('profiles')
        .select('name, email')
        .eq('id', user.id)
        .single();
    setState(() {
      _userName = response['name'] ?? '';
      _email = user.email ?? '';
      _loading = false;
    });
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _email);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() => _loading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      // Update name in profiles
      await Supabase.instance.client
          .from('profiles')
          .update({'name': result['name']})
          .eq('id', user.id);
      // Update email in auth if changed
      if (result['email'] != null && result['email'] != _email) {
        final res = await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: result['email']),
        );
        if (res.user != null) {
          _email = res.user!.email ?? _email;
        }
      }
      _userName = result['name'] ?? _userName;
      setState(() => _loading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  void _upgradePlan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upgrade to Premium'),
          content: const Text('Upgrade to Premium for TZS 5,000/month and unlock unlimited features.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Upgrade'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      setState(() {
        _plan = 'Premium';
        _isPremium = true;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upgraded to Premium!')),
      );
    }
  }

  void _showPlaceholder(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This feature is coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    // Placeholder for logout logic
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_userName.isNotEmpty ? _userName : 'No name'),
                  subtitle: Text(_email),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editProfile,
                    tooltip: 'Edit Profile',
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(_isPremium ? Icons.star : Icons.star_border),
                  title: Text('Subscription: $_plan'),
                  subtitle: Text(_isPremium
                      ? 'You have unlimited features.'
                      : 'Free Basic Plan. Upgrade for unlimited features.'),
                  trailing: !_isPremium
                      ? ElevatedButton(
                          onPressed: _upgradePlan,
                          child: const Text('Upgrade'),
                        )
                      : null,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Payment Methods'),
                  onTap: () => _showPlaceholder('Payment Methods'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() {
                        _notificationsEnabled = val;
                      });
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security & Privacy'),
                  onTap: () => _showPlaceholder('Security & Privacy'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: () => _showPlaceholder('Help & Support'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log Out'),
                  onTap: _logout,
                ),
              ],
            ),
    );
  }
} 