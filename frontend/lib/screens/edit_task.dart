import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/task.dart';

class EditTaskPage extends StatefulWidget {
  final FlatUser curUser;
  final VoidCallback onTaskSubmitted;
  final Task task;

  const EditTaskPage({
    super.key,
    required this.curUser,
    required this.onTaskSubmitted,
    required this.task,
  });

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _frequencyController;

  bool _isOneOff = true;
  late bool _priority;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _frequencyController = TextEditingController(
      text: widget.task.frequency.toString(),
    );
    _priority = widget.task.priority;
  }

  Future<void> _editTask() async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final frequency = int.tryParse(_frequencyController.text.trim());
    // final assignedFlat = getUserFlat(widget.curUser);
    // final assignedFlat = widget.curUser.flat;
    final _task = widget.task;

    final taskData = {
      'description': description,
      'isOneOff': _task.isOneOff,
      'assignedFlat': _task.assignedFlat,
      'assignedTo': _task.assignedTo,
      'done': _task.done,
      'setDate': _task.setDate,
      'priority': _priority,
      'frequency': frequency,
      'lastDoneOn': _task.lastDoneOn,
      'lastDoneBy': _task.lastDoneBy,
      'isPersonal': _task.isPersonal,
    };

    await _task.taskRef.set(taskData);
    // print('Task successfully added!');

    widget.onTaskSubmitted();
    Navigator.pop(context);
  }

  Widget buildOneOffEditor(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                _isOneOff ? 'One-Off Task' : 'Repeat Task',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please change description'
                    : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Mark as Priority'),
                value: _priority,
                onChanged: (val) {
                  setState(() {
                    _priority = val;
                  });
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _editTask,
                child: const Text('Edit Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRepeatEditor(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                _isOneOff ? 'One-Off Task' : 'Repeat Task',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please change description'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency (in days)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please change frequency';
                  }
                  final freq = int.tryParse(value);
                  if (freq == null || freq <= 0) {
                    return 'Enter a valid number > 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _editTask,
                child: const Text('Edit Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task.isOneOff) {
      return buildOneOffEditor(context);
    } else {
      return buildRepeatEditor(context);
    }
  }
}
