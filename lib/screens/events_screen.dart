import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const List<String> kEventTypes = ['Exam', 'Assignment', 'Event', 'Meeting', 'Reminder'];
const List<Color> kEventColors = [
  Color(0xFFFF6584), Color(0xFF6C63FF), Color(0xFFF7971E),
  Color(0xFF43E97B), Color(0xFFA0A0C0),
];

class Event {
  String id, title, type, location, note;
  DateTime date;
  TimeOfDay? time;

  Event({required this.id, required this.title, required this.type,
    required this.date, this.location = '', this.note = '', this.time});

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'type': type, 'location': location,
    'note': note, 'date': date.toIso8601String(),
    'timeH': time?.hour, 'timeM': time?.minute,
  };

  factory Event.fromJson(Map<String, dynamic> j) => Event(
    id: j['id'], title: j['title'], type: j['type'],
    location: j['location'] ?? '', note: j['note'] ?? '',
    date: DateTime.parse(j['date']),
    time: j['timeH'] != null ? TimeOfDay(hour: j['timeH'], minute: j['timeM']) : null,
  );

  int get daysLeft => date.difference(DateTime.now().subtract(const Duration(hours: 23, minutes: 59))).inDays;

  Color get typeColor {
    final i = kEventTypes.indexOf(type);
    return i >= 0 ? kEventColors[i] : Colors.grey;
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> _events = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('events_v2');
    if (data != null) {
      setState(() => _events = (json.decode(data) as List).map((e) => Event.fromJson(e)).toList());
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('events_v2', json.encode(_events.map((e) => e.toJson()).toList()));
  }

  List<Event> get _filtered {
    List<Event> list = _filter == 'All' ? _events : _events.where((e) => e.type == _filter).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  void _showAddSheet() {
    final titleCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'Exam';
    DateTime? date;
    TimeOfDay? time;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event title')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: kEventTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setSheet(() => type = v!),
                ),
                const SizedBox(height: 12),
                // Date picker
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setSheet(() => date = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6C63FF)),
                        const SizedBox(width: 10),
                        Text(date == null ? 'Select date *' : '${date!.day}/${date!.month}/${date!.year}',
                            style: TextStyle(color: date == null ? Colors.grey : Colors.black87)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Time picker
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    if (t != null) setSheet(() => time = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Color(0xFF6C63FF)),
                        const SizedBox(width: 10),
                        Text(time == null ? 'Select time (optional)' : time!.format(ctx),
                            style: TextStyle(color: time == null ? Colors.grey : Colors.black87)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location (optional)')),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty || date == null) return;
                      setState(() {
                        _events.add(Event(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text.trim(),
                          type: type,
                          date: date!,
                          time: time,
                          location: locCtrl.text.trim(),
                          note: noteCtrl.text.trim(),
                        ));
                      });
                      _save();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(Event e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: e.typeColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e.type, style: TextStyle(color: e.typeColor, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() => _events.remove(e));
                    _save();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(e.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.calendar_today, text: '${e.date.day}/${e.date.month}/${e.date.year}${e.time != null ? ' at ${e.time!.format(context)}' : ''}'),
            if (e.location.isNotEmpty) _DetailRow(icon: Icons.location_on_outlined, text: e.location),
            if (e.note.isNotEmpty) _DetailRow(icon: Icons.notes, text: e.note),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: e.typeColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: e.typeColor.withValues(alpha:0.3)),
              ),
              child: Text(
                e.daysLeft < 0 ? 'Event has passed' : e.daysLeft == 0 ? 'Today!' : '${e.daysLeft} day${e.daysLeft == 1 ? '' : 's'} remaining',
                style: TextStyle(color: e.typeColor, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: ['All', ...kEventTypes].map((t) {
                final selected = _filter == t;
                final color = t == 'All' ? const Color(0xFF6C63FF) : kEventColors[kEventTypes.indexOf(t)];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: selected,
                    selectedColor: t == 'All' ? const Color(0xFF6C63FF) : color,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                    onSelected: (_) => setState(() => _filter = t),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No events yet\nTap + to add one',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final e = _filtered[i];
                      final dl = e.daysLeft;
                      return GestureDetector(
                        onTap: () => _showDetail(e),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: e.typeColor,
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: e.typeColor.withValues(alpha:0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(e.type, style: TextStyle(color: e.typeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${e.date.day}/${e.date.month}/${e.date.year}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          if (e.location.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                                            Text(e.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Column(
                                  children: [
                                    Text(
                                      dl < 0 ? 'Done' : dl == 0 ? 'Today' : '${dl}d',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: dl < 0 ? Colors.grey : dl <= 2 ? Colors.red : dl <= 7 ? Colors.orange : const Color(0xFF43E97B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        ],
      ),
    );
  }
}
