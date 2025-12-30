import 'package:classroom_booking/permission_letter_page.dart';
import 'package:flutter/material.dart';
import 'package:classroom_booking/widgets/draggable_time_range.dart';
import 'booking_details_page.dart';
import 'models.dart';
import 'firestore_service.dart';

/* -------------------- THEME COLORS -------------------- */
const Color primaryOrange = Color(0xFFE2852E);
const Color softYellow = Color(0xFFF5C857);
const Color paleYellow = Color(0xFFFFEE91);

/* -------------------- DEPARTMENT VIEW -------------------- */
class DepartmentView extends StatefulWidget {
  final String deptId;

  const DepartmentView({super.key, required this.deptId});

  @override
  State<DepartmentView> createState() => _DepartmentViewState();
}

class _DepartmentViewState extends State<DepartmentView> {
  final FirestoreService _firestore = FirestoreService();
  Department? department;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final depts = await _firestore.getDepartments();
      final dept = depts.firstWhere((d) => d.id == widget.deptId);
      setState(() {
        department = dept;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "EduBook",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "${department?.name ?? 'Department'}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        backgroundColor: primaryOrange,
        elevation: 4,
        shadowColor: primaryOrange.withOpacity(0.5),
      ),
      body: department != null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [FloorSection(dept: department!)],
            )
          : const Center(child: Text("Department not found")),
    );
  }
}

/* -------------------- FLOOR SECTION -------------------- */
class FloorSection extends StatefulWidget {
  final Department dept;

  const FloorSection({super.key, required this.dept});

  @override
  State<FloorSection> createState() => _FloorSectionState();
}

class _FloorSectionState extends State<FloorSection> {
  final FirestoreService _firestore = FirestoreService();
  List<Room> rooms = [];
  bool isLoading = true;
  Room? selectedRoom;
  RangeValues selectedRange = const RangeValues(0, 4);
  String selectedType = 'Class';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final fetchedRooms = await _firestore.getRoomsForDepartment(
        widget.dept.id,
      );
      List<Room> roomsWithSlots = [];
      for (var room in fetchedRooms) {
        print(room.name);
        final dbSlots = await _firestore.getSlotsForRoom(room.id);
        final slots = _firestore.generateSlotsForRoom(room.id, dbSlots);
        roomsWithSlots.add(
          Room(
            id: room.id,
            name: room.name,
            bookable: room.bookable,
            deptId: room.deptId,
            floor: room.floor,
            slots: slots,
          ),
        );
      }
      setState(() {
        rooms = roomsWithSlots;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showBookingDialog(BuildContext context, Room room) {
    if (room.slots.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No slots'),
          content: const Text('No time slots available for this room.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    int startIndex = selectedRange.start.toInt();
    int endIndex = selectedRange.end.toInt();
    if (startIndex < 0) startIndex = 0;
    if (endIndex >= room.slots.length) endIndex = room.slots.length - 1;
    if (endIndex < startIndex) endIndex = startIndex;

    TimeOfDay startTime = room.slots[startIndex].startTime;
    TimeOfDay endTime = room.slots[endIndex].endTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Confirm Booking",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryOrange,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Room: ${room.name}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Time: ${_formatTime(startTime)} - ${_formatTime(endTime)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Purpose:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<String>(
                    title: const Text('Conducting Class'),
                    value: 'Class',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Event/Club'),
                    value: 'Event',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Add booking to DB with overlap check
                    final user = await _firestore.getCurrentUser();
                    if (user == null) return;
                    try {
                      await _firestore.addBooking(
                        user.id,
                        room.id,
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          startTime.hour,
                          startTime.minute,
                        ),
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          endTime.hour,
                          endTime.minute,
                        ),
                        selectedType,
                      );

                      Navigator.of(context).pop(); // pop after success

                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BookingDetailsPage(
                            room: room,
                            startTime: startTime,
                            endTime: endTime,
                            type: selectedType,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PermissionLetterPage(),
                          ),
                        );
                      }
                    } catch (e) {
                      // Show error (e.g., overlapping booking)
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text(
                            'Booking failed-Overlapping time slots',
                          ),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                  ),
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String suffix = hour >= 12 ? "PM" : "AM";
    hour = hour > 12 ? hour - 12 : hour;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Group rooms by floor
    Map<int, List<Room>> roomsByFloor = {};
    for (var room in rooms) {
      roomsByFloor.putIfAbsent(room.floor, () => []).add(room);
    }

    return Column(
      children: roomsByFloor.entries.map((entry) {
        int floor = entry.key;
        List<Room> floorRooms = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: primaryOrange.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, paleYellow.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.dept.name} - Floor $floor",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                      fontFamily: 'Roboto',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedRoom != null && selectedRoom!.floor == floor) ...[
                    Text(
                      selectedRoom!.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SlotStatusBar(slots: selectedRoom!.slots),
                    if (selectedRoom!.bookable) ...[
                      const SizedBox(height: 12),
                      DraggableTimeRange(
                        slots: selectedRoom!.slots,
                        showStatusBar: false,
                        onRangeChanged: (values) =>
                            setState(() => selectedRange = values),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            _showBookingDialog(context, selectedRoom!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                        ),
                        child: const Text('Book Now'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() => selectedRoom = null),
                      child: const Text('Back'),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: floorRooms
                          .map(
                            (r) => RoomTile(
                              room: r,
                              onTap: () => setState(() => selectedRoom = r),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/* -------------------- ROOM MODEL -------------------- */
class Room {
  final String id;
  final String name;
  final bool bookable;
  final String deptId;
  final int floor;
  final List<Slot> slots;

  const Room({
    required this.id,
    required this.name,
    required this.bookable,
    required this.deptId,
    required this.floor,
    required this.slots,
  });
}

/* -------------------- ROOM TILE -------------------- */
class RoomTile extends StatefulWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomTile({super.key, required this.room, this.onTap});

  @override
  State<RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<RoomTile> {
  final FirestoreService _firestore = FirestoreService();
  bool isHovering = false;
  RangeValues selectedRange = const RangeValues(0, 4);
  String selectedType = 'Class';

  void _showBookingDialog(BuildContext context) {
    if (widget.room.slots.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No slots'),
          content: const Text('No time slots available for this room.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    int startIndex = selectedRange.start.toInt();
    int endIndex = selectedRange.end.toInt();
    if (startIndex < 0) startIndex = 0;
    if (endIndex >= widget.room.slots.length)
      endIndex = widget.room.slots.length - 1;
    if (endIndex < startIndex) endIndex = startIndex;

    TimeOfDay startTime = widget.room.slots[startIndex].startTime;
    TimeOfDay endTime = widget.room.slots[endIndex].endTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Confirm Booking",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryOrange,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Room: ${widget.room.name}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Time: ${_formatTime(startTime)} - ${_formatTime(endTime)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Purpose:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  RadioListTile<String>(
                    title: const Text('Conducting Class'),
                    value: 'Class',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Event/Club'),
                    value: 'Event',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Add booking to DB with overlap check
                    final user = await _firestore.getCurrentUser();
                    if (user == null) return;
                    try {
                      await _firestore.addBooking(
                        user.id,
                        widget.room.id,
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          startTime.hour,
                          startTime.minute,
                        ),
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          endTime.hour,
                          endTime.minute,
                        ),
                        selectedType,
                      );

                      Navigator.of(context).pop(); // pop after success

                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BookingDetailsPage(
                            room: widget.room,
                            startTime: startTime,
                            endTime: endTime,
                            type: selectedType,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PermissionLetterPage(),
                          ),
                        );
                      }
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Booking failed'),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                  ),
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String suffix = hour >= 12 ? "PM" : "AM";
    hour = hour > 12 ? hour - 12 : hour;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isHovering
                  ? [paleYellow, softYellow.withOpacity(0.8)]
                  : [paleYellow, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: primaryOrange.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              if (isHovering)
                BoxShadow(
                  color: primaryOrange.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room name
              Text(
                widget.room.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryOrange,
                  fontFamily: 'Roboto',
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Availability bar
              AvailabilityBar(
                freeRatio:
                    widget.room.slots
                        .where((s) => s.status == SlotStatus.available)
                        .length /
                    widget.room.slots.length,
              ),

              const SizedBox(height: 8),

              // Availability or status
              if (widget.room.bookable && isHovering)
                DraggableTimeRange(
                  slots: widget.room.slots,
                  showStatusBar: false,
                  onRangeChanged: (values) {
                    setState(() => selectedRange = values);
                  },
                )
              else if (!widget.room.bookable)
                const Text("Not Bookable", style: TextStyle(color: Colors.grey))
              else
                const Text(
                  "Bookable, click to book",
                  style: TextStyle(color: Colors.green),
                ),

              const SizedBox(height: 12),

              // BOOK NOW (only on hover & bookable)
              if (isHovering && widget.room.bookable)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _showBookingDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Book Now",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------- AVAILABILITY BAR -------------------- */
class AvailabilityBar extends StatelessWidget {
  final double freeRatio;

  const AvailabilityBar({super.key, required this.freeRatio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("8:30 AM – 6:00 PM", style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: freeRatio,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation(softYellow),
          ),
        ),
      ],
    );
  }
}
