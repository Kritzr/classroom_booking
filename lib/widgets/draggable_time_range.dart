import 'package:flutter/material.dart';
import '../models.dart';

class SlotStatusBar extends StatelessWidget {
  final List<Slot> slots;

  const SlotStatusBar({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    var groups = _groupSlots(slots);
    bool isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 60),
        child: ListView(
          shrinkWrap: true,
          children: groups.map((group) {
            int totalDuration = group.fold(
              0,
              (sum, slot) => sum + slot.durationInMinutes,
            );
            SlotStatus status = group.first.status;
            Color color = _statusColor(status);
            String timeText =
                '${_slotToTime(group.first.startTime)}-${_slotToTime(group.last.endTime)}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      timeText,
                      style: TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(child: Container(height: 10, color: color)),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } else {
      return SizedBox(
        height: 30,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: groups.map((group) {
              int totalDuration = group.fold(
                0,
                (sum, slot) => sum + slot.durationInMinutes,
              );
              SlotStatus status = group.first.status;
              Color color = _statusColor(status);
              String timeText =
                  '${_slotToTime(group.first.startTime)}-${_slotToTime(group.last.endTime)}';
              return Container(
                width: totalDuration.toDouble() * 1.5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: color),
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  List<List<Slot>> _groupSlots(List<Slot> slots) {
    List<List<Slot>> groups = [];
    if (slots.isEmpty) return groups;
    List<Slot> currentGroup = [slots[0]];
    for (int i = 1; i < slots.length; i++) {
      if (slots[i].status == currentGroup.last.status) {
        currentGroup.add(slots[i]);
      } else {
        groups.add(currentGroup);
        currentGroup = [slots[i]];
      }
    }
    groups.add(currentGroup);
    return groups;
  }

  Color _statusColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return Colors.green;
      case SlotStatus.booked:
        return Colors.red;
      case SlotStatus.reserved:
        return Colors.grey;
    }
  }

  String _slotToTime(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String suffix = hour >= 12 ? "PM" : "AM";
    hour = hour > 12 ? hour - 12 : hour;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
  }
}

class DraggableTimeRange extends StatefulWidget {
  final List<Slot> slots;
  final bool showStatusBar;
  final ValueChanged<RangeValues>? onRangeChanged;

  const DraggableTimeRange({
    super.key,
    required this.slots,
    this.showStatusBar = true,
    this.onRangeChanged,
  });

  @override
  State<DraggableTimeRange> createState() => _DraggableTimeRangeState();
}

class _DraggableTimeRangeState extends State<DraggableTimeRange> {
  double start = 0; // default start slot index
  double end = 4; // default end slot index

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showStatusBar) ...[
          const Text(
            "Select Time",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          // 🔴🟢⚪ STATUS BAR with labels
          Builder(
            builder: (context) {
              bool isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 60),
                  child: ListView(
                    shrinkWrap: true,
                    children: widget.slots.map((slot) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _slotToTime(slot.startTime),
                                    style: TextStyle(fontSize: 8),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    _slotToTime(slot.endTime),
                                    style: TextStyle(fontSize: 8),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 10,
                                color: _statusColor(slot.status),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              } else {
                return SizedBox(
                  height: 50,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.slots.map((slot) {
                        return Container(
                          width:
                              slot.durationInMinutes.toDouble() *
                              1.5, // Scale width by duration for proportionality
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 25,
                                color: _statusColor(slot.status),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_slotToTime(slot.startTime)}\n${_slotToTime(slot.endTime)}',
                                style: const TextStyle(
                                  fontSize: 7,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
            },
          ),
        ],

        // 🎯 RANGE SLIDER
        RangeSlider(
          min: 0,
          max: widget.slots.length.toDouble() - 1,
          divisions: widget.slots.length - 1,
          values: RangeValues(start, end),
          labels: RangeLabels(
            _slotToTime(widget.slots[start.toInt()].startTime),
            _slotToTime(widget.slots[end.toInt()].endTime),
          ),
          onChanged: (values) {
            setState(() {
              start = values.start.roundToDouble();
              end = values.end.roundToDouble();
            });
            widget.onRangeChanged?.call(values);
          },
        ),
      ],
    );
  }

  Color _statusColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return Colors.green;
      case SlotStatus.booked:
        return Colors.red;
      case SlotStatus.reserved:
        return Colors.grey;
    }
  }

  String _slotToTime(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String suffix = hour >= 12 ? "PM" : "AM";
    hour = hour > 12 ? hour - 12 : hour;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
  }
}
