// --- lib/hub_service.dart (FIXED LOGIC) ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- UPDATED: This function now correctly streams the USER'S hub list ---
  Stream<List<String>> streamUserHubs() {
    final User? user = _auth.currentUser;
    if (user == null) {
      // Return a stream of an empty list if no user is logged in
      return Stream.value([]);
    }

    // Stream the user's document
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      // Check if the document exists and has data
      if (snapshot.exists && snapshot.data() != null) {
        // Get the 'hubIds' field, which is expected to be a List
        // Use 'List.from' to safely cast it
        var data = snapshot.data()!;
        var hubIdsDynamic = data['hubIds'];
        
        if (hubIdsDynamic is List) {
          // Convert the list of dynamic to List<String>
          return List<String>.from(hubIdsDynamic);
        }
      }
      // If doc doesn't exist, or no hubIds field, return empty list
      return [];
    });
  }

  // --- UPDATED: This function now correctly gets the USER'S hub list ---
   Future<List<String>> getAllUserHubs() async {
    final User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Get the user's document
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        var hubIdsDynamic = data['hubIds'];

        if (hubIdsDynamic is List) {
          return List<String>.from(hubIdsDynamic);
        }
      }
      return [];
    } catch (e) {
      print("Error in getAllUserHubs: $e");
      return [];
    }
  }

  // --- UPDATED: Now also adds the new Hub ID to the 'users' document ---
  Future<String?> createDemoHubForCurrentUser(String hubName) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Create the new Hub in 'hubs' collection
      DocumentReference newHubRef = _firestore.collection('hubs').doc();
      await newHubRef.set({
        'hubId': newHubRef.id,
        'ownerId': user.uid,
        'accessList': [user.uid],
        'hubName': hubName,
        'gasLevel': 75.0,
        'valveOn': true,
        'statusMessage': "Everything is OK",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. --- NEW --- Add this Hub's ID to the user's 'hubIds' list
      // Using SetOptions(merge: true) creates the doc if it doesn't exist
      await _firestore.collection('users').doc(user.uid).set({
        'hubIds': FieldValue.arrayUnion([newHubRef.id])
      }, SetOptions(merge: true));
      
      return newHubRef.id;

    } catch (e) {
      print("Error creating demo hub: $e");
      return null;
    }
  }

  // --- UPDATED: Now also adds the new Hub ID to the 'users' document ---
  Future<String?> linkBluetoothHubToUser(String hubName, String deviceMacId) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Create the new Hub in 'hubs' collection
      DocumentReference newHubRef = _firestore.collection('hubs').doc(deviceMacId);
      await newHubRef.set({
        'hubId': newHubRef.id,
        'bluetoothMacId': deviceMacId,
        'ownerId': user.uid,
        'accessList': [user.uid],
        'hubName': hubName,
        'gasLevel': 100.0,
        'valveOn': true,
        'statusMessage': "New Hub Connected",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. --- NEW --- Add this Hub's ID to the user's 'hubIds' list
      await _firestore.collection('users').doc(user.uid).set({
        'hubIds': FieldValue.arrayUnion([newHubRef.id])
      }, SetOptions(merge: true));

      return newHubRef.id;

    } catch (e) { 
      print("Error linking BT hub: $e");
      return null; 
    }
  }
}