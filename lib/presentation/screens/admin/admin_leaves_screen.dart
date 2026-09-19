import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/leave_request_model.dart';

class AdminLeavesScreen extends StatefulWidget {
  const AdminLeavesScreen({super.key});

  @override
  State<AdminLeavesScreen> createState() => _AdminLeavesScreenState();
}

class _AdminLeavesScreenState extends State<AdminLeavesScreen> {
  late Future<List<LeaveRequestModel>> _leavesFuture;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    _leavesFuture = context.read<DataService>().adminFetchAllLeaveRequests();
  }

  void _showUpdateDialog(LeaveRequestModel leave) {
    final remarksCtrl = TextEditingController(text: leave.adminRemarks ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student ID: ${leave.studentId}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Dates: ${DateFormat('MMM d').format(leave.fromDate)} to ${DateFormat('MMM d').format(leave.toDate)}'),
            const SizedBox(height: 8),
            Text('Reason: ${leave.reason}'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(labelText: 'Admin Remarks (Optional)', hintText: 'e.g. Approved by Warden'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () async {
              await _updateStatus(leave, LeaveStatus.rejected, remarksCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
          FilledButton.icon(
            onPressed: () async {
              await _updateStatus(leave, LeaveStatus.approved, remarksCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(LeaveRequestModel leave, LeaveStatus status, String remarks) async {
    try {
      await context.read<DataService>().adminUpdateLeaveRequest(leave.id, status, remarks);
      if (mounted) {
        setState(() => _loadLeaves());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave ${status.name} successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approvals'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _loadLeaves())),
        ],
      ),
      body: FutureBuilder<List<LeaveRequestModel>>(
        future: _leavesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final leaves = snapshot.data ?? [];
          if (leaves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight_takeoff, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No leave requests found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          // Sort so pending is at top
          leaves.sort((a, b) => a.status.index.compareTo(b.status.index));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              Color statusColor;
              switch (leave.status) {
                case LeaveStatus.pending: statusColor = Colors.orange; break;
                case LeaveStatus.approved: statusColor = Colors.green; break;
                case LeaveStatus.rejected: statusColor = Colors.red; break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  title: Text(leave.leaveType, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Student: ${leave.studentId} | ${DateFormat('MMM d').format(leave.fromDate)} - ${DateFormat('MMM d').format(leave.toDate)}'),
                      const SizedBox(height: 4),
                      Text('Reason: ${leave.reason}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(leave.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: statusColor,
                  ),
                  onTap: () => _showUpdateDialog(leave),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
