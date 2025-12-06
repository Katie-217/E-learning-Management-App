import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../domain/models/private_message_model.dart';
import '../../../domain/models/user_model.dart';
import '../student/student_repository.dart'; // ✅ Import StudentRepository

abstract class IChatRepository {
  Stream<List<ConversationModel>> getConversationsStream(String userId);
  Stream<List<PrivateMessageModel>> getMessagesStream(String conversationId);
  Future<void> sendMessage({required String conversationId, required String senderId, required String content});
  Future<String> startOrGetConversation(String userA, String userB);
  Future<void> markConversationAsRead(String conversationId, String userId);
  Future<UserModel?> getUserProfile(String userId);

  // ✅ Updated methods
  Future<List<UserModel>> getMyInstructors(String studentId);
  Future<List<UserModel>> getMyStudents(String instructorId);
}

class ChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  @override
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ConversationModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<PrivateMessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PrivateMessageModel.fromFirestore(doc)).toList());
  }

  @override
  Future<void> sendMessage({required String conversationId, required String senderId, required String content}) async {
    final conversationDoc = await _firestore.collection('conversations').doc(conversationId).get();
    if (!conversationDoc.exists) throw Exception('Cuộc trò chuyện không tồn tại');

    final conversation = ConversationModel.fromFirestore(conversationDoc);
    if (!conversation.participantIds.contains(senderId)) {
      throw Exception('Bạn không có quyền gửi tin nhắn ở đây');
    }

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final messagesRef = conversationRef.collection('messages').doc();
    final now = DateTime.now();

    final newMessage = PrivateMessageModel(
      id: messagesRef.id,
      senderId: senderId,
      content: content,
      sentAt: now,
      isRead: false,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(messagesRef, newMessage.toFirestore());
      transaction.update(conversationRef, {
        'lastMessageContent': content,
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
        'isRead': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<String> startOrGetConversation(String userA, String userB) async {
    // 1. Kiểm tra tồn tại
    final userADoc = await _firestore.collection('users').doc(userA).get();
    final userBDoc = await _firestore.collection('users').doc(userB).get();
    if (!userADoc.exists || !userBDoc.exists) throw Exception('Người dùng không tồn tại');

    // 2. Kiểm tra Role (Chỉ cho phép Student <-> Instructor)
    final roleA = userADoc.data()?['role'] ?? '';
    final roleB = userBDoc.data()?['role'] ?? '';

    bool isValid = (roleA == 'student' && roleB == 'instructor') ||
                   (roleA == 'instructor' && roleB == 'student');

    if (!isValid) {
      if (roleA == 'instructor' && roleB == 'instructor') {
        throw Exception('Hệ thống không hỗ trợ chat riêng giữa các giảng viên.');
      }
      throw Exception('Chỉ cho phép nhắn tin giữa Giảng viên và Sinh viên.');
    }

    final ids = [userA, userB]..sort();
    final conversationId = 'chat_${ids[0]}_${ids[1]}';
    final docRef = _firestore.collection('conversations').doc(conversationId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final newConversation = ConversationModel(
        id: conversationId,
        participantIds: ids,
        lastMessageContent: 'Bắt đầu trò chuyện',
        lastMessageAt: DateTime.now(),
        lastMessageSenderId: '',
        isRead: true,
      );
      await docRef.set(newConversation.toFirestore());
    }
    return conversationId;
  }

  @override
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    final docRef = _firestore.collection('conversations').doc(conversationId);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['lastMessageSenderId'] != userId) {
        await docRef.update({'isRead': true});
      }
    }
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) { return null; }
  }

  // ========================================
  // ✅ OPTIMIZED: Sử dụng StudentRepository
  // ========================================

  @override
  Future<List<UserModel>> getMyInstructors(String studentId) async {
    try {
      // Logic: Lấy Groups -> Course -> InstructorId -> User
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('studentIds', arrayContains: studentId)
          .get();
          
      if (groupsSnapshot.docs.isEmpty) return [];

      final courseIds = groupsSnapshot.docs
          .map((d) => d.data()['courseId'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();
          
      if (courseIds.isEmpty) return [];

      final instructorIds = <String>{};
      for (final cid in courseIds) {
         final cDoc = await _firestore.collection('courses').doc(cid).get();
         if (cDoc.exists) {
           final iId = cDoc.data()?['instructorId'];
           if (iId != null) instructorIds.add(iId);
         }
      }
      
      if (instructorIds.isEmpty) return [];
      
      // Lấy User details
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: instructorIds.toList())
          .get();
          
      return usersSnapshot.docs
          .map((d) => UserModel.fromFirestore(d))
          .toList();
    } catch (e) { 
      return []; 
    }
  }

  @override
  Future<List<UserModel>> getMyStudents(String instructorId) async {
    try {
      print('🔵 [ChatRepository] Getting students for instructor: $instructorId');
      
      // ✅ Sử dụng StudentRepository (reuse existing logic)
      final students = await StudentRepository.getAllStudents();
      
      print('🔵 [ChatRepository] Found ${students.length} students');
      
      // ✅ Sort by name (consistent with student management)
      students.sort((a, b) => a.name.compareTo(b.name));
      
      return students;
      
    } catch (e) {
      print('🔴 [ChatRepository] Error: $e');
      return [];
    }
  }
}