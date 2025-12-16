
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Stream<List<String>> streamUserHubs() {
    final User? user = _auth.currentUser;
    if (user == null) {

      return Stream.value([]);
    }


    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {

      if (snapshot.exists && snapshot.data() != null) {


        var data = snapshot.data()!;
        var hubIdsDynamic = data['hubIds'];
        
        if (hubIdsDynamic is List) {

          return List<String>.from(hubIdsDynamic);
        }
      }

      return [];
    });
  }


   Future<List<String>> getAllUserHubs() async {
    final User? user = _auth.currentUser;
    if (user == null) return [];

    try {

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



      await _firestore.collection('users').doc(user.uid).set({
        'hubIds': FieldValue.arrayUnion([newHubRef.id])
      }, SetOptions(merge: true));
      
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
