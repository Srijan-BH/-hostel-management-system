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
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all, color: Colors.white),
            label: const Text('Mark All Present', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Mark All Present'),
                  content: Text('Mark all unmarked students as Present for ${DateFormat('MMM d').format(_selectedDate)}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
                  ],
                ),
              );
              
              if (confirm == true && mounted) {
                await context.read<DataService>().adminMarkAllPresent(_selectedDate);
                setState(() => _loadData());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All unmarked students marked as Present.')));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
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
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(child: Text(student.name.isNotEmpty ? student.name[0] : 'S')),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student.name.isEmpty ? 'Unknown' : student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Room ${student.roomNumber}-${student.bedNumber}', style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
