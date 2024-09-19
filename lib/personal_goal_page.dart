import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PersonalGoalsPage extends StatefulWidget {
  const PersonalGoalsPage({super.key});

  @override
  _PersonalGoalsPageState createState() => _PersonalGoalsPageState();
}

class _PersonalGoalsPageState extends State<PersonalGoalsPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalTitleController = TextEditingController();
  final _taskController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  DateTime? _selectedDate;
  List<String> _tasks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Goals'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalForm(),
              const SizedBox(height: 20),
              Text('Your Goals', style: Theme.of(context).textTheme.titleLarge),
              _buildGoalsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _goalTitleController,
            decoration: const InputDecoration(labelText: 'Goal Title'),
            validator: (value) => value!.isEmpty ? 'Please enter a goal title' : null,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Expected Completion Date'),
              child: Text(_selectedDate == null ? 'Select a date' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _taskController,
                  decoration: const InputDecoration(labelText: 'Add a task'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTask,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(children: _buildTaskList()),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitGoal,
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskList() {
    return _tasks.map((task) => ListTile(
      title: Text(task),
      trailing: IconButton(
        icon: const Icon(Icons.remove),
        onPressed: () => _removeTask(task),
      ),
    )).toList();
  }

  Widget _buildGoalsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('personal_goals')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final goals = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(goal['title']),
                subtitle: Text('Expected: ${goal['expectedDate']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showGoalDetails(goal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteGoal(goals[index].id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showGoalDetails(Map<String, dynamic> goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(goal['title']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Expected completion: ${goal['expectedDate']}'),
                const SizedBox(height: 10),
                Text('Tasks:', style: Theme.of(context).textTheme.titleMedium),
                ...((goal['tasks'] as List<dynamic>?) ?? []).map((task) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text('• $task'),
                  )
                ).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(_taskController.text);
        _taskController.clear();
      });
    }
  }

  void _removeTask(String task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitGoal() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        await _firestore.collection('personal_goals').add({
          'userId': _auth.currentUser!.uid,
          'title': _goalTitleController.text,
          'expectedDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'tasks': _tasks,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _goalTitleController.clear();
        _taskController.clear();
        setState(() {
          _selectedDate = null;
          _tasks = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add goal: $e')),
        );
      }
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    try {
      await _firestore.collection('personal_goals').doc(goalId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete goal: $e')),
      );
    }
  }

  @override
  void dispose() {
    _goalTitleController.dispose();
    _taskController.dispose();
    super.dispose();
  }
}