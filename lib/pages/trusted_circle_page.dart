import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class TrustedCirclePage extends StatefulWidget {
  const TrustedCirclePage({super.key});

  @override
  State<TrustedCirclePage> createState() => _TrustedCirclePageState();
}

class _TrustedCirclePageState extends State<TrustedCirclePage> {
  final List<TrustedContact> _contacts = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Your Trusted Circle',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These contacts will be alerted in emergencies',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    // Add Contact Button
                    OutlinedButton.icon(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Trusted Contact'),
                    ),
                    const SizedBox(height: 24),
                    // Contacts List
                    if (_contacts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'No contacts added yet',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._contacts.map((contact) => _buildContactCard(contact)),
                    const SizedBox(height: 24),
                    // Distance Preview
                    if (_contacts.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Distance Preview',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Closest contact: ${_contacts.isNotEmpty ? _contacts.first.name : "None"}',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Distance: ${_contacts.isNotEmpty ? "0.5 km" : "N/A"}',
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
            // Continue Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _contacts.isNotEmpty
                    ? () {
                        context.go('/home');
                      }
                    : null,
                child: const Text('Continue to Dashboard'),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildContactCard(TrustedContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getPriorityIcon(contact.priority),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(contact.name),
        subtitle: Text('${contact.phone} • ${contact.priority}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
          onPressed: () {
            setState(() {
              _contacts.remove(contact);
            });
          },
        ),
      ),
    );
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Nearby Responder':
        return Icons.near_me;
      case 'Guardian':
        return Icons.shield;
      case 'Emergency Only':
        return Icons.emergency;
      default:
        return Icons.person;
    }
  }

  void _addContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedPriority = 'Nearby Responder';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Trusted Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600)),
              ...['Nearby Responder', 'Guardian', 'Emergency Only'].map((priority) {
                return RadioListTile<String>(
                  title: Text(priority),
                  value: priority,
                  groupValue: selectedPriority,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPriority = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  setState(() {
                    _contacts.add(TrustedContact(
                      name: nameController.text,
                      phone: phoneController.text,
                      priority: selectedPriority,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class TrustedContact {
  final String name;
  final String phone;
  final String priority;

  TrustedContact({
    required this.name,
    required this.phone,
    required this.priority,
  });
}
