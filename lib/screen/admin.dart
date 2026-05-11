import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final String currentRoute = "adminHome";

  void _navigateAndCloseDrawer(String routeName) {
    Navigator.of(context).pop();
    Navigator.pushNamed(context, routeName);
  }

  Widget _buildDashboardCard(
      String title, int count, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, "loginScreen");
  }

  // ================= عدد المستشفيات =================
  Future<int> getHospitalsCount() async {
    final bloodTypes = [
      'A+',
      'A-',
      'AB+',
      'AB-',
      'B+',
      'B-',
      'O+',
      'O-'
    ];

    Set<String> uniqueHospitals = {};

    for (String bloodType in bloodTypes) {
      final doc = await FirebaseFirestore.instance
          .collection('blood_inventory')
          .doc(bloodType)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        if (data.containsKey('hospitals')) {
          Map<String, dynamic> hospitals = data['hospitals'];

          uniqueHospitals.addAll(hospitals.keys);
        }
      }
    }

    return uniqueHospitals.length;
  }

  // ================= عدد المستخدمين =================
  Future<int> getUsersCount() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    return snapshot.docs.length;
  }

  // ================= الأكياس المتاحة =================
  Future<int> getAvailableBags() async {
    final bloodTypes = [
      'A+',
      'A-',
      'AB+',
      'AB-',
      'B+',
      'B-',
      'O+',
      'O-'
    ];

    int totalAvailable = 0;

    for (String bloodType in bloodTypes) {
      final doc = await FirebaseFirestore.instance
          .collection('blood_inventory')
          .doc(bloodType)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        if (data.containsKey('hospitals')) {
          Map<String, dynamic> hospitals = data['hospitals'];

          hospitals.forEach((hospital, count) {
            if (count is int && count > 0) {
              totalAvailable += count;
            }
          });
        }
      }
    }

    return totalAvailable;
  }

  // ================= الأكياس المحجوزة =================
  Future<int> getReservedBags() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    int totalQuantity = 0;

    for (var doc in snapshot.docs) {
      final quantityDynamic = doc['quantity'];

      int quantity = 0;

      if (quantityDynamic is int) {
        quantity = quantityDynamic;
      } else if (quantityDynamic is String) {
        quantity = int.tryParse(quantityDynamic) ?? 0;
      } else if (quantityDynamic is double) {
        quantity = quantityDynamic.toInt();
      }

      totalQuantity += quantity;
    }

    return totalQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Home"),
        backgroundColor: const Color(0xFF00A7B3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري تحديث البيانات...'),
                ),
              );
            },
          ),
        ],
      ),

      // ================= Drawer =================
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF00A7B3),
              ),
              accountName: Text("Admin"),
              accountEmail: Text("admin@lifelink.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF00A7B3),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Admin Home"),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Blood Inventory"),
              onTap: () =>
                  _navigateAndCloseDrawer("bloodInventoryAdmin"),
            ),

            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Users"),
              onTap: () => _navigateAndCloseDrawer("usersAdmin"),
            ),

            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Reports"),
              onTap: () => _navigateAndCloseDrawer("reportsAdmin"),
            ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<int>>(
            future: Future.wait([
              getUsersCount(),
              getHospitalsCount(),
              getAvailableBags(),
              getReservedBags(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                  ),
                );
              }

              final usersCount = snapshot.data?[0] ?? 0;
              final hospitalsCount = snapshot.data?[1] ?? 0;
              final availableBags = snapshot.data?[2] ?? 0;
              final reservedBags = snapshot.data?[3] ?? 0;

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: .9,
                children: [
                  _buildDashboardCard(
                    "Users",
                    usersCount,
                    Icons.people,
                    Colors.orange,
                  ),

                  _buildDashboardCard(
                    "Hospitals",
                    hospitalsCount,
                    Icons.local_hospital,
                    Colors.red,
                  ),

                  _buildDashboardCard(
                    "Available",
                    availableBags,
                    Icons.inventory,
                    Colors.blue,
                  ),

                  _buildDashboardCard(
                    "Reserved",
                    reservedBags,
                    Icons.pending_actions,
                    Colors.green,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
