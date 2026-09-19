import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/service_request_model.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  late Future<List<ServiceRequestModel>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    _servicesFuture = context.read<DataService>().adminFetchAllServiceRequests();
  }

  void _showUpdateDialog(ServiceRequestModel service) {
    ServiceRequestStatus selectedStatus = service.status;
    final assignedToCtrl = TextEditingController(text: service.assignedTo ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Update Service Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${service.serviceType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Desc: ${service.description}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<ServiceRequestStatus>(
                  value: selectedStatus,
                  items: ServiceRequestStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                  onChanged: (val) => setStateSB(() => selectedStatus = val!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: assignedToCtrl,
                  decoration: const InputDecoration(labelText: 'Assigned To (Staff Name)', hintText: 'e.g. John (Electrician)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  try {
                    await context.read<DataService>().adminUpdateServiceRequest(service.id, selectedStatus, assignedToCtrl.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _loadServices());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service request updated')));
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
        title: const Text('Service Requests (Staff)'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _loadServices())),
        ],
      ),
      body: FutureBuilder<List<ServiceRequestModel>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No service requests.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          services.sort((a, b) => a.status.index.compareTo(b.status.index));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              
              Color statusColor;
              switch (service.status) {
                case ServiceRequestStatus.requested: statusColor = Colors.orange; break;
                case ServiceRequestStatus.assigned: statusColor = Colors.indigo; break;
                case ServiceRequestStatus.inProgress: statusColor = Colors.blue; break;
                case ServiceRequestStatus.completed: statusColor = Colors.green; break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Icon(Icons.build),
                  ),
                  title: Text(service.serviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Student: ${service.studentId}'),
                      if (service.assignedTo != null && service.assignedTo!.isNotEmpty)
                        Text('Assigned To: ${service.assignedTo}', style: TextStyle(color: Colors.indigo.shade700)),
                      const SizedBox(height: 4),
                      Text('Requested: ${DateFormat('MMM d, yyyy').format(service.requestedAt)}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(service.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: statusColor,
                  ),
                  onTap: () => _showUpdateDialog(service),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
