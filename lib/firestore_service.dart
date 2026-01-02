import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Add this method to FirestoreService class
  Future<bool> testConnection() async {
    try {
      // Attempt a lightweight query (e.g., check if 'departments' collection has any docs)
      final snapshot = await _db.collection('Departments').limit(1).get();
      return true; // Connected if no exception
    } catch (e) {
      print('Firestore connection failed: $e');
      return false;
    }
  }

  // Get current user (hardcoded for now)
  Future<UserModel?> getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
    }
    return null;
  }

  // Get all departments
  Future<List<Department>> getDepartments() async {
    final snapshot = await _db.collection('Departments').get();
    return snapshot.docs.map((doc) => Department.fromDocument(doc)).toList();
  }

  // Get rooms for a department
  Future<List<Room>> getRoomsForDepartment(String deptId) async {
    // Try several possible ways deptId may be stored in Firestore (DocumentReference or plain string)
    QuerySnapshot snapshot = await _db
        .collection('rooms')
        .where('deptId', isEqualTo: _db.doc('Departments/$deptId'))
        .get();

    if (snapshot.docs.isEmpty) {
      // try lowercase collection name
      snapshot = await _db
          .collection('rooms')
          .where('deptId', isEqualTo: _db.doc('departments/$deptId'))
          .get();
    }

    if (snapshot.docs.isEmpty) {
      // try plain string id stored in field
      snapshot = await _db
          .collection('rooms')
          .where('deptId', isEqualTo: deptId)
          .get();
    }

    List<Room> rooms = [];
    for (var doc in snapshot.docs) {
      Room room = Room.fromDocument(doc);
      List<SlotModel> slotsDb = await getSlotsForRoom(room.id);
      List<Slot> slots = generateSlotsForRoom(room.id, slotsDb);

      rooms.add(
        Room(
          id: room.id,
          bookable: room.bookable,
          deptId: room.deptId,
          floor: room.floor,
          name: room.name,
          slots: slots,
        ),
      );
    }
    return rooms;
  }

  // Get slots for a room
  Future<List<SlotModel>> getSlotsForRoom(String roomId) async {
    QuerySnapshot snapshot = await _db
        .collection('slots')
        .where('roomId', isEqualTo: _db.doc('rooms/$roomId'))
        .get();

    if (snapshot.docs.isEmpty) {
      // try lowercase collection or plain string
      snapshot = await _db
          .collection('slots')
          .where('roomId', isEqualTo: _db.doc('Rooms/$roomId'))
          .get();
    }

    if (snapshot.docs.isEmpty) {
      snapshot = await _db
          .collection('slots')
          .where('roomId', isEqualTo: roomId)
          .get();
    }

    return snapshot.docs.map((doc) => SlotModel.fromDocument(doc)).toList();
  }

  // Generate full slots list for a room (8:30 AM to 6:00 PM, 30 min intervals)
  List<Slot> generateSlotsForRoom(String roomId, List<SlotModel> dbSlots) {
    List<Slot> slots = [];
    DateTime start = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      8,
      30,
    );
    DateTime end = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      18,
      0,
    );

    while (start.isBefore(end)) {
      DateTime slotEnd = start.add(const Duration(minutes: 30));
      SlotStatus status = SlotStatus.available;

      // Check if in DB slots
      for (var dbSlot in dbSlots) {
        if (dbSlot.startTime == start) {
          if (dbSlot.status == 'booked')
            status = SlotStatus.booked;
          else if (dbSlot.status == 'reserved')
            status = SlotStatus.reserved;
          slotEnd = dbSlot.endTime;
          break;
        }
      }

      slots.add(
        Slot(
          startTime: TimeOfDay.fromDateTime(start),
          endTime: TimeOfDay.fromDateTime(slotEnd),
          status: status,
        ),
      );

      start = slotEnd;
    }

    return slots;
  }

  // Get bookings for a user
  Future<List<Booking>> getBookingsForUser(String userId) async {
    final snapshot = await _db
        .collection('bookings')
        .where(
          'userId',
          isEqualTo: _db.doc('users/$userId'),
        ) // Query by DocumentReference
        .get();
    if(snapshot.docs.isEmpty){
      return [];
    }

    return snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList();
  }

  // Add booking
  Future<void> addBooking(
    String userId,
    String roomId,
    DateTime startTime,
    DateTime endTime,
    String type,
  ) async {
    // Check for overlapping booked slots first
    final existingSlots = await getSlotsForRoom(roomId);
    for (var s in existingSlots) {
      if (s.status == 'booked') {
        // overlap check
        if (s.startTime.isBefore(endTime) && s.endTime.isAfter(startTime)) {
          throw Exception('Selected time overlaps with an existing booking.');
        }
      }
    }

    // Add booking document
    await _db.collection('bookings').add({
      'userId': _db.doc('users/$userId'), // Save as DocumentReference
      'roomId': _db.doc('rooms/$roomId'),
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'approved': false, // Assume pending approval
    });

    // Update slots to booked
    DateTime current = startTime;
    while (current.isBefore(endTime)) {
      DateTime slotEnd = current.add(const Duration(minutes: 30));
      await _db.collection('slots').add({
        'roomId': _db.doc('rooms/$roomId'),
        'startTime': current,
        'endTime': slotEnd,
        'status': 'booked',
      });
      current = slotEnd;
    }
  }
}
