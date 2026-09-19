import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/data_service.dart';
import 'package:hostel_management_system/models/mess_menu_model.dart';

class AdminMessScreen extends StatefulWidget {
  const AdminMessScreen({super.key});

  @override
  State<AdminMessScreen> createState() => _AdminMessScreenState();
}

class _AdminMessScreenState extends State<AdminMessScreen> {
  late Future<List<MessMenuModel>> _menuFuture;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  void _loadMenu() {
    _menuFuture = context.read<DataService>().fetchMessMenu();
  }

  Future<void> _populateDefaultMenu() async {
    final dataService = context.read<DataService>();
    final defaultMenus = [
      MessMenuModel(id: 'M_Mon', dayOfWeek: 'Monday', breakfast: 'Idli, Sambar, Chutney', lunch: 'Rice, Dal Tadka, Paneer Butter Masala, Roti', snacks: 'Samosa, Tea', dinner: 'Chapati, Mixed Veg Curry, Salad'),
      MessMenuModel(id: 'M_Tue', dayOfWeek: 'Tuesday', breakfast: 'Poha, Jalebi', lunch: 'Rajma Chawal, Raita, Papad', snacks: 'Pakora, Coffee', dinner: 'Roti, Dal Makhani, Aloo Gobi'),
      MessMenuModel(id: 'M_Wed', dayOfWeek: 'Wednesday', breakfast: 'Masala Dosa, Sambar', lunch: 'Chole Bhature, Lassi', snacks: 'Bhel Puri, Juice', dinner: 'Veg Fried Rice, Gobi Manchurian'),
      MessMenuModel(id: 'M_Thu', dayOfWeek: 'Thursday', breakfast: 'Upma, Coconut Chutney', lunch: 'Kadhi Pakora, Rice, Roti', snacks: 'Pav Bhaji', dinner: 'Aloo Paratha, Curd, Pickle'),
      MessMenuModel(id: 'M_Fri', dayOfWeek: 'Friday', breakfast: 'Aloo Puri', lunch: 'Veg Biryani, Mirchi Ka Salan, Raita', snacks: 'Bread Pakora, Tea', dinner: 'Roti, Palak Paneer, Jeera Rice'),
      MessMenuModel(id: 'M_Sat', dayOfWeek: 'Saturday', breakfast: 'Vada Pav, Green Chutney', lunch: 'Khichdi, Kadhi, Papad', snacks: 'Dabeli', dinner: 'Roti, Malai Kofta, Dal Fry'),
      MessMenuModel(id: 'M_Sun', dayOfWeek: 'Sunday', breakfast: 'Onion Uttapam', lunch: 'Veg Pulao, Paneer Tikka Masala', snacks: 'Kachori, Tea', dinner: 'Roti, Mutter Paneer, Dal'),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var menu in defaultMenus) {
        await dataService.updateMessMenu(menu);
      }
      if (mounted) {
        Navigator.pop(context); // close loading
        setState(() => _loadMenu());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default Indian Menu populated!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showEditMenuDialog(String day, MessMenuModel? existingMenu) {
    final breakfastCtrl = TextEditingController(text: existingMenu?.breakfast ?? '');
    final lunchCtrl = TextEditingController(text: existingMenu?.lunch ?? '');
    final snacksCtrl = TextEditingController(text: existingMenu?.snacks ?? '');
    final dinnerCtrl = TextEditingController(text: existingMenu?.dinner ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Menu for $day'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: breakfastCtrl, decoration: const InputDecoration(labelText: 'Breakfast', hintText: 'e.g. Idli, Sambar, Chutney'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: lunchCtrl, decoration: const InputDecoration(labelText: 'Lunch', hintText: 'e.g. Rice, Dal, Chapati, Paneer'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: snacksCtrl, decoration: const InputDecoration(labelText: 'Snacks', hintText: 'e.g. Samosa, Tea'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(controller: dinnerCtrl, decoration: const InputDecoration(labelText: 'Dinner', hintText: 'e.g. Fried Rice, Manchurian'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final newMenu = MessMenuModel(
                  id: existingMenu?.id ?? 'M${DateTime.now().millisecondsSinceEpoch}',
                  dayOfWeek: day,
                  breakfast: breakfastCtrl.text.trim().isEmpty ? 'Not specified' : breakfastCtrl.text.trim(),
                  lunch: lunchCtrl.text.trim().isEmpty ? 'Not specified' : lunchCtrl.text.trim(),
                  snacks: snacksCtrl.text.trim().isEmpty ? 'Not specified' : snacksCtrl.text.trim(),
                  dinner: dinnerCtrl.text.trim().isEmpty ? 'Not specified' : dinnerCtrl.text.trim(),
                );
                await context.read<DataService>().updateMessMenu(newMenu);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _loadMenu());
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$day menu updated!')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Menu Management'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _populateDefaultMenu,
            icon: const Icon(Icons.restaurant),
            label: const Text('Populate Default'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<MessMenuModel>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final menuList = snapshot.data ?? [];
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _days.length,
            itemBuilder: (context, index) {
              final day = _days[index];
              // Find menu for this day
              final existingMenuIdx = menuList.indexWhere((m) => m.dayOfWeek == day);
              final existingMenu = existingMenuIdx != -1 ? menuList[existingMenuIdx] : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showEditMenuDialog(day, existingMenu),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (existingMenu == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text('No menu published for this day yet.', style: TextStyle(color: Colors.grey))),
                        )
                      else ...[
                        _buildMealRow('Breakfast', existingMenu.breakfast),
                        _buildMealRow('Lunch', existingMenu.lunch),
                        _buildMealRow('Snacks', existingMenu.snacks),
                        _buildMealRow('Dinner', existingMenu.dinner),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMealRow(String meal, String items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(meal, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Expanded(child: Text(items)),
        ],
      ),
    );
  }
}
