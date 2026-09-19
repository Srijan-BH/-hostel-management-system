import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/fee_model.dart';
import 'package:hostel_management_system/models/student_model.dart';

class AdminFeesScreen extends StatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  late Future<List<FeeModel>> _feesFuture;
  late Future<List<StudentModel>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final dataService = context.read<DataService>();
    _feesFuture = dataService.adminFetchAllFees();
    _studentsFuture = dataService.fetchAllStudents();
  }

  void _showAddFeeDialog(List<StudentModel> students) {
    String? selectedStudentId;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Hostel Rent - Fall Semester');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Issue New Fee'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedStudentId,
                    items: students.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.roomNumber ?? "No Room"})'))).toList(),
                    onChanged: (val) => setStateSB(() => selectedStudentId = val),
                    decoration: const InputDecoration(labelText: 'Select Student'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (selectedStudentId == null || amountCtrl.text.isEmpty) return;
                  try {
                    final fee = FeeModel(
                      id: 'F${DateTime.now().millisecondsSinceEpoch}',
                      studentId: selectedStudentId!,
                      totalAmount: double.parse(amountCtrl.text.trim()),
                      dueDate: DateTime.now().add(const Duration(days: 30)),
                      status: FeeStatus.pending,
                      description: descCtrl.text.trim(),
                    );
                    await context.read<DataService>().adminAddFee(fee);
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _loadData());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee issued successfully')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Issue Fee'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showUpdateStatusDialog(FeeModel fee) {
    FeeStatus selectedStatus = fee.status;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Update Fee Status'),
            content: DropdownButtonFormField<FeeStatus>(
              value: selectedStatus,
              items: FeeStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
              onChanged: (val) => setStateSB(() => selectedStatus = val!),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  try {
                    await context.read<DataService>().adminUpdateFeeStatus(fee.id, selectedStatus);
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _loadData());
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
        title: const Text('Fee Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _loadData())),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_feesFuture, _studentsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<FeeModel> fees = snapshot.data?[0] ?? [];
          final List<StudentModel> students = snapshot.data?[1] ?? [];

          return Stack(
            children: [
              if (fees.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No fees issued.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
                  itemCount: fees.length,
                  itemBuilder: (context, index) {
                    final fee = fees[index];
                    final student = students.firstWhere((s) => s.id == fee.studentId, orElse: () => StudentModel(id: '', email: '', name: 'Unknown Student', phoneNumber: '', course: '', yearSemester: '', joiningDate: DateTime.now(), guardianName: '', guardianContact: ''));
                    
                    Color statusColor;
                    switch (fee.status) {
                      case FeeStatus.pending: statusColor = Colors.orange; break;
                      case FeeStatus.partiallyPaid: statusColor = Colors.blue; break;
                      case FeeStatus.paid: statusColor = Colors.green; break;
                      case FeeStatus.overdue: statusColor = Colors.red; break;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.attach_money, color: Colors.green.shade800),
                        ),
                        title: Text('₹${fee.totalAmount.toStringAsFixed(2)} - ${fee.description}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Student: ${student.name}'),
                            const SizedBox(height: 4),
                            Text('Due: ${DateFormat('MMM d, yyyy').format(fee.dueDate)}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(fee.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: statusColor,
                        ),
                        onTap: () => _showUpdateStatusDialog(fee),
                      ),
                    );
                  },
                ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddFeeDialog(students),
                  icon: const Icon(Icons.add),
                  label: const Text('Issue Fee'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
