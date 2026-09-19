import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/complaint_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  late Future<List<ComplaintModel>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    final studentId = context.read<AuthService>().currentUser!.id;
    _complaintsFuture = context.read<DataService>().fetchStudentComplaints(studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewComplaintDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
      body: FutureBuilder<List<ComplaintModel>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final complaints = snapshot.data ?? [];
          
          if (complaints.isEmpty) {
            return const Center(child: Text('No complaints submitted yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
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
                          Text(complaint.category, style: Theme.of(context).textTheme.titleLarge),
                          _buildStatusChip(complaint.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(complaint.submittedAt)}'),
                      const SizedBox(height: 8),
                      Text(complaint.description, style: const TextStyle(color: Colors.grey)),
                      if (complaint.imageUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(complaint.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
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

  Widget _buildStatusChip(ComplaintStatus status) {
    Color color;
    switch (status) {
      case ComplaintStatus.resolved: color = Colors.green; break;
      case ComplaintStatus.rejected: color = Colors.red; break;
      case ComplaintStatus.inProgress: color = Colors.blue; break;
      case ComplaintStatus.submitted: color = Colors.orange; break;
    }
    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  void _showNewComplaintDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    String selectedCategory = 'Maintenance';
    XFile? attachedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Complaint'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: ['Maintenance', 'Electrical', 'Plumbing', 'Cleaning', 'Other'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setDialogState(() => attachedImage = image);
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Attach Photo'),
                        ),
                        const SizedBox(width: 8),
                        if (attachedImage != null)
                          const Expanded(child: Text('Image attached', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    if (attachedImage != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(attachedImage!.path, height: 100, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (descCtrl.text.trim().isEmpty) return;
                    final studentId = context.read<AuthService>().currentUser!.id;
                    final complaint = ComplaintModel(
                      id: 'C${DateTime.now().millisecondsSinceEpoch}',
                      studentId: studentId,
                      category: selectedCategory,
                      description: descCtrl.text.trim(),
                      status: ComplaintStatus.submitted,
                      submittedAt: DateTime.now(),
                      imageUrl: attachedImage?.path,
                    );
                    Navigator.pop(context);
                    await context.read<DataService>().submitComplaint(complaint);
                    if (mounted) {
                      setState(() {
                        _loadComplaints();
                      });
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
}
