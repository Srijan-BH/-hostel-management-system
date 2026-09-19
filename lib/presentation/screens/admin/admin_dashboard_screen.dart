import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/presentation/widgets/responsive_scaffold.dart';
import 'package:hostel_management_system/presentation/screens/auth/role_selection_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_students_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_rooms_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_mess_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_attendance_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_complaints_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_leaves_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_services_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_fees_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_notices_screen.dart';
import 'package:hostel_management_system/presentation/screens/admin/admin_staff_screen.dart';
import 'package:hostel_management_system/utils/pdf_generator.dart';
import 'package:hostel_management_system/models/room_model.dart';
import 'package:hostel_management_system/models/fee_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<int> _totalStudentsFuture;
  late Future<int> _availableRoomsFuture;
  late Future<int> _pendingLeavesFuture;
  late Future<int> _openComplaintsFuture;

  @override
  void initState() {
    super.initState();
    final dataService = context.read<DataService>();
    _totalStudentsFuture = dataService.getTotalStudentsCount();
    _availableRoomsFuture = dataService.getAvailableRoomsCount();
    _pendingLeavesFuture = dataService.getPendingLeavesCount();
    _openComplaintsFuture = dataService.getOpenComplaintsCount();
  }

  void _logout(BuildContext context) {
    context.read<AuthService>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  Future<void> _generatePdfReport(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final dataService = context.read<DataService>();
      final students = await dataService.fetchAllStudents();
      final rooms = await dataService.fetchAllRooms();
      final fees = await dataService.adminFetchAllFees();
      
      if (context.mounted) {
        Navigator.pop(context); // close loader
        await PdfGenerator.generateAndPrintHostelReport(
          students: students,
          rooms: rooms,
          fees: fees,
        );
      }
    } catch(e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final admin = authService.currentUser;

    if (admin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ResponsiveScaffold(
      title: 'Admin Dashboard',
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
        NavigationDestination(icon: Icon(Icons.report_problem), label: 'Complaints'),
        NavigationDestination(icon: Icon(Icons.notifications), label: 'Notices'),
        NavigationDestination(icon: Icon(Icons.work), label: 'Staff'),
      ],
      railDestinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.people), label: Text('Students')),
        NavigationRailDestination(icon: Icon(Icons.meeting_room), label: Text('Rooms')),
        NavigationRailDestination(icon: Icon(Icons.co_present), label: Text('Attendance')),
        NavigationRailDestination(icon: Icon(Icons.exit_to_app), label: Text('Leaves')),
        NavigationRailDestination(icon: Icon(Icons.report_problem), label: Text('Complaints')),
        NavigationRailDestination(icon: Icon(Icons.build), label: Text('Services')),
        NavigationRailDestination(icon: Icon(Icons.receipt), label: Text('Fees')),
        NavigationRailDestination(icon: Icon(Icons.restaurant_menu), label: Text('Mess')),
        NavigationRailDestination(icon: Icon(Icons.notifications), label: Text('Notices')),
        NavigationRailDestination(icon: Icon(Icons.work), label: Text('Staff')),
      ],
      pages: [
        _buildDashboard(context, admin.name, () => _logout(context)),
        const AdminStudentsScreen(),
        const AdminRoomsScreen(),
        const AdminAttendanceScreen(),
        const AdminLeavesScreen(),
        const AdminComplaintsScreen(),
        const AdminServicesScreen(),
        const AdminFeesScreen(),
        const AdminMessScreen(),
        const AdminNoticesScreen(),
        const AdminStaffScreen(),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context, String adminName, VoidCallback onLogout) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: MediaQuery.of(context).size.width >= 600,
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Download Report', onPressed: () => _generatePdfReport(context)),
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
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
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(Icons.admin_panel_settings, size: 32, color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge),
                    Text(adminName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('System Administrator', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Analytics Charts Section
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Room Occupancy', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                  final rooms = snapshot.data!.docs.map((doc) => RoomModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
                                  int fullCount = rooms.where((r) => r.occupantStudentIds.length >= r.capacity).length;
                                  int availCount = rooms.length - fullCount;
                                  if (rooms.isEmpty) return const Center(child: Text('No Rooms Data'));
                                  if (availCount == 0 && fullCount == 0) return const Center(child: Text('No Rooms'));
                                  return PieChart(
                                    PieChartData(
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        PieChartSectionData(color: Colors.green, value: availCount.toDouble(), title: 'Avail\n$availCount', radius: 35, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                                        PieChartSectionData(color: Colors.red, value: fullCount.toDouble(), title: 'Full\n$fullCount', radius: 35, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Fee Collection (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('fees').snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                  final fees = snapshot.data!.docs.map((doc) => FeeModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
                                  double totalExpected = fees.fold(0.0, (sum, f) => sum + f.totalAmount);
                                  double totalPaid = fees.fold(0.0, (sum, f) => sum + f.paidAmount);
                                  double totalPending = totalExpected - totalPaid;
                                  if (totalExpected == 0) return const Center(child: Text('No Fee Data'));
                                  
                                  return BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: totalExpected > 0 ? totalExpected : 100,
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (val, meta) {
                                              if (val == 0) return const Text('Paid', style: TextStyle(fontSize: 10));
                                              if (val == 1) return const Text('Pending', style: TextStyle(fontSize: 10));
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: [
                                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totalPaid, color: Colors.blue, width: 22)]),
                                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalPending, color: Colors.orange, width: 22)]),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Total Students', _totalStudentsFuture, Icons.people, Colors.blue),
                    _buildStatCard('Available Rooms', _availableRoomsFuture, Icons.meeting_room, Colors.green),
                    _buildStatCard('Pending Leaves', _pendingLeavesFuture, Icons.exit_to_app, Colors.orange),
                    _buildStatCard('Open Complaints', _openComplaintsFuture, Icons.report_problem, Colors.red),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, Future<int> future, IconData icon, Color color) {
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
                  child: FutureBuilder<int>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      return Text('${snapshot.data ?? 0}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
                    }
                  ),
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
