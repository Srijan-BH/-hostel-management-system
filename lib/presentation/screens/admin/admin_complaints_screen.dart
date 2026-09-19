import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/complaint_model.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  late Future<List<ComplaintModel>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    _complaintsFuture = context.read<DataService>().adminFetchAllComplaints();
  }

  void _showUpdateDialog(ComplaintModel complaint) {
    ComplaintStatus selectedStatus = complaint.status;
    final resolutionCtrl = TextEditingController(text: complaint.adminRemarks ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Update Complaint Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${complaint.category}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (complaint.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(complaint.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<ComplaintStatus>(
                  value: selectedStatus,
                  items: ComplaintStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                  onChanged: (val) => setStateSB(() => selectedStatus = val!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resolutionCtrl,
                  decoration: const InputDecoration(labelText: 'Resolution Remarks', hintText: 'e.g. Fixed by plumber'),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  try {
                    await context.read<DataService>().adminUpdateComplaint(complaint.id, selectedStatus, resolutionCtrl.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _loadComplaints());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint updated successfully')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Update'),
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
        title: const Text('Complaints Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _loadComplaints())),
        ],
      ),
      body: FutureBuilder<List<ComplaintModel>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up_outlined, size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text('No complaints found!', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          // Sort so pending/inProgress are at top
          complaints.sort((a, b) => a.status.index.compareTo(b.status.index));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              
              Color statusColor;
              switch (complaint.status) {
                case ComplaintStatus.submitted: statusColor = Colors.orange; break;
                case ComplaintStatus.inProgress: statusColor = Colors.blue; break;
                case ComplaintStatus.resolved: statusColor = Colors.green; break;
                case ComplaintStatus.rejected: statusColor = Colors.red; break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  title: Text(complaint.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Description: ${complaint.description} | Student: ${complaint.studentId}'),
                      const SizedBox(height: 4),
                      Text('Submitted: ${DateFormat('MMM d, yyyy').format(complaint.submittedAt)}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(complaint.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: statusColor,
                  ),
                  onTap: () => _showUpdateDialog(complaint),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
