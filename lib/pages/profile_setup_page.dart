import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _medicalController = TextEditingController();
  String? _selectedAgeGroup;
  String? _selectedLanguage;
  String _sensitivityMode = 'Normal';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Personalize your safety',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps our AI provide better protection',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              // Age Group
              const Text('Age Group', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['Woman', 'Elderly'].map((group) {
                  final isSelected = _selectedAgeGroup == group;
                  return ChoiceChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedAgeGroup = selected ? group : null;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Medical Info (Optional)
              TextField(
                controller: _medicalController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Medical Information (Optional)',
                  hintText: 'Allergies, conditions, medications...',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
              ),
              const SizedBox(height: 24),
              // Language
              const Text('Preferred Language', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.language),
                ),
                items: ['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam']
                    .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              // Emergency Sensitivity Mode
              Card(
                color: AppTheme.primaryColor.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Emergency Sensitivity Mode',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This directly affects adaptive learning & thresholds',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ...['Normal', 'High', 'Elderly'].map((mode) {
                        return RadioListTile<String>(
                          title: Text(mode),
                          value: mode,
                          groupValue: _sensitivityMode,
                          onChanged: (value) {
                            setState(() {
                              _sensitivityMode = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Continue Button
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty && _selectedAgeGroup != null) {
                    context.go('/trusted-circle');
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
    );
  }
}
