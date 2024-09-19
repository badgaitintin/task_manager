import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'edit_task_page.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User? _user;
  DateTime _selectedDate = DateTime.now();

  @override
void initState() {
  super.initState();
  _user = FirebaseAuth.instance.currentUser;
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    setState(() {
      _user = user;
    });
  });
}

  
  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // If user is not logged in, redirect to login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks', style: Theme.of(context).textTheme.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: TaskSearch(userId: _user!.uid));
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildCurrentDateAndUpcomingTasks(),
          _buildCalendar(),
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add New Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCurrentDateAndUpcomingTasks() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today is',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${DateTime.now().day}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold) ?? 
                         const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMMM').format(DateTime.now()).toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildUpcomingTasks(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('date')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No upcoming tasks');
        }
        final tasks = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...tasks.map((task) {
              final taskData = task.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(taskData['title']),
                subtitle: Text(DateFormat('MMM d, y').format((taskData['date'] as Timestamp).toDate())),
                leading: const Icon(Icons.event),
                dense: true,
                visualDensity: VisualDensity.compact,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCurrentDate() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today is',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${DateTime.now().day}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold) ?? 
                       const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('MMMM').format(DateTime.now()).toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          // You can add more widgets here if needed
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return MediaQuery.of(context).size.width < 600
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onDateChanged: (newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
              ),
            ),
          )
        : CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (newDate) {
              setState(() {
                _selectedDate = newDate;
              });
            },
          );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .where('date', isEqualTo: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text('No tasks for this day', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showAddTaskDialog,
                  child: const Text('Add a task'),
                ),
              ],
            ),
          );
        }
        final tasks = snapshot.data!.docs;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            final taskId = tasks[index].id;
            return _buildTaskCard(task, taskId);
          },
        );
      },
    );
  }

void _showAddTaskDialog() {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: AddTaskPage(
            onTaskAdded: (Map<String, dynamic> newTask) async {
              Navigator.of(dialogContext).pop(); // Close the dialog first
              if (_user != null) {
                try {
                  await _firestore
                      .collection('users')
                      .doc(_user!.uid)
                      .collection('tasks')
                      .add(newTask);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task added successfully')),
                    );
                    setState(() {}); // Refresh UI after showing the snackbar
                  }
                } catch (e) {
                  print('Error adding task: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding task: $e')),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                }
              }
            },
          ),
        ),
      );
    },
  );
}

  Widget _buildTaskCard(Map<String, dynamic> task, String taskId) {
    final priorityColors = {
      'Low': Colors.green,
      'Medium': Colors.orange,
      'High': Colors.red,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColors[task['priority']] ?? Colors.grey,
          child: const Icon(Icons.star, color: Colors.white),
        ),
        title: Text(task['title'], style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['description']),
            const SizedBox(height: 4),
            Text(
              'Time: ${task['time']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editTask(taskId, task),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTask(taskId),
            ),
          ],
        ),
        onTap: () {
          // Show task details or expand the card
        },
      ),
    );
  }

 Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_user?.displayName ?? 'User'),
            accountEmail: Text(_user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                (_user?.displayName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 24.0),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Personal Goals'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/personal_goals');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editTask(String taskId, Map<String, dynamic> currentTask) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: EditTaskPage(
            taskId: taskId,
            task: currentTask,
            onTaskUpdated: () {
              Navigator.of(context).pop(); // ปิด dialog
              setState(() {}); // รีเฟรช UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task updated successfully')),
              );
            },
          ),
        ),
      );
    },
  );
}

  Future<void> _deleteTask(String taskId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

     if (confirmDelete == true) {
      try {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('tasks')
            .doc(taskId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting task: $e')),
        );
      }
    }
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
}

class TaskSearch extends SearchDelegate<String> {
  final String userId;

  TaskSearch({required this.userId});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No results found'));
        }
        final tasks = snapshot.data!.docs;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(task['title']),
              subtitle: Text(DateFormat('MMM d, y').format((task['date'] as Timestamp).toDate())),
              onTap: () {
                // You can navigate to task details page here
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(5)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No suggestions'));
        }
        final tasks = snapshot.data!.docs;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(task['title']),
              onTap: () {
                query = task['title'];
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}