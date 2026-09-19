import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/notice_model.dart';
import 'package:hostel_management_system/services/auth_service.dart';

class AdminNoticesScreen extends StatefulWidget {
  const AdminNoticesScreen({super.key});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  late Future<List<NoticeModel>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    _noticesFuture = context.read<DataService>().adminFetchAllNotices();
  }

  void _showAddNoticeDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    NoticePriority priority = NoticePriority.low;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Broadcast New Notice'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentCtrl,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<NoticePriority>(
                    value: priority,
                    items: NoticePriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                    onChanged: (val) => setStateSB(() => priority = val!),
                    decoration: const InputDecoration(labelText: 'Priority'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
                  
                  try {
                    final admin = context.read<AuthService>().currentUser;
                    final notice = NoticeModel(
                      id: 'N${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      description: contentCtrl.text.trim(),
                      date: DateTime.now(),
                      expiryDate: DateTime.now().add(const Duration(days: 7)),
                      postedByAdminId: admin?.id ?? 'A1001',
                      priority: priority,
                    );
                    await context.read<DataService>().adminAddNotice(notice);
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _loadNotices());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice broadcasted successfully')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Publish'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Broadcasting'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _loadNotices())),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoticeDialog,
        icon: const Icon(Icons.campaign),
        label: const Text('New Notice'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To send a Push Notification to all students\' phones, use the "Messaging" tab in your Firebase Console.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NoticeModel>>(
        future: _noticesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No notices published.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          // Sort newest first
          notices.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              Color priorityColor;
              switch (notice.priority) {
                case NoticePriority.low: priorityColor = Colors.green; break;
                case NoticePriority.medium: priorityColor = Colors.orange; break;
                case NoticePriority.high: priorityColor = Colors.red; break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(notice.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          Chip(
                            label: Text(notice.priority.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                            backgroundColor: priorityColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(notice.description, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('By: ${notice.postedByAdminId}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text(DateFormat('MMM d, yyyy h:mm a').format(notice.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}
