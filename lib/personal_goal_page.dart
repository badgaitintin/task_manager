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
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Personal Goals',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
              background: Container(
                color: Colors.white,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _goalTitleController,
                          decoration: InputDecoration(
                            labelText: 'Enter a new personal goal title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a goal title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Expected completion date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select a date'
                                  : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            labelText: 'Add a task',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _addTask,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildTaskList(),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitGoal,
                          child: const Text('Add Goal'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('personal_goal')
                .doc(_auth.currentUser!.uid)
                .collection('goals')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final goals = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final goal = goals[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ExpansionTile(
                          title: Text(goal['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Expected: ${goal['expectedDate']}'),
                          children: [
                            ...(goal['tasks'] as List<dynamic>).map((task) => 
                              ListTile(
                                title: Text(task),
                                leading: Icon(Icons.check_box_outline_blank),
                              )
                            ),
                            ButtonBar(
                              alignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  child: Text('Delete Goal'),
                                  onPressed: () => _deleteGoal(goals[index].id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: goals.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskList() {
    return _tasks.map((task) => 
      ListTile(
        title: Text(task),
        trailing: IconButton(
          icon: Icon(Icons.remove_circle_outline),
          onPressed: () => _removeTask(task),
        ),
      )
    ).toList();
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
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('personal_goal')
            .doc(user.uid)
            .collection('goals')
            .add({
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
          const SnackBar(content: Text('Personal goal added successfully')),
        );
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expected completion date')),
      );
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('personal_goal')
          .doc(user.uid)
          .collection('goals')
          .doc(goalId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal deleted')),
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