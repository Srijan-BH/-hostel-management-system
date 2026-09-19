import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/notice_model.dart';
import 'package:intl/intl.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  late Future<List<NoticeModel>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _noticesFuture = context.read<DataService>().fetchNotices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hostel Notices'), automaticallyImplyLeading: false),
      body: FutureBuilder<List<NoticeModel>>(
        future: _noticesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notices = snapshot.data ?? [];
          
          if (notices.isEmpty) {
            return const Center(child: Text('No active notices.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final isHighPriority = notice.priority == NoticePriority.high;
              
              return Card(
                color: isHighPriority ? Colors.red.shade50 : null,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notice.title, 
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isHighPriority ? Colors.red.shade900 : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isHighPriority)
                            const Icon(Icons.warning, color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(DateFormat('MMM dd, yyyy').format(notice.date), style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      Text(notice.description),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
