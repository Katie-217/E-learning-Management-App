import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateMessageModel {
  final String id;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  const PrivateMessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory PrivateMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrivateMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      sentAt: _parseDateTime(data['sentAt']),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.parse(val);
    return DateTime.now();
  }
}