import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum Priority { low, medium, high }

class Task {
  String id;
  String name;
  bool isDone;
  Priority priority;
  String category;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.name,
    this.isDone = false,
    this.priority = Priority.medium,
    this.category = 'Academic',
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isDone': isDone,
    'priority': priority.index,
    'category': category,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    name: json['name'],
    isDone: json['isDone'],
    priority: Priority.values[json['priority']],
    category: json['category'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
  );
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  String _filter = 'All';
  final _categories = ['All', 'Academic', 'Personal', 'Project', 'Reminder'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks_v2');
    if (data != null) {
      setState(() {
        _tasks = (json.decode(data) as List).map((e) => Task.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('tasks_v2', json.encode(_tasks.map((t) => t.toJson()).toList()));
  }

  List<Task> get _filteredTasks {
    if (_filter == 'All') return _tasks;
    return _tasks.where((t) => t.category == _filter).toList();
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high: return Colors.red;
      case Priority.medium: return Colors.orange;
      case Priority.low: return Colors.green;
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.high: return 'High';
      case Priority.medium: return 'Medium';
      case Priority.low: return 'Low';
    }
  }

  void _showAddTaskSheet() {
    final nameCtrl = TextEditingController();
    Priority selectedPriority = Priority.medium;
    String selectedCategory = 'Academic';
    DateTime? selectedDate;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Task name...', labelText: 'Task'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Academic', 'Personal', 'Project', 'Reminder']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSheet(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: Priority.values.map((p) {
                  final selected = selectedPriority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setSheet(() => selectedPriority = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? _priorityColor(p) : _priorityColor(p).withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _priorityColor(p)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _priorityLabel(p),
                            style: TextStyle(
                              color: selected ? Colors.white : _priorityColor(p),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setSheet(() => selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 10),
                      Text(
                        selectedDate == null ? 'Set due date (optional)' : 'Due: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        style: TextStyle(color: selectedDate == null ? Colors.grey : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _tasks.add(Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        priority: selectedPriority,
                        category: selectedCategory,
                        dueDate: selectedDate,
                      ));
                    });
                    _saveTasks();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = _tasks.where((t) => t.isDone).length;
    final total = _tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('$done/$total', style: const TextStyle(color: Colors.white70))),
          )
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          if (total > 0)
            LinearProgressIndicator(
              value: done / total,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF6C63FF),
              minHeight: 4,
            ),
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _filter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: const Color(0xFF6C63FF),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                    onSelected: (_) => setState(() => _filter = cat),
                  ),
                );
              },
            ),
          ),
          // Task list
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No tasks here!\nTap + to add one',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (_, i) {
                      final task = _filteredTasks[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: GestureDetector(
                            onTap: () {
                              setState(() => task.isDone = !task.isDone);
                              _saveTasks();
                            },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: task.isDone ? const Color(0xFF6C63FF) : Colors.transparent,
                                border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                              ),
                              child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          ),
                          title: Text(
                            task.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                              color: task.isDone ? Colors.grey : Colors.black87,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _priorityColor(task.priority).withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _priorityLabel(task.priority),
                                  style: TextStyle(color: _priorityColor(task.priority), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(task.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (task.dueDate != null) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.calendar_today, size: 11, color: Colors.grey[500]),
                                Text(' ${task.dueDate!.day}/${task.dueDate!.month}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _tasks.remove(task));
                              _saveTasks();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
