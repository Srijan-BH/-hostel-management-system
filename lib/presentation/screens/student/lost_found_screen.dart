import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/lost_found_model.dart';
import 'package:intl/intl.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  late Future<List<LostFoundModel>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _itemsFuture = context.read<DataService>().fetchLostAndFoundItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Report Item'),
      ),
      body: FutureBuilder<List<LostFoundModel>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];
          
          if (items.isEmpty) {
            return const Center(child: Text('No items reported yet.'));
          }

          // Sort by latest first
          items.sort((a, b) => b.dateReported.compareTo(a.dateReported));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isLost = item.type == LostFoundType.lost;
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
                          Expanded(
                            child: Text(
                              item.itemName, 
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isLost ? Colors.red : Colors.green
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              isLost ? 'LOST' : 'FOUND', 
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                            backgroundColor: isLost ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(item.location, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM dd, HH:mm').format(item.dateReported), style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(item.description),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.contact_phone, size: 16),
                          const SizedBox(width: 8),
                          Text('Contact: ${item.contactInformation}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
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

  void _showReportDialog(BuildContext context) {
    final itemCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    LostFoundType selectedType = LostFoundType.lost;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Report Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<LostFoundType>(
                            title: const Text('Lost'),
                            value: LostFoundType.lost,
                            groupValue: selectedType,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<LostFoundType>(
                            title: const Text('Found'),
                            value: LostFoundType.found,
                            groupValue: selectedType,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: itemCtrl,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locCtrl,
                      decoration: const InputDecoration(labelText: 'Location (where lost/found)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(labelText: 'Your Contact Info'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (itemCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                    
                    final studentId = context.read<AuthService>().currentUser!.id;
                    final item = LostFoundModel(
                      id: 'LF${DateTime.now().millisecondsSinceEpoch}',
                      reportedByUserId: studentId,
                      type: selectedType,
                      itemName: itemCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      dateReported: DateTime.now(),
                      contactInformation: contactCtrl.text.trim(),
                      status: LostFoundStatus.open,
                    );
                    
                    Navigator.pop(context);
                    await context.read<DataService>().submitLostAndFoundItem(item);
                    if (mounted) {
                      setState(() {
                        _loadItems();
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
