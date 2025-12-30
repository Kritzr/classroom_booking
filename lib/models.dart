import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SlotStatus { available, booked, reserved }

class UserModel {
  final String id;
  final String email;
  final String firstname;
  final String lastname;
  final String userType;
  final String username;

  UserModel({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.userType,
    required this.username,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'],
      firstname: data['firstName'],
      lastname: data['lastName'],
      userType: data['userType'],
      username: data['username'],
    );
  }
}

class Department {
  final String id;
  final String name;
  final int floors;

  Department({required this.id, required this.name, required this.floors});

  factory Department.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Department(id: doc.id, name: data['Name'], floors: data['floors']);
  }
}

class Room {
  final String id;
  final bool bookable;
  final String deptId;
  final int floor;
  final String name;
  final List<Slot> slots;

  Room({
    required this.id,
    required this.bookable,
    required this.deptId,
    required this.floor,
    required this.name,
    this.slots = const [],
  });

  factory Room.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      bookable: data['bookable'],
      deptId: (data['deptId'] as DocumentReference).id, // Extract ID from reference
      floor: data['floor'],
      name: data['name'],
    );
  }
}

class SlotModel {
  final String id;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  SlotModel({
    required this.id,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory SlotModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SlotModel(
      id: doc.id,
      roomId: (data['roomId'] as DocumentReference).id, // Extract ID from reference
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: data['status'],
    );
  }
}

class Slot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final SlotStatus status;

  const Slot({
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  int get durationInMinutes {
    return (endTime.hour * 60 + endTime.minute) -
        (startTime.hour * 60 + startTime.minute);
  }
}

class Booking {
  final String id;
  final String userId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final bool approved;

  Booking({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.approved,
  });

  factory Booking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
   
    return Booking(
      id: doc.id,
      userId:
          (data['userId'] as DocumentReference).id, // Extract ID from reference
      roomId: (data['roomId'] as DocumentReference).id, // Extract ID from reference
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      type: data['type'],
      approved: data['approved'],
    );
  }
}
