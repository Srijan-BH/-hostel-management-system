import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/service_request_model.dart';
import 'package:intl/intl.dart';

class ServiceRequestsScreen extends StatefulWidget {
  const ServiceRequestsScreen({super.key});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  late Future<List<ServiceRequestModel>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final studentId = context.read<AuthService>().currentUser!.id;
    _requestsFuture = context.read<DataService>().fetchStudentServiceRequests(studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Requests'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewRequestDialog(context),
        icon: const Icon(Icons.build),
        label: const Text('Request Service'),
      ),
      body: FutureBuilder<List<ServiceRequestModel>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];
          
          if (requests.isEmpty) {
            return const Center(child: Text('No active service requests.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
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
                          Text(request.serviceType, style: Theme.of(context).textTheme.titleLarge),
                          _buildStatusChip(request.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Requested: ${DateFormat('MMM dd, yyyy HH:mm').format(request.requestedAt)}'),
                      const SizedBox(height: 8),
                      Text(request.description, style: const TextStyle(color: Colors.grey)),
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

  Widget _buildStatusChip(ServiceRequestStatus status) {
    Color color;
    switch (status) {
      case ServiceRequestStatus.completed: color = Colors.green; break;
      case ServiceRequestStatus.inProgress: color = Colors.blue; break;
      case ServiceRequestStatus.assigned: color = Colors.indigo; break;
      case ServiceRequestStatus.requested: color = Colors.orange; break;
    }
    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  void _showNewRequestDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    String selectedType = 'Room Cleaning';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Request Service'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: ['Room Cleaning', 'Laundry', 'Carpentry', 'Pest Control'].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedType = val!),
                    decoration: const InputDecoration(labelText: 'Service Type'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description/Notes'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (descCtrl.text.trim().isEmpty) return;
                    final studentId = context.read<AuthService>().currentUser!.id;
                    final request = ServiceRequestModel(
                      id: 'SR${DateTime.now().millisecondsSinceEpoch}',
                      studentId: studentId,
                      serviceType: selectedType,
                      description: descCtrl.text.trim(),
                      status: ServiceRequestStatus.requested,
                      requestedAt: DateTime.now(),
                    );
                    Navigator.pop(context);
                    await context.read<DataService>().submitServiceRequest(request);
                    if (mounted) {
                      setState(() {
                        _loadRequests();
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
