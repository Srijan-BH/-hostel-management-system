import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/staff_model.dart';
import 'package:intl/intl.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  late Future<List<StaffModel>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  void _loadStaff() {
    _staffFuture = context.read<DataService>().adminFetchAllStaff();
  }

  void _showAddEditStaffDialog({StaffModel? existingStaff}) {
    final nameCtrl = TextEditingController(text: existingStaff?.name ?? '');
    final roleCtrl = TextEditingController(text: existingStaff?.role ?? '');
    final phoneCtrl = TextEditingController(text: existingStaff?.phone ?? '');
    final shiftCtrl = TextEditingController(text: existingStaff?.shift ?? '');
    final salaryCtrl = TextEditingController(text: existingStaff?.salary.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingStaff == null ? 'Add New Staff' : 'Edit Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (e.g. Guard, Cleaner)')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
              TextField(controller: shiftCtrl, decoration: const InputDecoration(labelText: 'Shift (e.g. Morning, Night)')),
              TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary (₹)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          if (existingStaff != null)
            TextButton(
              onPressed: () async {
                await context.read<DataService>().adminDeleteStaff(existingStaff.id);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _loadStaff());
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final staff = StaffModel(
                id: existingStaff?.id ?? 'STF${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                role: roleCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                shift: shiftCtrl.text.trim(),
                salary: double.tryParse(salaryCtrl.text.trim()) ?? 0.0,
                joinedDate: existingStaff?.joinedDate ?? DateTime.now(),
              );
              
              if (existingStaff == null) {
                await context.read<DataService>().adminAddStaff(staff);
              } else {
                await context.read<DataService>().adminUpdateStaff(staff);
              }
              
              if (mounted) {
                Navigator.pop(context);
                setState(() => _loadStaff());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _loadStaff())),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEditStaffDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: FutureBuilder<List<StaffModel>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final staffList = snapshot.data ?? [];
          if (staffList.isEmpty) {
            return const Center(child: Text('No staff members registered yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.work, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${staff.role} • ${staff.shift} Shift\nPhone: ${staff.phone}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showAddEditStaffDialog(existingStaff: staff),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
