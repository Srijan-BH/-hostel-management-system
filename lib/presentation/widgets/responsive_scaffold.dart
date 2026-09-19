import 'package:flutter/material.dart';
import 'package:hostel_management_system/presentation/screens/settings_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/student_dashboard_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/complaints_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/fees_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/mess_menu_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/notices_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/profile_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/service_requests_screen.dart';
import 'package:hostel_management_system/presentation/screens/student/lost_found_screen.dart';
import 'package:hostel_management_system/services/auth_service.dart';

class ResponsiveScaffold extends StatefulWidget {
  final List<NavigationDestination> destinations;
  final List<NavigationRailDestination> railDestinations;
  final List<Widget> pages;
  final String title;
  
  const ResponsiveScaffold({
    super.key,
    required this.destinations,
    required this.railDestinations,
    required this.pages,
    required this.title,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.domain_verification, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 64),
                ],
              ),
            ),
            for (int i = 0; i < widget.railDestinations.length; i++)
              ListTile(
                leading: widget.railDestinations[i].icon,
                title: widget.railDestinations[i].label,
                selected: _selectedIndex == i,
                selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
                onTap: () {
                  setState(() {
                    _selectedIndex = i;
                  });
                  Navigator.pop(context); // Close drawer
                },
              ),
          ],
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: widget.railDestinations,
                        leading: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.domain_verification,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: widget.pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
