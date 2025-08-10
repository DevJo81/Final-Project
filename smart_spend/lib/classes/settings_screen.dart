import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// ignore: unused_import
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: unused_import
import 'dart:io' show Platform;

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
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      // Ignore notification initialization errors on web
      // print('Notification initialization error: $e');
    }
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
    try {
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
    } catch (e) {
      // Ignore notification scheduling errors on web
      // print('Notification scheduling error: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      // Ignore notification errors on web or when plugin is not initialized
      // print('Notification error: $e');
    }
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
    // Always show web payment dialog
    _showWebPaymentDialog();
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

  void _enableDemoMode() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('subscriptions').insert({
      'user_id': user.id,
      'payment_method_id': null, // No real payment method for demo
      'plan': 'Premium',
      'status': 'active',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _fetchActiveSubscription();

    setState(() {
      _plan = 'Premium';
      _isPremium = true;
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo mode enabled!')),
    );
  }

  void _disableDemoMode() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Cancel the demo subscription by finding subscriptions with null payment_method_id
    final demoSubscriptions = await Supabase.instance.client
        .from('subscriptions')
        .select('id, payment_method_id')
        .eq('user_id', user.id)
        .eq('status', 'active');

    if (demoSubscriptions.isNotEmpty) {
      for (final subscription in demoSubscriptions) {
        // Check if this is a demo subscription (payment_method_id is null)
        if (subscription['payment_method_id'] == null) {
          await Supabase.instance.client
              .from('subscriptions')
              .update({
                'status': 'cancelled', 
                'ended_at': DateTime.now().toUtc().toIso8601String()
              })
              .eq('id', subscription['id']);
        }
      }
    }

    await _fetchActiveSubscription();

    setState(() {
      _plan = 'Free Basic';
      _isPremium = false;
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo mode disabled!')),
    );
  }

  void _showWebPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Premium Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• Unlimited savings goals'),
              const Text('• Unlimited budget categories'),
              const Text('• Advanced analytics & insights'),
              const Text('• Priority customer support'),
              const Text('• Export financial reports'),
              const Text('• Custom budget alerts'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Only 5000 TSH/month',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cancel anytime • No hidden fees',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_android, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '📱 Download Mobile App',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To access premium features with secure payments, download our mobile app:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Replace with your actual Google Play Store URL when published
                              const url = 'https://play.google.com/store/apps/details?id=com.example.smart_spend';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              } else {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(content: Text('Could not open Google Play Store')),
                                );
                              }
                            },
                            icon: const Icon(Icons.android, size: 16),
                            label: const Text('Google Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Replace with your actual App Store URL when published
                              // This opens App Store search for "Smart Spend"
                              const url = 'https://apps.apple.com/us/search?term=Smart%20Spend';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              } else {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(content: Text('Could not open App Store')),
                                );
                              }
                            },
                            icon: const Icon(Icons.apple, size: 16),
                            label: const Text('App Store'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange.shade600, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Try premium features now with demo mode - no payment required!',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _enableDemoMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Demo Mode'),
          ),
        ],
      ),
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
                  trailing: (!_isPremium)
                      ? ElevatedButton(
                          onPressed: _upgradePlan,
                          child: const Text('Upgrade'),
                        )
                      : null,
                ),
                // Add demo mode for testing
                if (!_isPremium)
                  ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Demo Mode'),
                    subtitle: const Text('Test premium features without payment'),
                    trailing: ElevatedButton(
                      onPressed: _enableDemoMode,
                      child: const Text('Enable Demo'),
                    ),
                  ),
                if (_isPremium && _activeSubscription?['payment_method_id'] == null)
                  ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Demo Mode Active'),
                    subtitle: const Text('Currently in demo mode'),
                    trailing: ElevatedButton(
                      onPressed: _disableDemoMode,
                      child: const Text('Disable Demo'),
                    ),
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

