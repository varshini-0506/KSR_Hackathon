import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class IncidentSummaryPage extends StatefulWidget {
  const IncidentSummaryPage({super.key});

  @override
  State<IncidentSummaryPage> createState() => _IncidentSummaryPageState();
}

class _IncidentSummaryPageState extends State<IncidentSummaryPage> {
  String? _feedback;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppTheme.primaryColor.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      const Text(
                        'Why Alert Was Triggered',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Reasons
              _buildReasonCard(
                'Unusual Route + Time',
                'You deviated from your usual path at an unusual time',
                Icons.route,
              ),
              const SizedBox(height: 12),
              _buildReasonCard(
                'Sudden Speed Change',
                'Movement pattern changed abruptly',
                Icons.speed,
              ),
              const SizedBox(height: 12),
              _buildReasonCard(
                'No Response',
                'No response to safety check prompt',
                Icons.notifications_off,
              ),
              const SizedBox(height: 24),
              // Timeline
              const Text(
                'Timeline of Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTimelineItem('10:30 PM', 'Unusual route detected'),
              _buildTimelineItem('10:32 PM', 'Speed change detected'),
              _buildTimelineItem('10:35 PM', 'Safety prompt sent'),
              _buildTimelineItem('10:36 PM', 'No response - alert escalated'),
              const SizedBox(height: 24),
              // Sensor Contribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sensor Contribution',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildSensorIndicator('GPS', 0.8),
                      _buildSensorIndicator('Accelerometer', 0.6),
                      _buildSensorIndicator('Companion Detection', 0.3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Feedback
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Was this a real emergency?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _feedback = 'real';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _feedback == 'real' ? AppTheme.dangerColor : AppTheme.primaryColor,
                                  width: _feedback == 'real' ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                'Yes',
                                style: TextStyle(
                                  color: _feedback == 'real' ? AppTheme.dangerColor : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _feedback = 'false';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _feedback == 'false' ? AppTheme.warningColor : AppTheme.primaryColor,
                                  width: _feedback == 'false' ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                'False Alarm',
                                style: TextStyle(
                                  color: _feedback == 'false' ? AppTheme.warningColor : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_feedback != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Feedback submitted - helps improve AI model')),
                            );
                            context.go('/home');
                          },
                          child: const Text('Submit Feedback'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildReasonCard(String title, String description, IconData icon) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildTimelineItem(String time, String event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(event),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorIndicator(String sensor, double contribution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sensor),
              Text('${(contribution * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: contribution,
            backgroundColor: AppTheme.backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
