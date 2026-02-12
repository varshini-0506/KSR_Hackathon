import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class EmergencyEscalationPage extends StatefulWidget {
  const EmergencyEscalationPage({super.key});

  @override
  State<EmergencyEscalationPage> createState() => _EmergencyEscalationPageState();
}

class _EmergencyEscalationPageState extends State<EmergencyEscalationPage> {
  final List<String> _alertedContacts = ['Sarah (0.5 km)', 'John (1.2 km)', 'Mom (2.0 km)'];
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dangerColor.withOpacity(0.1),
      appBar: AppBar(
        backgroundColor: AppTheme.dangerColor,
        title: const Text('Emergency in Progress'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('End Emergency?'),
                content: const Text('Are you sure you want to end this emergency?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                    child: const Text('End Emergency'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                color: AppTheme.dangerColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.emergency, size: 48, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Emergency Active',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help is on the way',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Who has been alerted
              const Text(
                'Alerted Contacts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._alertedContacts.map((contact) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.dangerColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: AppTheme.dangerColor),
                      ),
                      title: Text(contact),
                      trailing: Icon(Icons.check_circle, color: AppTheme.successColor),
                    ),
                  )),
              const SizedBox(height: 24),
              // Live Location
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppTheme.dangerColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Live Location',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: 48, color: AppTheme.dangerColor),
                              const SizedBox(height: 8),
                              Text(
                                'Location being shared',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Countdown
              Card(
                color: AppTheme.warningColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Escalation in',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_countdown}s',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Manual Actions
              const Text(
                'Manual Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Call police
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Police'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Send audio snapshot
                },
                icon: const Icon(Icons.mic),
                label: const Text('Send Audio Snapshot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
