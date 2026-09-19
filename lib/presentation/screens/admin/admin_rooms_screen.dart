import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/room_model.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  late Future<List<RoomModel>> _roomsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    _roomsFuture = context.read<DataService>().fetchAllRooms();
  }

  Future<void> _autoAllocate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final count = await context.read<DataService>().autoAllocateRooms();
    if (mounted) {
      Navigator.pop(context);
      setState(() => _loadRooms());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Automatically allocated $count students to rooms!')),
      );
    }
  }

  void _showAddRoomDialog() {
    final blockController = TextEditingController();
    final roomNumController = TextEditingController();
    final capacityController = TextEditingController(text: '2');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: blockController, decoration: const InputDecoration(labelText: 'Hostel Block (e.g. Block A)')),
            TextField(controller: roomNumController, decoration: const InputDecoration(labelText: 'Room Number (e.g. 101)')),
            TextField(controller: capacityController, decoration: const InputDecoration(labelText: 'Capacity (e.g. 2)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final room = RoomModel(
                  id: 'R${DateTime.now().millisecondsSinceEpoch}',
                  roomNumber: roomNumController.text.trim(),
                  hostelBlock: blockController.text.trim(),
                  capacity: int.parse(capacityController.text.trim()),
                  occupantStudentIds: [],
                  facilities: ['Basic'],
                  status: 'Available',
                );
                await context.read<DataService>().addRoom(room);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _loadRooms());
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room added successfully')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Add Room'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome), tooltip: 'Auto Allocate', onPressed: _autoAllocate),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _loadRooms())),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoomDialog,
        icon: const Icon(Icons.add_home),
        label: const Text('Add Room'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search rooms by block or number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RoomModel>>(
              future: _roomsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allRooms = snapshot.data ?? [];
                final rooms = allRooms.where((r) => 
                  r.roomNumber.toLowerCase().contains(_searchQuery) ||
                  r.hostelBlock.toLowerCase().contains(_searchQuery)
                ).toList();

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No rooms found. Create one!', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final isFull = room.occupantStudentIds.length >= room.capacity;
                    return Card(
                      color: isFull ? Colors.grey.shade100 : null,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(room.hostelBlock, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                Icon(Icons.meeting_room, color: isFull ? Colors.red : Colors.green),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Room ${room.roomNumber}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            LinearProgressIndicator(
                              value: room.occupantStudentIds.length / room.capacity,
                              backgroundColor: Colors.grey.shade300,
                              color: isFull ? Colors.red : Colors.green,
                            ),
                            const SizedBox(height: 8),
                            Text('${room.occupantStudentIds.length} / ${room.capacity} Occupied', style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
