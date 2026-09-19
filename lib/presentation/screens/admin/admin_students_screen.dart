import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/student_model.dart';
import 'package:hostel_management_system/models/room_model.dart';
import 'package:hostel_management_system/presentation/screens/admin/room_allocation_map.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  late Future<List<StudentModel>> _studentsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    _studentsFuture = context.read<DataService>().fetchAllStudents();
  }

  void _showAddStudentDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final courseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
            TextField(controller: courseController, decoration: const InputDecoration(labelText: 'Course (e.g. B.Tech CS)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final student = StudentModel(
                  id: 'S${DateTime.now().millisecondsSinceEpoch}',
                  email: emailController.text.trim(),
                  name: nameController.text.trim(),
                  phoneNumber: 'Pending',
                  course: courseController.text.trim(),
                  yearSemester: '1st Year',
                  joiningDate: DateTime.now(),
                  guardianName: 'Pending',
                  guardianContact: 'Pending',
                );
                await context.read<DataService>().adminAddStudent(student);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _loadStudents());
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added successfully')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  void _showAssignRoomDialog(StudentModel student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomAllocationMap(studentId: student.id),
      ),
    );
    if (result == true && mounted) {
      setState(() => _loadStudents());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadStudents();
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StudentModel>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allStudents = snapshot.data ?? [];
                final students = allStudents.where((s) {
                  return s.name.toLowerCase().contains(_searchQuery) ||
                         s.email.toLowerCase().contains(_searchQuery);
                }).toList();

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No students found.' : 'No students match your search.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isAssigned = student.roomNumber != null && student.roomNumber!.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                        ),
                        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(student.email, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.meeting_room, size: 14, color: isAssigned ? Colors.green : Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  isAssigned ? 'Room: ${student.roomNumber}-${student.bedNumber ?? ""}' : 'Unassigned',
                                  style: TextStyle(color: isAssigned ? Colors.green.shade700 : Colors.orange.shade700, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.meeting_room),
                          tooltip: 'Assign Room',
                          onPressed: () => _showAssignRoomDialog(student),
                        ),
                        onTap: () {
                          // View details
                        },
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
