import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text('No Data', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                          Text('Overall Attendance', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text('0', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                          Text('Leaves Taken', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Recent Attendance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child: Text("No attendance records found."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
