import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class TaskInputScreen extends StatefulWidget {
  final FlatUser curUser;
  final DocumentReference userRef;
  final VoidCallback onTaskSubmitted;

  const TaskInputScreen({
    super.key,
    required this.curUser,
    required this.userRef,
    required this.onTaskSubmitted,
  });

  @override
  State<TaskInputScreen> createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();

  bool _isOneOff = true;
  bool _priority = false;
  bool _isPersonal = true;
  bool _claimTask = false;

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
      'assignedTo': _isOneOff
          ? (_claimTask ? widget.userRef : null)
          : widget.userRef,
      // null : widget.userRef,
      'done': _isOneOff ? false : null,
      'setDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'priority': _isOneOff ? _priority : false,
      'frequency': _isOneOff
          ? 0
          : int.tryParse(_frequencyController.text.trim()) ?? 1,
      'lastDoneOn': _isOneOff ? null : null,
      'lastDoneBy': _isOneOff ? null : null,
      'isPersonal': _isOneOff ? false : _isPersonal,
    };

    await FirebaseFirestore.instance.collection('Tasks').add(taskData);
    // print('Task successfully added!');

    widget.onTaskSubmitted();
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
              if (_isOneOff)
                SwitchListTile(
                  title: const Text('Claim this task'),
                  value: _claimTask,
                  onChanged: (val) {
                    setState(() {
                      _claimTask = val;
                    });
                  },
                ),
              if (!_isOneOff)
                TextFormField(
                  controller: _frequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Frequency (in days)',
                  ),
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
                const SizedBox(height: 16),
              if (!_isOneOff)
                Container(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // horizontal centering
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // vertical centering
                    children: [
                      Expanded(flex: 1, child: Text("Flat Task", textAlign: TextAlign.right)),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Transform.scale(
                            scale: 1,
                            child: Switch(
                              value: _isPersonal,
                              onChanged: (val) {
                                setState(() {
                                  _isPersonal = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(flex: 1, child: Text("Personal Task", textAlign: TextAlign.left),),
                    ],
                  ),
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
