import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/room_model.dart';

class RoomAllocationMap extends StatefulWidget {
  final String studentId;
  const RoomAllocationMap({super.key, required this.studentId});

  @override
  State<RoomAllocationMap> createState() => _RoomAllocationMapState();
}

class _RoomAllocationMapState extends State<RoomAllocationMap> {
  late Future<List<RoomModel>> _roomsFuture;
  String _selectedBlock = 'A';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    _roomsFuture = context.read<DataService>().fetchAllRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Room Map')),
      body: FutureBuilder<List<RoomModel>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rooms = snapshot.data ?? [];
          final blocks = rooms.map((r) => r.hostelBlock).toSet().toList()..sort();
          
          if (!blocks.contains(_selectedBlock) && blocks.isNotEmpty) {
            _selectedBlock = blocks.first;
          }

          if (blocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No rooms available to allocate.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          final blockRooms = rooms.where((r) => r.hostelBlock == _selectedBlock).toList();
          blockRooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<String>(
                  segments: blocks.map((b) => ButtonSegment(value: b, label: Text('Block $b'))).toList(),
                  selected: {_selectedBlock},
                  onSelectionChanged: (val) {
                    setState(() {
                      _selectedBlock = val.first;
                    });
                  },
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: blockRooms.length,
                  itemBuilder: (context, index) {
                    return _RoomCard(
                      room: blockRooms[index],
                      onBedSelected: (bedId) => _assignBed(context, blockRooms[index], bedId),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _assignBed(BuildContext context, RoomModel room, String bedId) async {
    try {
      await context.read<DataService>().assignRoomToStudent(widget.studentId, room.id, bedId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Student assigned to Room ${room.roomNumber} - Bed $bedId')));
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final Function(String bedId) onBedSelected;

  const _RoomCard({required this.room, required this.onBedSelected});

  @override
  Widget build(BuildContext context) {
    int occupantsCount = room.occupantStudentIds.length;
    double occupancyRate = occupantsCount / room.capacity;
    
    Color statusColor = Colors.green;
    if (occupancyRate == 1.0) statusColor = Colors.red;
    else if (occupancyRate > 0) statusColor = Colors.orange;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: occupantsCount >= room.capacity 
            ? null 
            : () => _showBedSelectionDialog(context),
        child: Column(
          children: [
            Container(
              color: statusColor.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                'Room ${room.roomNumber}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
            ),
            const Spacer(),
            Icon(
              occupancyRate == 1.0 ? Icons.do_not_disturb_on : Icons.meeting_room,
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 8),
            Text('$occupantsCount / ${room.capacity} Beds Full'),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showBedSelectionDialog(BuildContext context) {
    final List<String> allBeds = ['A', 'B', 'C', 'D'].sublist(0, room.capacity);
    // Since mock DB just adds student ids, we assume beds are filled in order for the UI mockup
    final availableBeds = allBeds.sublist(room.occupantStudentIds.length);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Bed in Room ${room.roomNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableBeds.map((bed) {
              return ListTile(
                leading: const Icon(Icons.single_bed),
                title: Text('Bed $bed'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  onBedSelected(bed);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
