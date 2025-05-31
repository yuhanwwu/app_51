import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class TaskInputScreen extends StatefulWidget {
  final User curUser;

  const TaskInputScreen({Key? key, required this.curUser}) : super(key: key);

  @override
  State<TaskInputScreen> createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();

  bool _isOneOff = true;
  bool _priority = false;
  
  // Future<String> getUserFlat(String userId) async {
  //   final userDoc = await FirebaseFirestore.instance
  //       .collection("Users")
  //       .doc(userId)
  //       .get();
  //   return userDoc.get('flat');

  // }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    // final assignedFlat = getUserFlat(widget.curUser);
    final assignedFlat = widget.curUser.flat;
    

    final taskData = {
      'description': description,
      'isOneOff': _isOneOff,
      'assignedFlat': assignedFlat,
      'assignedTo': null, //_isOneOff ? null : 'TO_BE_FILLED_IF_NEEDED',
      'done': _isOneOff ? false : null,
      'setDate': _isOneOff
          ? DateFormat('yyyy-MM-dd').format(DateTime.now())
          : null,
      'priority': _isOneOff ? _priority : false,
      'frequency': _isOneOff
          ? 0
          : int.tryParse(_frequencyController.text.trim()) ?? 1,
      'lastDoneOn': _isOneOff ? null : null,
      'lastDoneBy': _isOneOff ? null : null,
    };

    await FirebaseFirestore.instance.collection('tasks').add(taskData);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isOneOff = !_isOneOff;
                    });
                  },
                  child: Text(
                    _isOneOff
                        ? 'Switch to Repeat Task'
                        : 'Switch to One-Off Task',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Text(
                _isOneOff ? 'One-Off Task' : 'Repeat Task',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_isOneOff)
                SwitchListTile(
                  title: const Text('Mark as Priority'),
                  value: _priority,
                  onChanged: (val) {
                    setState(() {
                      _priority = val;
                    });
                  },
                ),
              if (!_isOneOff)
                TextFormField(
                  controller: _frequencyController,
                  decoration: const InputDecoration(
                      labelText: 'Frequency (in days)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter frequency';
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
                onPressed: _submitTask,
                child: const Text('Add Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
