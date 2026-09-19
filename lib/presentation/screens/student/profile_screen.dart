import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_management_system/services/auth_service.dart';
import 'package:hostel_management_system/models/student_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthService>().currentUser as StudentModel?;

    if (student == null) {
      return const Center(child: Text('No student data found.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, student),
        child: const Icon(Icons.edit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                
                if (image != null && context.mounted) {
                  final updated = StudentModel(
                    id: student.id,
                    email: student.email,
                    name: student.name,
                    phoneNumber: student.phoneNumber,
                    course: student.course,
                    yearSemester: student.yearSemester,
                    roomNumber: student.roomNumber,
                    bedNumber: student.bedNumber,
                    hostelBlock: student.hostelBlock,
                    joiningDate: student.joiningDate,
                    guardianName: student.guardianName,
                    guardianContact: student.guardianContact,
                    profilePhotoUrl: image.path, // Blob URL on web
                  );
                  context.read<AuthService>().updateStudentProfile(updated);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: student.profilePhotoUrl != null ? NetworkImage(student.profilePhotoUrl!) : null,
                    child: student.profilePhotoUrl == null ? Text(student.name[0], style: const TextStyle(fontSize: 48)) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(student.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(student.email, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            _buildInfoCard(context, 'Academic Information', [
              _InfoRow(label: 'Student ID', value: student.id),
              _InfoRow(label: 'Course', value: student.course),
              _InfoRow(label: 'Year/Semester', value: student.yearSemester),
              _InfoRow(label: 'Joining Date', value: DateFormat('MMM dd, yyyy').format(student.joiningDate)),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, 'Contact Information', [
              _InfoRow(label: 'Phone Number', value: student.phoneNumber),
              _InfoRow(label: 'Guardian Name', value: student.guardianName),
              _InfoRow(label: 'Guardian Contact', value: student.guardianContact),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, StudentModel current) {
    final phoneCtrl = TextEditingController(text: current.phoneNumber == 'Pending Update' ? '' : current.phoneNumber);
    final gNameCtrl = TextEditingController(text: current.guardianName == 'Pending Update' ? '' : current.guardianName);
    final gContactCtrl = TextEditingController(text: current.guardianContact == 'Pending Update' ? '' : current.guardianContact);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Your Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gNameCtrl,
                decoration: const InputDecoration(labelText: 'Guardian Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gContactCtrl,
                decoration: const InputDecoration(labelText: 'Guardian Contact'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final updated = StudentModel(
                  id: current.id,
                  email: current.email,
                  name: current.name,
                  phoneNumber: phoneCtrl.text.trim().isEmpty ? 'Pending Update' : phoneCtrl.text.trim(),
                  course: current.course,
                  yearSemester: current.yearSemester,
                  roomNumber: current.roomNumber,
                  bedNumber: current.bedNumber,
                  hostelBlock: current.hostelBlock,
                  joiningDate: current.joiningDate,
                  guardianName: gNameCtrl.text.trim().isEmpty ? 'Pending Update' : gNameCtrl.text.trim(),
                  guardianContact: gContactCtrl.text.trim().isEmpty ? 'Pending Update' : gContactCtrl.text.trim(),
                  profilePhotoUrl: current.profilePhotoUrl,
                );
                context.read<AuthService>().updateStudentProfile(updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
