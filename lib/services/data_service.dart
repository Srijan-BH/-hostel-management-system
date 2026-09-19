import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_management_system/models/student_model.dart';
import 'package:hostel_management_system/models/leave_request_model.dart';
import 'package:hostel_management_system/models/complaint_model.dart';
import 'package:hostel_management_system/models/fee_model.dart';
import 'package:hostel_management_system/models/notice_model.dart';
import 'package:hostel_management_system/models/mess_menu_model.dart';
import 'package:hostel_management_system/models/room_model.dart';
import 'package:hostel_management_system/models/attendance_model.dart';
import 'package:hostel_management_system/models/service_request_model.dart';
import 'package:hostel_management_system/models/lost_found_model.dart';
import 'package:hostel_management_system/models/staff_model.dart';
import 'package:hostel_management_system/services/notification_service.dart';

class DataService extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<NoticeModel>> fetchNotices() async {
    final query = await _db.collection('notices').get();
    return query.docs.map((doc) => NoticeModel.fromJson(doc.data())).where((n) => !n.isExpired).toList();
  }

  Future<List<FeeModel>> fetchStudentFees(String studentId) async {
    final query = await _db.collection('fees').where('studentId', isEqualTo: studentId).get();
    return query.docs.map((doc) => FeeModel.fromJson(doc.data())).toList();
  }

  Future<bool> processFeePayment(String feeId, double amountPaid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final docRef = _db.collection('fees').doc(feeId);
      final doc = await docRef.get();
      if (doc.exists) {
        final fee = FeeModel.fromJson(doc.data()!);
        final newPaidAmount = fee.paidAmount + amountPaid;
        final newStatus = newPaidAmount >= fee.totalAmount ? FeeStatus.paid : FeeStatus.partiallyPaid;
        
        await docRef.update({
          'paidAmount': newPaidAmount,
          'status': newStatus.name,
        });
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<List<LeaveRequestModel>> fetchStudentLeaves(String studentId) async {
    final query = await _db.collection('leaveRequests').where('studentId', isEqualTo: studentId).get();
    return query.docs.map((doc) => LeaveRequestModel.fromJson(doc.data())).toList();
  }
  
  Future<void> submitLeaveRequest(LeaveRequestModel request) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('leaveRequests').doc(request.id).set(request.toJson());
    _isLoading = false;
    notifyListeners();
  }

  Future<List<ComplaintModel>> fetchStudentComplaints(String studentId) async {
    final query = await _db.collection('complaints').where('studentId', isEqualTo: studentId).get();
    return query.docs.map((doc) => ComplaintModel.fromJson(doc.data())).toList();
  }

  Future<void> submitComplaint(ComplaintModel complaint) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('complaints').doc(complaint.id).set(complaint.toJson());
    _isLoading = false;
    notifyListeners();
  }

  Future<List<MessMenuModel>> fetchMessMenu() async {
    final query = await _db.collection('messMenu').get();
    return query.docs.map((doc) => MessMenuModel.fromJson(doc.data())).toList();
  }

  Future<List<ServiceRequestModel>> fetchStudentServiceRequests(String studentId) async {
    final query = await _db.collection('serviceRequests').where('studentId', isEqualTo: studentId).get();
    return query.docs.map((doc) => ServiceRequestModel.fromJson(doc.data())).toList();
  }

  Future<void> submitServiceRequest(ServiceRequestModel request) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('serviceRequests').doc(request.id).set(request.toJson());
    _isLoading = false;
    notifyListeners();
  }

  Future<List<LostFoundModel>> fetchLostAndFoundItems() async {
    final query = await _db.collection('lostAndFoundItems').get();
    return query.docs.map((doc) => LostFoundModel.fromJson(doc.data())).toList();
  }

  Future<void> submitLostAndFoundItem(LostFoundModel item) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('lostAndFoundItems').doc(item.id).set(item.toJson());
    _isLoading = false;
    notifyListeners();
  }

  // --- ADMIN METHODS ---

  Future<int> getTotalStudentsCount() async {
    try {
      final query = await _db.collection('users').where('role', isEqualTo: 'student').count().get();
      return query.count ?? 0;
    } catch(e) { return 0; }
  }

  Future<int> getAvailableRoomsCount() async {
    try {
      final query = await _db.collection('rooms').where('status', isEqualTo: 'Available').count().get();
      return query.count ?? 0;
    } catch(e) { return 0; }
  }

  Future<int> getPendingLeavesCount() async {
    try {
      final query = await _db.collection('leaveRequests').where('status', isEqualTo: 'pending').count().get();
      return query.count ?? 0;
    } catch (e) { return 0; }
  }

  Future<int> getOpenComplaintsCount() async {
    try {
      final query = await _db.collection('complaints').where('status', isNotEqualTo: 'resolved').count().get();
      return query.count ?? 0;
    } catch (e) { return 0; }
  }

  Future<List<StudentModel>> fetchAllStudents() async {
    final query = await _db.collection('users').where('role', isEqualTo: 'student').get();
    return query.docs.map((doc) => StudentModel.fromJson(doc.data())).toList();
  }

  Future<void> adminAddStudent(StudentModel student) async {
    final query = await _db.collection('users').where('email', isEqualTo: student.email.toLowerCase()).get();
    if (query.docs.isNotEmpty) {
      throw Exception('Email already exists');
    }
    await _db.collection('users').doc(student.id).set(student.toJson());
    notifyListeners();
  }

  Future<List<RoomModel>> fetchAllRooms() async {
    final query = await _db.collection('rooms').get();
    return query.docs.map((doc) => RoomModel.fromJson(doc.data())).toList();
  }

  Future<void> addRoom(RoomModel room) async {
    final query = await _db.collection('rooms').where('roomNumber', isEqualTo: room.roomNumber).where('hostelBlock', isEqualTo: room.hostelBlock).get();
    if (query.docs.isNotEmpty) {
      throw Exception('Room already exists in this block');
    }
    await _db.collection('rooms').doc(room.id).set(room.toJson());
    notifyListeners();
  }

  Future<void> assignRoomToStudent(String studentId, String roomId, String bed) async {
    final studentDoc = await _db.collection('users').doc(studentId).get();
    final roomDoc = await _db.collection('rooms').doc(roomId).get();
    
    if (studentDoc.exists && roomDoc.exists) {
      final room = RoomModel.fromJson(roomDoc.data()!);
      if (room.occupantStudentIds.length >= room.capacity) {
        throw Exception('Room is full');
      }
      
      await _db.collection('users').doc(studentId).update({
        'roomNumber': room.roomNumber,
        'bedNumber': bed,
        'hostelBlock': room.hostelBlock,
      });

      room.occupantStudentIds.add(studentId);
      await _db.collection('rooms').doc(roomId).update({
        'occupantStudentIds': room.occupantStudentIds,
      });
      notifyListeners();
    }
  }

  Future<void> updateMessMenu(MessMenuModel updatedMenu) async {
    final query = await _db.collection('messMenu').where('dayOfWeek', isEqualTo: updatedMenu.dayOfWeek).get();
    if (query.docs.isNotEmpty) {
      await _db.collection('messMenu').doc(query.docs.first.id).update(updatedMenu.toJson());
    } else {
      await _db.collection('messMenu').doc(updatedMenu.dayOfWeek).set(updatedMenu.toJson());
    }
    notifyListeners();
  }

  Future<List<AttendanceModel>> adminFetchAttendanceForDate(DateTime date) async {
    final query = await _db.collection('attendance').get();
    return query.docs.map((doc) => AttendanceModel.fromJson(doc.data())).where((a) => 
      a.date.year == date.year && a.date.month == date.month && a.date.day == date.day
    ).toList();
  }

  Future<void> adminMarkAttendance(String studentId, DateTime date, AttendanceStatus status) async {
    final query = await _db.collection('attendance').where('studentId', isEqualTo: studentId).get();
    final filtered = query.docs.map((doc) => AttendanceModel.fromJson(doc.data())).where((a) => 
      a.date.year == date.year && a.date.month == date.month && a.date.day == date.day
    ).toList();

    if (filtered.isNotEmpty) {
      await _db.collection('attendance').doc(filtered.first.id).update({
        'status': status.name,
        'markedByAdminId': 'A1001',
      });
    } else {
      final id = 'ATT${DateTime.now().millisecondsSinceEpoch}';
      await _db.collection('attendance').doc(id).set(AttendanceModel(
        id: id,
        studentId: studentId,
        date: date,
        status: status,
        markedByAdminId: 'A1001',
      ).toJson());
    }
    notifyListeners();
  }

  Future<List<ComplaintModel>> adminFetchAllComplaints() async {
    final query = await _db.collection('complaints').get();
    return query.docs.map((doc) => ComplaintModel.fromJson(doc.data())).toList();
  }

  Future<void> adminUpdateComplaint(String complaintId, ComplaintStatus newStatus, String resolution) async {
    final doc = await _db.collection('complaints').doc(complaintId).get();
    if (doc.exists) {
      final old = ComplaintModel.fromJson(doc.data()!);
      await _db.collection('complaints').doc(complaintId).update({
        'status': newStatus.name,
        'adminRemarks': resolution.isNotEmpty ? resolution : old.adminRemarks,
      });
      notifyListeners();
    }
  }

  Future<List<LeaveRequestModel>> adminFetchAllLeaveRequests() async {
    final query = await _db.collection('leaveRequests').get();
    return query.docs.map((doc) => LeaveRequestModel.fromJson(doc.data())).toList();
  }

  Future<void> adminUpdateLeaveRequest(String id, LeaveStatus status, String adminRemarks) async {
    final doc = await _db.collection('leaveRequests').doc(id).get();
    if (doc.exists) {
      final old = LeaveRequestModel.fromJson(doc.data()!);
      await _db.collection('leaveRequests').doc(id).update({
        'status': status.name,
        'adminRemarks': adminRemarks.isNotEmpty ? adminRemarks : old.adminRemarks,
      });
      notifyListeners();
      
      NotificationService().showNotification(
        id: DateTime.now().millisecond,
        title: 'Leave Request Updated',
        body: 'A leave request has been ${status.name}.',
      );
    }
  }

  Future<List<ServiceRequestModel>> adminFetchAllServiceRequests() async {
    final query = await _db.collection('serviceRequests').get();
    return query.docs.map((doc) => ServiceRequestModel.fromJson(doc.data())).toList();
  }

  Future<void> adminUpdateServiceRequest(String id, ServiceRequestStatus status, String assignedTo) async {
    final doc = await _db.collection('serviceRequests').doc(id).get();
    if (doc.exists) {
      final old = ServiceRequestModel.fromJson(doc.data()!);
      await _db.collection('serviceRequests').doc(id).update({
        'status': status.name,
        'assignedTo': assignedTo.isNotEmpty ? assignedTo : old.assignedTo,
      });
      notifyListeners();
    }
  }

  Future<List<FeeModel>> adminFetchAllFees() async {
    final query = await _db.collection('fees').get();
    return query.docs.map((doc) => FeeModel.fromJson(doc.data())).toList();
  }

  Future<void> adminAddFee(FeeModel fee) async {
    await _db.collection('fees').doc(fee.id).set(fee.toJson());
    notifyListeners();
  }

  Future<void> adminUpdateFeeStatus(String feeId, FeeStatus status) async {
    await _db.collection('fees').doc(feeId).update({
      'status': status.name,
    });
    notifyListeners();
  }

  Future<List<NoticeModel>> adminFetchAllNotices() async {
    final query = await _db.collection('notices').get();
    return query.docs.map((doc) => NoticeModel.fromJson(doc.data())).toList();
  }

  Future<void> adminAddNotice(NoticeModel notice) async {
    await _db.collection('notices').doc(notice.id).set(notice.toJson());
    notifyListeners();
    
    NotificationService().showNotification(
      id: DateTime.now().millisecond,
      title: 'New Notice Broadcasted!',
      body: notice.title,
    );
  }

  // --- STAFF MANAGEMENT ---
  Future<List<StaffModel>> adminFetchAllStaff() async {
    final query = await _db.collection('staff').get();
    return query.docs.map((doc) => StaffModel.fromJson(doc.data())).toList();
  }

  Future<void> adminAddStaff(StaffModel staff) async {
    await _db.collection('staff').doc(staff.id).set(staff.toJson());
    notifyListeners();
  }

  Future<void> adminUpdateStaff(StaffModel staff) async {
    await _db.collection('staff').doc(staff.id).update(staff.toJson());
    notifyListeners();
  }

  Future<void> adminDeleteStaff(String staffId) async {
    await _db.collection('staff').doc(staffId).delete();
    notifyListeners();
  }

  // --- AUTOMATED ROOM ALLOCATION ---
  Future<int> autoAllocateRooms() async {
    _isLoading = true;
    notifyListeners();

    int allocatedCount = 0;
    try {
      final studentsQuery = await _db.collection('users').where('role', isEqualTo: 'student').where('roomNumber', isNull: true).get();
      final unassignedStudents = studentsQuery.docs.map((d) => StudentModel.fromJson(d.data())).toList();

      final roomsQuery = await _db.collection('rooms').where('status', isEqualTo: 'Available').get();
      final availableRooms = roomsQuery.docs.map((d) => RoomModel.fromJson(d.data())).toList();

      if (unassignedStudents.isNotEmpty && availableRooms.isNotEmpty) {
        WriteBatch batch = _db.batch();
        int roomIndex = 0;
        
        for (var student in unassignedStudents) {
          if (roomIndex >= availableRooms.length) break;
          
          var currentRoom = availableRooms[roomIndex];
          
          String assignedBed = 'A';
          if (currentRoom.occupantStudentIds.length == 1) assignedBed = 'B';
          if (currentRoom.occupantStudentIds.length == 2) assignedBed = 'C';
          if (currentRoom.occupantStudentIds.length == 3) assignedBed = 'D';

          final studentRef = _db.collection('users').doc(student.id);
          batch.update(studentRef, {
            'roomNumber': currentRoom.roomNumber,
            'bedNumber': assignedBed,
            'hostelBlock': currentRoom.hostelBlock,
          });

          currentRoom.occupantStudentIds.add(student.id);
          final roomRef = _db.collection('rooms').doc(currentRoom.id);
          
          String newStatus = currentRoom.occupantStudentIds.length >= currentRoom.capacity ? 'Full' : 'Available';
          batch.update(roomRef, {
            'occupantStudentIds': currentRoom.occupantStudentIds,
            'status': newStatus,
          });

          allocatedCount++;

          if (currentRoom.occupantStudentIds.length >= currentRoom.capacity) {
            roomIndex++;
          }
        }
        await batch.commit();
      }
    } catch(e) {
      debugPrint("Allocation Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return allocatedCount;
  }
}
