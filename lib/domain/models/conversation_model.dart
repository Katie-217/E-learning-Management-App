import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds; // [id_student, id_instructor]
  final String lastMessageContent;
  final DateTime lastMessageAt;
  final String lastMessageSenderId;
  final bool isRead;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.lastMessageContent,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    this.isRead = false,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessageContent: data['lastMessageContent'] ?? '',
      lastMessageAt: _parseDateTime(data['lastMessageAt']),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      isRead: data['isRead'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'lastMessageContent': lastMessageContent,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageSenderId': lastMessageSenderId,
      'isRead': isRead,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Helper: Tìm ID người chat cùng mình
  String getOtherParticipantId(String myId) {
    return participantIds.firstWhere((id) => id != myId, orElse: () => '');
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    return DateTime.now();
  }
}