// import 'package:your_app/core/services/firestore_service.dart';

class GroupRepository {
  // final _firestore = FirestoreService.instance;

  // Mock data cho UI test
  final List<Map<String, dynamic>> _mockGroups = [
    {
      "id": "G1",
      "name": "Group 1",
      "course": "IT4409 - Web Programming",
      "members": [
        {"id": "S1", "name": "Nguyen Van A"},
        {"id": "S2", "name": "Tran Thi B"},
      ],
      "teacher": "Dr. Nguyen Van A",
    },
    {
      "id": "G2",
      "name": "Group 2",
      "course": "IT4409 - Web Programming",
      "members": [
        {"id": "S3", "name": "Le Van C"},
        {"id": "S4", "name": "Pham Thi D"},
      ],
      "teacher": "Dr. Nguyen Van A",
    }
  ];

  Future<List<Map<String, dynamic>>> getGroups({bool useMock = true}) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockGroups;
    }

    // 🔥 Real Firebase
    // final docs = await _firestore.getCollection(collectionPath: 'groups');
    // return docs.map((d) => d.data() as Map<String, dynamic>).toList();
    return [];
  }

  Future<void> addGroup(Map<String, dynamic> data, {bool useMock = true}) async {
    if (useMock) {
      _mockGroups.add(data);
      return;
    }

    // 🔥 Firestore
    // await _firestore.addDocument(collectionPath: 'groups', data: data);
  }

  Future<void> addMember(String groupId, Map<String, dynamic> member, {bool useMock = true}) async {
    if (useMock) {
      final g = _mockGroups.firstWhere((g) => g["id"] == groupId);
      (g["members"] as List).add(member);
      return;
    }

    // 🔥 Firestore
    // await _firestore.updateDocument(collectionPath: 'groups', docId: groupId, data: {
    //   "members": FieldValue.arrayUnion([member])
    // });
  }

  Future<void> removeMember(String groupId, String memberId, {bool useMock = true}) async {
    if (useMock) {
      final g = _mockGroups.firstWhere((g) => g["id"] == groupId);
      (g["members"] as List).removeWhere((m) => m["id"] == memberId);
      return;
    }

    // 🔥 Firestore
    // await _firestore.updateDocument(collectionPath: 'groups', docId: groupId, data: {
    //   "members": FieldValue.arrayRemove([...])
    // });
  }
}
