import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/conversation_model.dart';
import '../../../domain/models/private_message_model.dart';
import '../../../domain/models/user_model.dart';
import '../student/student_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

abstract class IChatRepository {
  Stream<List<ConversationModel>> getConversationsStream(String userId);
  Stream<List<PrivateMessageModel>> getMessagesStream(String conversationId);
  Future<void> sendMessage({required String conversationId, required String senderId, required String content});
  Future<String> startOrGetConversation(String userA, String userB);
  Future<void> markConversationAsRead(String conversationId, String userId);
  Future<UserModel?> getUserProfile(String userId);
  Future<List<UserModel>> getMyInstructors(String studentId);
  Future<List<UserModel>> getMyStudents(String instructorId);
}

class ChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  @override
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    
    // ✅ BỎ orderBy để tránh cần index, sort ở client-side
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          
          final conversations = snapshot.docs
              .map((doc) => ConversationModel.fromFirestore(doc))
              .toList();
          
          // ✅ Sort ở client-side theo lastMessageAt
          conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
          
          return conversations;
        })
        .handleError((error) {
        });
  }

  @override
  Stream<List<PrivateMessageModel>> getMessagesStream(String conversationId) {
    
    // ✅ BỎ orderBy để tránh cần index, sort ở client-side
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          
          final messages = snapshot.docs
              .map((doc) => PrivateMessageModel.fromFirestore(doc))
              .toList();
          
          // ✅ Sort ở client-side theo sentAt (descending)
          messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          
          return messages;
        })
        .handleError((error) {
        });
  }

  @override
  Future<void> sendMessage({
    required String conversationId, 
    required String senderId, 
    required String content
  }) async {

    
    try {
      // 1. Kiểm tra conversation tồn tại
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
          
      if (!conversationDoc.exists) {
        throw Exception('Cuộc trò chuyện không tồn tại');
      }
      
      
      // 2. Kiểm tra user có quyền không
      final conversation = ConversationModel.fromFirestore(conversationDoc);
      if (!conversation.participantIds.contains(senderId)) {

        throw Exception('Bạn không có quyền gửi tin nhắn ở đây');
      }
      
 
      
      // 3. Tạo message
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
      
      
      // 4. Ghi vào Firestore
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
      
      
    } catch (e, stackTrace) {

      rethrow;
    }
  }


// Chỉ cần sửa hàm startOrGetConversation trong chat_repository.dart

@override
Future<String> startOrGetConversation(String userA, String userB) async {

  final userADoc = await _firestore.collection('users').doc(userA).get();
  final userBDoc = await _firestore.collection('users').doc(userB).get();
  
  if (!userADoc.exists) {

    throw Exception('Người dùng A không tồn tại');
  }
  
  if (!userBDoc.exists) {
    throw Exception('Người dùng B không tồn tại');
  }
  

  // 2. Kiểm tra Role - ✅ FIX: So sánh case-insensitive
  final roleA = (userADoc.data()?['role'] ?? '').toString().toLowerCase();
  final roleB = (userBDoc.data()?['role'] ?? '').toString().toLowerCase();
  

  // ✅ So sánh với lowercase
  bool isValid = (roleA == 'student' && roleB == 'instructor') ||
                 (roleA == 'instructor' && roleB == 'student');

  if (!isValid) {
    if (roleA == 'instructor' && roleB == 'instructor') {
      throw Exception('Hệ thống không hỗ trợ chat riêng giữa các giảng viên.');
    }
    if (roleA == 'student' && roleB == 'student') {
      throw Exception('Chỉ cho phép nhắn tin với giảng viên.');
    }
    throw Exception('Chỉ cho phép nhắn tin giữa Giảng viên và Sinh viên.');
  }


  // 3. Tạo conversation ID (sorted để đảm bảo unique)
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
  } else {
  }
  
  return conversationId;
}
  @override
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    
    try {
      final docRef = _firestore.collection('conversations').doc(conversationId);
      final snapshot = await docRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['lastMessageSenderId'] != userId) {
          await docRef.update({'isRead': true});
        }
      }
    } catch (e) {
    }
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<UserModel>> getMyInstructors(String studentId) async {
    try {
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
      final students = await StudentRepository.getAllStudents();
      students.sort((a, b) => a.name.compareTo(b.name));
      return students;
    } catch (e) {
      return [];
    }
  }
}
