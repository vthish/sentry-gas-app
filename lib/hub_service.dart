// --- lib/hub_service.dart (SIMPLIFIED - Removed orderBy to fix index issue) ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<String>> streamUserHubs() {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('hubs')
        .where('accessList', arrayContains: user.uid)
        // .orderBy('createdAt', descending: true) // <-- මෙය තාවකාලිකව ඉවත් කළා
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // ... (අනෙක් functions එලෙසම තබන්න: getAllUserHubs, createDemoHubForCurrentUser, linkBluetoothHubToUser) ...
   Future<List<String>> getAllUserHubs() async {
    final User? user = _auth.currentUser;
    if (user == null) return [];
    try {
      QuerySnapshot hubQuery = await _firestore
          .collection('hubs')
          .where('accessList', arrayContains: user.uid)
           // .orderBy('createdAt', descending: true) // <-- මෙයත් ඉවත් කළා
          .get();
      return hubQuery.docs.map((doc) => doc.id).toList();
    } catch (e) { return []; }
  }

  Future<String?> createDemoHubForCurrentUser(String hubName) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    try {
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
      return newHubRef.id;
    } catch (e) {
      print("Error creating demo hub: $e");
      return null;
    }
  }

  Future<String?> linkBluetoothHubToUser(String hubName, String deviceMacId) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    try {
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
      return newHubRef.id;
    } catch (e) { return null; }
  }
}