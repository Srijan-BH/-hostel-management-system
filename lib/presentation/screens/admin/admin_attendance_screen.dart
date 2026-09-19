import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/student_model.dart';
import 'package:hostel_management_system/models/attendance_model.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  late Future<List<StudentModel>> _studentsFuture;
  late Future<List<AttendanceModel>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final dataService = context.read<DataService>();
    _studentsFuture = dataService.fetchAllStudents();
    _attendanceFuture = dataService.adminFetchAttendanceForDate(_selectedDate);
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right), 
                  onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1))) 
                    ? () => _changeDate(1) 
                    : null,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder(
              future: Future.wait([_studentsFuture, _attendanceFuture]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<StudentModel> allStudents = snapshot.data?[0] ?? [];
                final List<AttendanceModel> dailyAttendance = snapshot.data?[1] ?? [];
                
                // Filter to only students who are assigned to a room
                final activeStudents = allStudents.where((s) => s.roomNumber != null && s.roomNumber!.isNotEmpty).toList();

                if (activeStudents.isEmpty) {
                  return const Center(child: Text('No students assigned to rooms yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: activeStudents.length,
                  itemBuilder: (context, index) {
                    final student = activeStudents[index];
                    
                    // Find if attendance is marked
                    final record = dailyAttendance.where((a) => a.studentId == student.id).firstOrNull;
                    final status = record?.status;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(student.name[0])),
                        title: Text(student.name),
                        subtitle: Text('Room ${student.roomNumber}-${student.bedNumber}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: const Text('Present'),
                              selected: status == AttendanceStatus.present,
                              selectedColor: Colors.green.shade200,
                              onSelected: (val) async {
                                if (val) {
                                  await context.read<DataService>().adminMarkAttendance(student.id, _selectedDate, AttendanceStatus.present);
                                  setState(() => _loadData());
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Absent'),
                              selected: status == AttendanceStatus.absent,
                              selectedColor: Colors.red.shade200,
                              onSelected: (val) async {
                                if (val) {
                                  await context.read<DataService>().adminMarkAttendance(student.id, _selectedDate, AttendanceStatus.absent);
                                  setState(() => _loadData());
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Leave'),
                              selected: status == AttendanceStatus.onLeave,
                              selectedColor: Colors.orange.shade200,
                              onSelected: (val) async {
                                if (val) {
                                  await context.read<DataService>().adminMarkAttendance(student.id, _selectedDate, AttendanceStatus.onLeave);
                                  setState(() => _loadData());
                                }
                              },
                            ),
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
