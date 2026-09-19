import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_management_system/models/user_model.dart';
import 'package:hostel_management_system/models/student_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isAdmin => _currentUser?.role == UserRole.admin || _currentUser?.role == UserRole.warden;

  AuthService() {
    _checkAuthState();
  }

  void _checkAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
      } else {
        await _fetchUserData(user.uid);
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['role'] == 'student') {
          _currentUser = StudentModel.fromJson(data);
        } else {
          _currentUser = UserModel.fromJson(data);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<bool> login(String email, String password, UserRole expectedRole) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        throw Exception('User profile not found in database.');
      }

      final data = doc.data()!;
      final roleStr = data['role'] as String?;
      
      final bool isStudentRole = roleStr == 'student';
      if (expectedRole == UserRole.student && !isStudentRole) {
        throw Exception('Account is not a student account.');
      }
      if (expectedRole != UserRole.student && isStudentRole) {
        throw Exception('Account does not have admin privileges.');
      }

      if (isStudentRole) {
        _currentUser = StudentModel.fromJson(data);
      } else {
        _currentUser = UserModel.fromJson(data);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newStudent = StudentModel(
        id: cred.user!.uid,
        email: email.toLowerCase(),
        name: name,
        phoneNumber: 'Pending Update',
        course: 'Not Assigned',
        yearSemester: '1st Year',
        joiningDate: DateTime.now(),
        guardianName: 'Pending Update',
        guardianContact: 'Pending Update',
      );

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(newStudent.toJson());
      
      _currentUser = newStudent;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStudentProfile(StudentModel updatedStudent) async {
    _currentUser = updatedStudent;
    await FirebaseFirestore.instance.collection('users').doc(updatedStudent.id).update(updatedStudent.toJson());
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to send reset email';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
