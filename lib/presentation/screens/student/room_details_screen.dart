import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/models/student_model.dart';

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthService>().currentUser as StudentModel?;

    if (student == null) {
      return const Center(child: Text('No student data found.'));
    }

    final hasRoom = student.roomNumber != null && student.hostelBlock != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Room Details'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: hasRoom ? _buildRoomInfo(context, student) : _buildNoRoom(context),
      ),
    );
  }

  Widget _buildRoomInfo(BuildContext context, StudentModel student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Icon(Icons.meeting_room, size: 64, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Room ${student.roomNumber}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                      Text('${student.hostelBlock} • Bed ${student.bedNumber ?? "N/A"}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('Roommates', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        // Placeholder for roommates (we'd fetch this from DataService)
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Loading roommates...'),
            subtitle: const Text('Feature coming soon'),
          ),
        ),
      ],
    );
  }

  Widget _buildNoRoom(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.meeting_room_outlined, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'No Room Assigned',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text('Please contact the warden for room allocation.'),
        ],
      ),
    );
  }
}
