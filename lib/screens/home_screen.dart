import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:evBookingOperators/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  User? _user;
  List<Map<String, dynamic>> _requests = [];
  final List<Map<String, dynamic>> _approvedLogs = [];
  List<bool> _approvedStatus = [];
  int _approvalCount = 0;
  int _cancellationCount = 0;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchRequestsFromFirestore();
  }

  Future<void> _fetchRequestsFromFirestore() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _requests = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'docId': doc.id,
            'createdAt': data['createdAt'],
            'currentLocation': data['currentLocation'],
            'designation': data['designation'],
            'destination': data['destination'],
            'luggage': data['luggage'],
            'purpose': data['purpose'],
            'status': data['status'],
            'uEmail': data['uEmail'],
            'uId': data['uId'],
            'uName': data['uName'],
          };
        }).toList();

        _approvedStatus = List<bool>.filled(_requests.length,
            false); // Initialize approval status for the requests
      });
    } catch (e) {
      print('Error fetching requests: $e');
      // Handle errors, like showing an error message or retrying
    }
  }

  Future<void> signUserOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showDetailsDialog(int index) {
    Map<String, dynamic> request = _requests[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('E-Vehicle Request Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Name: ${request['uName']}'),
                Text('Email: ${request['uEmail']}'),
                Text('Designation: ${request['designation']}'),
                Text('Current Location: ${request['currentLocation']}'),
                Text('Destination: ${request['destination']}'),
                Text('Luggage: ${request['luggage']}'),
                Text('Purpose: ${request['purpose']}'),
                Text('Status: ${request['status']}'),
                Text('Created At: ${request['createdAt'].toDate()}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Approve'),
              onPressed: () async {
                try {
                  // Update Firestore document status to 'approved'
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(request['docId'])
                      .update({'status': 'approved'});

                  setState(() {
                    _approvedLogs.insert(0, request);
                    _approvalCount++;
                    _approvedStatus[index] = true; // Mark as approved
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error updating status: $e');
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  _cancellationCount++;
                  _approvedStatus[index] = true; // Mark as unapproved
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEvLogs() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ev Recent Logs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Approvals: $_approvalCount'),
              Text('Total Cancellations: $_cancellationCount'),
              const SizedBox(height: 10),
              ..._approvedLogs.take(2).map((log) {
                return ListTile(
                  title: Text('Approved: ${log['uEmail']}'),
                  subtitle: Text(
                      'From: ${log['currentLocation']} To: ${log['destination']}'),
                );
              }),
              if (_approvedLogs.length >
                  2) // Show a message if there are more than two
                Text('And ${_approvedLogs.length - 2} more...'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Colors.deepPurple, Colors.purple]),
              ),
              accountName: Text(_user?.displayName ?? ''),
              accountEmail: Text(_user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : null,
                child: _user?.photoURL == null
                    ? Text(
                        _user?.displayName?.substring(0, 1) ?? 'G',
                        style: const TextStyle(fontSize: 40.0),
                      )
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Recent Approval'),
              onTap: () {
                Navigator.pop(context);
                _showEvLogs();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                signUserOut();
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: <Widget>[
            // Top bar with rounded corners
            Container(
              margin: const EdgeInsets.all(16.0), // Margin around the bar
              padding: const EdgeInsets.all(16.0), // Padding inside the bar
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4), // Shadow position
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'REQUEST APPROVE',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  if (_approvedStatus[index]) {
                    return const SizedBox.shrink(); // Skip approved requests
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          // Use Expanded here
                          child: Text(
                            '${index + 1}. Request from: ${_requests[index]['uName']}',
                            style: const TextStyle(fontSize: 18.0),
                            overflow: TextOverflow.ellipsis, // Prevent overflow
                            maxLines: 1, // Limit to one line
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_sharp),
                          onPressed: () => _showDetailsDialog(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchRequestsFromFirestore,
        backgroundColor: Colors.deepPurple,
        // Call the fetch method to reload data
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
