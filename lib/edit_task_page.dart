import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditTaskPage extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> task;
  final Function onTaskUpdated;

  const EditTaskPage({
    super.key,
    required this.taskId,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _priority;
  late bool _isRepeating;
  late String _repeatFrequency;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task['title']);
    _descriptionController = TextEditingController(text: widget.task['description']);
    _locationController = TextEditingController(text: widget.task['location']);
    _selectedDate = (widget.task['date'] as Timestamp).toDate();
    final timeParts = (widget.task['time'] as String).split(':');
    _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    _priority = widget.task['priority'];
    _isRepeating = widget.task['isRepeating'];
    _repeatFrequency = widget.task['repeatFrequency'] ?? 'Daily';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

Future<void> _updateTask() async {
  if (_formKey.currentState!.validate()) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final updatedTask = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'location': _locationController.text,
          'date': Timestamp.fromDate(_selectedDate),
          'time': '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          'priority': _priority,
          'isRepeating': _isRepeating,
          'repeatFrequency': _isRepeating ? _repeatFrequency : null,
          'userId': user.uid,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tasks')
            .doc(widget.taskId)
            .update(updatedTask);

        widget.onTaskUpdated();
        // ไม่ต้อง pop ที่นี่เพราะเราจะ pop ใน onTaskUpdated callback
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
    } catch (e) {
      print('Error updating task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Task',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildTextField(_titleController, 'Title', 'Enter task title'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description', 'Enter task description', maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(_locationController, 'Location', 'Enter location'),
              const SizedBox(height: 16),
              _buildDateTimePicker(),
              const SizedBox(height: 16),
              _buildPriorityDropdown(),
              const SizedBox(height: 16),
              _buildRepeatingSwitch(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateTask,
                child: const Text('Update Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(_selectedTime.format(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: _priority,
      decoration: InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      items: ['Low', 'Medium', 'High'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _priority = newValue!;
        });
      },
    );
  }

  Widget _buildRepeatingSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Repeat'),
        Switch(
          value: _isRepeating,
          onChanged: (value) {
            setState(() {
              _isRepeating = value;
            });
          },
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
}