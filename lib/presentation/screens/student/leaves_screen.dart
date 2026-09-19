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
    final reasonCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    DateTime? fromDate;
    DateTime? toDate;
    String leaveType = 'Home Visit';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Apply for Leave'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: leaveType,
                      decoration: const InputDecoration(labelText: 'Leave Type'),
                      items: ['Home Visit', 'Sick Leave', 'Event', 'Other']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => leaveType = val!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(fromDate == null ? 'Select Start Date' : 'From: ${DateFormat('MMM dd, yyyy').format(fromDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setDialogState(() => fromDate = date);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(toDate == null ? 'Select End Date' : 'To: ${DateFormat('MMM dd, yyyy').format(toDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: fromDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setDialogState(() => toDate = date);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(labelText: 'Destination Contact Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(labelText: 'Reason for Leave'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (fromDate == null || toDate == null || reasonCtrl.text.trim().isEmpty || contactCtrl.text.trim().isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                       return;
                    }
                    final studentId = context.read<AuthService>().currentUser!.id;
                    final leave = LeaveRequestModel(
                      id: 'LV${DateTime.now().millisecondsSinceEpoch}',
                      studentId: studentId,
                      leaveType: leaveType,
                      fromDate: fromDate!,
                      toDate: toDate!,
                      reason: reasonCtrl.text.trim(),
                      destinationContact: contactCtrl.text.trim(),
                      submittedAt: DateTime.now(),
                      status: LeaveStatus.pending,
                    );
                    Navigator.pop(context);
                    await context.read<DataService>().submitLeaveRequest(leave);
                    if (mounted) {
                      setState(() => _loadLeaves());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted successfully')));
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
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
