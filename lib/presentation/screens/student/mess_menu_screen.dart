import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/mess_menu_model.dart';

class MessMenuScreen extends StatefulWidget {
  const MessMenuScreen({super.key});

  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends State<MessMenuScreen> {
  late Future<List<MessMenuModel>> _menuFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture = context.read<DataService>().fetchMessMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Menu'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFeedbackDialog(context),
        icon: const Icon(Icons.feedback),
        label: const Text('Feedback'),
      ),
      body: FutureBuilder<List<MessMenuModel>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final menu = snapshot.data ?? [];
          if (menu.isEmpty) {
            return const Center(child: Text('No mess menu published yet.'));
          }

          // Sort by day of week
          const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          menu.sort((a, b) => daysOfWeek.indexOf(a.dayOfWeek).compareTo(daysOfWeek.indexOf(b.dayOfWeek)));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: menu.length,
            itemBuilder: (context, index) {
              final dayMenu = menu[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ExpansionTile(
                  title: Text(dayMenu.dayOfWeek, style: Theme.of(context).textTheme.titleLarge),
                  initiallyExpanded: index == 0,
                  children: [
                    ListTile(title: const Text('Breakfast'), subtitle: Text(dayMenu.breakfast)),
                    ListTile(title: const Text('Lunch'), subtitle: Text(dayMenu.lunch)),
                    ListTile(title: const Text('Snacks'), subtitle: Text(dayMenu.snacks)),
                    ListTile(title: const Text('Dinner'), subtitle: Text(dayMenu.dinner)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mess Feedback'),
          content: TextField(
            controller: feedbackCtrl,
            decoration: const InputDecoration(
              labelText: 'Your feedback',
              hintText: 'Tell us how the food was...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (feedbackCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback submitted successfully! Thank you.')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
