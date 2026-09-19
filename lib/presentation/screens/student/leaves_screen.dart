import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/leave_request_model.dart';
import 'package:intl/intl.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  late Future<List<LeaveRequestModel>> _leavesFuture;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  void _loadLeaves() {
    final studentId = context.read<AuthService>().currentUser!.id;
    _leavesFuture = context.read<DataService>().fetchStudentLeaves(studentId);
  }

  void _showApplyLeaveDialog() {
    // Dialog logic to apply for leave
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave application form goes here')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyLeaveDialog,
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
      body: FutureBuilder<List<LeaveRequestModel>>(
        future: _leavesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final leaves = snapshot.data ?? [];
          
          if (leaves.isEmpty) {
            return const Center(child: Text('No leave requests found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(leave.leaveType, style: Theme.of(context).textTheme.titleLarge),
                          _buildStatusChip(leave.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('From: ${DateFormat('MMM dd, yyyy').format(leave.fromDate)}'),
                      Text('To: ${DateFormat('MMM dd, yyyy').format(leave.toDate)}'),
                      const SizedBox(height: 8),
                      Text('Reason: ${leave.reason}', style: const TextStyle(color: Colors.grey)),
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

  Widget _buildStatusChip(LeaveStatus status) {
    Color color;
    switch (status) {
      case LeaveStatus.approved: color = Colors.green; break;
      case LeaveStatus.rejected: color = Colors.red; break;
      case LeaveStatus.pending: color = Colors.orange; break;
    }
    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }
}
