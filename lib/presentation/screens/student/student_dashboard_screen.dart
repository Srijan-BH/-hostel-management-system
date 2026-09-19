import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/presentation/widgets/responsive_scaffold.dart';
import 'package:hostel_management_system/models/student_model.dart';
import 'package:hostel_management_system/models/fee_model.dart';
import 'package:hostel_management_system/models/notice_model.dart';
import 'package:hostel_management_system/presentation/screens/auth/role_selection_screen.dart';

import 'package:hostel_management_system/presentation/screens/student/profile_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/room_details_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/attendance_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/leaves_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/complaints_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/service_requests_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/mess_menu_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/fees_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/notices_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/lost_found_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late Future<List<FeeModel>> _feesFuture;
  late Future<List<NoticeModel>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final studentId = authService.currentUser?.id ?? '';
    final dataService = context.read<DataService>();
    
    _feesFuture = dataService.fetchStudentFees(studentId);
    _noticesFuture = dataService.fetchNotices();
  }

  void _logout() {
    context.read<AuthService>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final student = authService.currentUser as StudentModel?;

    if (student == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ResponsiveScaffold(
      title: 'Student Dashboard',
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.meeting_room), label: 'Room'),
        NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Mess'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Lost & Found'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
      railDestinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.meeting_room), label: Text('Room Details')),
        NavigationRailDestination(icon: Icon(Icons.co_present), label: Text('Attendance')),
        NavigationRailDestination(icon: Icon(Icons.exit_to_app), label: Text('Leaves')),
        NavigationRailDestination(icon: Icon(Icons.report_problem), label: Text('Complaints')),
        NavigationRailDestination(icon: Icon(Icons.build), label: Text('Services')),
        NavigationRailDestination(icon: Icon(Icons.restaurant_menu), label: Text('Mess Menu')),
        NavigationRailDestination(icon: Icon(Icons.receipt), label: Text('Fees')),
        NavigationRailDestination(icon: Icon(Icons.notifications), label: Text('Notices')),
        NavigationRailDestination(icon: Icon(Icons.search), label: Text('Lost & Found')),
        NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')), // Added Profile to rail
      ],
      pages: [
        _buildDashboard(context, student), // 0: Dashboard
        const RoomDetailsScreen(),         // 1: Room
        const AttendanceScreen(),          // 2: Attendance
        const LeavesScreen(),              // 3: Leaves
        const ComplaintsScreen(),          // 4: Complaints
        const ServiceRequestsScreen(),     // 5: Services
        const MessMenuScreen(),            // 6: Mess
        const FeesScreen(),                // 7: Fees
        const NoticesScreen(),             // 8: Notices
        const LostFoundScreen(),           // 9: Lost & Found
        const ProfileScreen(),             // 10: Profile
      ],
      // We pass logout to the responsive scaffold in a real app, for now let's just use an appbar action on the pages
    );
  }

  Widget _buildDashboard(BuildContext context, StudentModel student) {
    return Scaffold(
      appBar: MediaQuery.of(context).size.width >= 600
          ? AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
              ],
            )
          : AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
              ],
              automaticallyImplyLeading: false, // Hide back button
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: student.profilePhotoUrl != null ? NetworkImage(student.profilePhotoUrl!) : null,
                  child: student.profilePhotoUrl == null ? Text(student.name.isNotEmpty ? student.name[0] : 'S', style: const TextStyle(fontSize: 24)) : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge),
                    Text(student.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${student.course} - ${student.yearSemester}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                
                String roomString = student.roomNumber != null ? '${student.roomNumber}' : 'Unassigned';
                if (student.bedNumber != null) roomString += '-${student.bedNumber}';

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _DashboardCard(title: 'Room', value: roomString, icon: Icons.meeting_room, color: Colors.blue),
                    _DashboardCard(title: 'Attendance', value: 'No Data', icon: Icons.co_present, color: Colors.green),
                    
                    FutureBuilder<List<FeeModel>>(
                      future: _feesFuture,
                      builder: (context, snapshot) {
                        double totalPending = 0;
                        if (snapshot.hasData) {
                          for (var fee in snapshot.data!) {
                            totalPending += fee.remainingAmount;
                          }
                        }
                        return _DashboardCard(
                          title: 'Pending Fees', 
                          value: snapshot.connectionState == ConnectionState.waiting ? '...' : '₹${totalPending.toStringAsFixed(0)}', 
                          icon: Icons.receipt, 
                          color: Colors.orange
                        );
                      }
                    ),
                    
                    FutureBuilder<List<NoticeModel>>(
                      future: _noticesFuture,
                      builder: (context, snapshot) {
                        return _DashboardCard(
                          title: 'Notices', 
                          value: snapshot.connectionState == ConnectionState.waiting ? '...' : '${snapshot.data?.length ?? 0} New', 
                          icon: Icons.notifications, 
                          color: Colors.red
                        );
                      }
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
