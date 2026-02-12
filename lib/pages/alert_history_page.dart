import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AlertHistoryPage extends StatefulWidget {
  const AlertHistoryPage({super.key});

  @override
  State<AlertHistoryPage> createState() => _AlertHistoryPageState();
}

class _AlertHistoryPageState extends State<AlertHistoryPage> {
  final List<AlertItem> _alerts = [
    AlertItem(
      date: 'Feb 10, 2026',
      time: '10:36 PM',
      type: 'Emergency Escalation',
      status: 'Confirmed Emergency',
      isRealEmergency: true,
    ),
    AlertItem(
      date: 'Feb 8, 2026',
      time: '3:15 PM',
      type: 'Safety Prompt',
      status: 'False Alarm',
      isRealEmergency: false,
    ),
    AlertItem(
      date: 'Feb 5, 2026',
      time: '11:20 PM',
      type: 'Emergency Escalation',
      status: 'False Alarm',
      isRealEmergency: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: _alerts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No alerts yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        context.go('/incident-summary');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${alert.date} • ${alert.time}',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: alert.isRealEmergency
                                        ? AppTheme.dangerColor.withOpacity(0.1)
                                        : AppTheme.warningColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    alert.status,
                                    style: TextStyle(
                                      color: alert.isRealEmergency
                                          ? AppTheme.dangerColor
                                          : AppTheme.warningColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class AlertItem {
  final String date;
  final String time;
  final String type;
  final String status;
  final bool isRealEmergency;

  AlertItem({
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    required this.isRealEmergency,
  });
}
