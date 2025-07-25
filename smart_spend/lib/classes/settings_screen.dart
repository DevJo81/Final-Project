import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SettingsScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  String _email = '';
  String _plan = 'Free Basic';
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  bool _loading = true;
  bool _notificationsEnabled = true;

  static const String _notifPrefKey = 'notifications_enabled';
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Payment methods state
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _loadingPayments = false;

  // Subscription state
  Map<String, dynamic>? _activeSubscription;
  Map<String, dynamic>? _activePaymentMethod;

  @override
  void initState() {
    super.initState();
    _initTimezone();
    _initNotifications();
    _fetchProfile();
    _loadNotificationPref();
    _fetchPaymentMethods();
    _fetchActiveSubscription();
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_notifPrefKey) ?? true;
    });
    if (_notificationsEnabled) {
      _scheduleSampleNotification();
    } else {
      _cancelAllNotifications();
    }
  }

  Future<void> _scheduleSampleNotification() async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Smart Spend Reminder',
      'Check your budget and spending insights!',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Notifications',
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> _cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
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

  // Add this method to select a payment method
  Future<String?> _selectPaymentMethodDialog() async {
    await _fetchPaymentMethods();
    String? selectedId;
    await showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Payment Method'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_paymentMethods.isEmpty)
                  const Text('No payment methods found. Please add one first.'),
                for (final method in _paymentMethods)
                  RadioListTile<String>(
                    value: method['id'].toString(),
                    groupValue: selectedId,
                    onChanged: (val) {
                      setState(() => selectedId = val);
                    },
                    title: Text(
                      method['type'] == 'card'
                          ? (method['masked_card'] ?? 'Card')
                          : (method['provider'] ?? 'Mobile Money'),
                    ),
                    subtitle: Text(
                      method['type'] == 'card'
                          ? (method['cardholder_name'] ?? '')
                          : (method['mobile_number'] ?? ''),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.of(context).pop(selectedId),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
    return selectedId;
  }

  void _upgradePlan() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payments are only available on mobile devices.')),
      );
      return;
    }
    final selectedId = await _selectPaymentMethodDialog();
    if (selectedId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Fetch the selected payment method for email and display
    // ignore: unused_local_variable
    final method = _paymentMethods.firstWhere((m) => m['id'].toString() == selectedId);

    // Set the amount (in kobo, e.g. 5000 NGN = 500000 kobo)
    final int amountKobo = 500000; // TZS 5,000 or your price in kobo

    // Prepare the charge
    Charge charge = Charge()
      ..amount = amountKobo
      ..email = _email // or user.email
      ..reference = 'SSUBS_${DateTime.now().millisecondsSinceEpoch}'
      ..currency = 'NGN'; // Change to your currency if supported

    final plugin = PaystackPlugin();
    CheckoutResponse response = await plugin.checkout(
      // ignore: use_build_context_synchronously
      context,
      method: CheckoutMethod.card, // or .selectable for card/mobile
      charge: charge,
      fullscreen: false,
      // logo: Image.asset('assets/logo.png', width: 48), // Optional: your app logo
    );

    if (response.status == true) {
      // Payment successful: create subscription in Supabase
      await Supabase.instance.client.from('subscriptions').insert({
        'user_id': user.id,
        'payment_method_id': selectedId,
        'plan': 'Premium',
        'status': 'active',
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'paystack_reference': response.reference,
      });

      await _fetchActiveSubscription();

      setState(() {
        _plan = 'Premium';
        _isPremium = true;
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upgraded to Premium!')),
      );
    } else {
      // Payment failed or cancelled
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed:  2${response.message}')),
      );
    }
  }

  // ignore: unused_element
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

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help? Contact our support team and we’ll get back to you as soon as possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'support@smartspend.com',
                query: 'subject=Support Request&body=Describe your issue here...',
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
              } else {
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open email app.')),
                );
              }
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showSecurityPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security & Privacy'),
        content: const Text('Manage your security and privacy settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: _resetPassword,
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _resetPassword() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user email found.')),
      );
      return;
    }
    await Supabase.instance.client.auth.resetPasswordForEmail(user.email!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset link sent!')),
    );
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _fetchPaymentMethods() async {
    setState(() => _loadingPayments = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _paymentMethods = [];
        _loadingPayments = false;
      });
      return;
    }
    final response = await Supabase.instance.client
        .from('payment_methods')
        .select()
        .eq('user_id', user.id)
        .order('created_at');
    setState(() {
      _paymentMethods = List<Map<String, dynamic>>.from(response as List);
      _loadingPayments = false;
    });
  }

  void _showPaymentMethodsDialog() async {
    await _fetchPaymentMethods();
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Payment Methods'),
          content: SizedBox(
            width: 350,
            child: _loadingPayments
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_paymentMethods.isEmpty)
                        const Text('No payment methods added.'),
                      for (final method in _paymentMethods)
                        ListTile(
                          leading: Icon(
                            method['type'] == 'card'
                                ? Icons.credit_card
                                : Icons.phone_android,
                          ),
                          title: Text(
                            method['type'] == 'card'
                                ? (method['masked_card'] ?? 'Card')
                                : (method['provider'] ?? 'Mobile Money'),
                          ),
                          subtitle: Text(
                            method['type'] == 'card'
                                ? (method['cardholder_name'] ?? '')
                                : (method['mobile_number'] ?? ''),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (method['type'] == 'card') {
                                _showEditCardDialog(method);
                              } else {
                                _showEditMobileMoneyDialog(method);
                              }
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.credit_card),
                            label: const Text('Add Card'),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              _showAddCardDialog();
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.phone_android),
                            label: const Text('Add Mobile Money'),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              _showAddMobileMoneyDialog();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog() {
    final cardholderController = TextEditingController();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Credit/Debit Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardholderController,
              decoration: const InputDecoration(labelText: 'Cardholder Name'),
            ),
            TextField(
              controller: cardNumberController,
              decoration: const InputDecoration(labelText: 'Card Number'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return;
              final cardNumber = cardNumberController.text.trim();
              if (cardNumber.length < 4) return;
              final masked = '**** ${cardNumber.substring(cardNumber.length - 4)}';
              await Supabase.instance.client.from('payment_methods').insert({
                'user_id': user.id,
                'type': 'card',
                'cardholder_name': cardholderController.text.trim(),
                'masked_card': masked,
              });
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              _showPaymentMethodsDialog();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddMobileMoneyDialog() {
    final providerController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mobile Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: providerController,
              decoration: const InputDecoration(labelText: 'Provider (e.g. M-Pesa)'),
            ),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) return;
              await Supabase.instance.client.from('payment_methods').insert({
                'user_id': user.id,
                'type': 'mobile_money',
                'provider': providerController.text.trim(),
                'mobile_number': numberController.text.trim(),
              });
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              _showPaymentMethodsDialog();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditCardDialog(Map<String, dynamic> method) {
    final cardholderController = TextEditingController(text: method['cardholder_name'] ?? '');
    final cardNumberController = TextEditingController(); // Don't prefill for security
    final expiryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardholderController,
              decoration: const InputDecoration(labelText: 'Cardholder Name'),
            ),
            TextField(
              controller: cardNumberController,
              decoration: const InputDecoration(labelText: 'New Card Number (leave blank to keep)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updates = {
                'cardholder_name': cardholderController.text.trim(),
              };
              final cardNumber = cardNumberController.text.trim();
              if (cardNumber.isNotEmpty && cardNumber.length >= 4) {
                updates['masked_card'] = '**** ${cardNumber.substring(cardNumber.length - 4)}';
              }
              await Supabase.instance.client
                  .from('payment_methods')
                  .update(updates)
                  .eq('id', method['id']);
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              _showPaymentMethodsDialog();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditMobileMoneyDialog(Map<String, dynamic> method) {
    final providerController = TextEditingController(text: method['provider'] ?? '');
    final numberController = TextEditingController(text: method['mobile_number'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Mobile Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: providerController,
              decoration: const InputDecoration(labelText: 'Provider (e.g. M-Pesa)'),
            ),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client
                  .from('payment_methods')
                  .update({
                    'provider': providerController.text.trim(),
                    'mobile_number': numberController.text.trim(),
                  })
                  .eq('id', method['id']);
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              _showPaymentMethodsDialog();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchActiveSubscription() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _activeSubscription = null;
        _activePaymentMethod = null;
      });
      return;
    }
    final subs = await Supabase.instance.client
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('started_at', ascending: false)
        .limit(1);
    // ignore: unnecessary_type_check
    if (subs is List && subs.isNotEmpty) {
      // ignore: unnecessary_cast
      final sub = subs.first as Map<String, dynamic>;
      Map<String, dynamic>? method;
      if (sub['payment_method_id'] != null) {
        final methodResp = await Supabase.instance.client
            .from('payment_methods')
            .select()
            .eq('id', sub['payment_method_id'])
            .maybeSingle();
        if (methodResp != null) method = Map<String, dynamic>.from(methodResp);
      }
      setState(() {
        _activeSubscription = sub;
        _activePaymentMethod = method;
        _plan = sub['plan'] ?? 'Free Basic';
        _isPremium = (sub['plan'] == 'Premium' && sub['status'] == 'active');
      });
    } else {
      setState(() {
        _activeSubscription = null;
        _activePaymentMethod = null;
        _plan = 'Free Basic';
        _isPremium = false;
      });
    }
  }

  void _changePaymentMethod() async {
    final selectedId = await _selectPaymentMethodDialog();
    if (selectedId == null || _activeSubscription == null) return;
    await Supabase.instance.client
        .from('subscriptions')
        .update({'payment_method_id': selectedId})
        .eq('id', _activeSubscription!['id']);
    await _fetchActiveSubscription();
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method updated!')),
    );
  }

  void _cancelSubscription() async {
    if (_activeSubscription == null) return;
    await Supabase.instance.client
        .from('subscriptions')
        .update({'status': 'cancelled', 'ended_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', _activeSubscription!['id']);
    await _fetchActiveSubscription();
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription cancelled.')), 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Back',
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isPremium
                          ? 'You have unlimited features.'
                          : 'Free Basic Plan. Upgrade for unlimited features.'),
                      if (_activePaymentMethod != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          // ignore: prefer_interpolation_to_compose_strings
                          'Payment Method: ' +
                              (_activePaymentMethod!['type'] == 'card'
                                  ? (_activePaymentMethod!['masked_card'] ?? 'Card')
                                  : (_activePaymentMethod!['provider'] ?? 'Mobile Money')) +
                              (_activePaymentMethod!['type'] == 'card'
                                  ? ' (${_activePaymentMethod!['cardholder_name'] ?? ''})'
                                  : ' (${_activePaymentMethod!['mobile_number'] ?? ''})'),
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _changePaymentMethod,
                              child: const Text('Change Payment Method'),
                            ),
                            TextButton(
                              onPressed: _cancelSubscription,
                              // ignore: sort_child_properties_last
                              child: const Text('Cancel Subscription'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: (!_isPremium && !kIsWeb)
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
                  onTap: _showPaymentMethodsDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (val) async {
                      setState(() {
                        _notificationsEnabled = val;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_notifPrefKey, val);
                      if (val) {
                        _scheduleSampleNotification();
                      } else {
                        _cancelAllNotifications();
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security & Privacy'),
                  onTap: _showSecurityPrivacyDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: _showHelpSupportDialog,
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