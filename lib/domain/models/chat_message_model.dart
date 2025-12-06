// // ========================================
// // FILE: chat_message_model.dart
// // MÔ TẢ: Model tin nhắn riêng giữa instructor và student
// // ========================================

// class ChatMessageModel {
//   final String id;
//   final String courseId;
//   final String conversationId; // ID cuộc trò chuyện
//   final String senderId;
//   final String senderName;
//   final String senderRole;
//   final String receiverId;
//   final String receiverName;
//   final String receiverRole;
//   final String content;
//   final MessageType type;
//   final List<AttachmentModel> attachments;
//   final DateTime sentAt;
//   final DateTime? readAt;
//   final MessageStatus status;
//   final String? replyToMessageId; // Reply to message
//   final bool isEdited;
//   final DateTime? editedAt;
//   final bool isDeleted;

//   const ChatMessageModel({
//     required this.id,
//     required this.courseId,
//     required this.conversationId,
//     required this.senderId,
//     required this.senderName,
//     required this.senderRole,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverRole,
//     required this.content,
//     this.type = MessageType.text,
//     this.attachments = const [],
//     required this.sentAt,
//     this.readAt,
//     this.status = MessageStatus.sent,
//     this.replyToMessageId,
//     this.isEdited = false,
//     this.editedAt,
//     this.isDeleted = false,
//   });

//   factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
//     return ChatMessageModel(
//       id: map['id'] ?? '',
//       courseId: map['courseId'] ?? '',
//       conversationId: map['conversationId'] ?? '',
//       senderId: map['senderId'] ?? '',
//       senderName: map['senderName'] ?? '',
//       senderRole: map['senderRole'] ?? '',
//       receiverId: map['receiverId'] ?? '',
//       receiverName: map['receiverName'] ?? '',
//       receiverRole: map['receiverRole'] ?? '',
//       content: map['content'] ?? '',
//       type: _parseMessageType(map['type'] ?? 'text'),
//       attachments: (map['attachments'] as List<dynamic>?)
//               ?.map((item) =>
//                   AttachmentModel.fromMap(item as Map<String, dynamic>))
//               .toList() ??
//           [],
//       sentAt: _parseDateTime(map['sentAt']) ?? DateTime.now(),
//       readAt: _parseDateTime(map['readAt']),
//       status: _parseStatus(map['status'] ?? 'sent'),
//       replyToMessageId: map['replyToMessageId'],
//       isEdited: map['isEdited'] ?? false,
//       editedAt: _parseDateTime(map['editedAt']),
//       isDeleted: map['isDeleted'] ?? false,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'courseId': courseId,
//       'conversationId': conversationId,
//       'senderId': senderId,
//       'senderName': senderName,
//       'senderRole': senderRole,
//       'receiverId': receiverId,
//       'receiverName': receiverName,
//       'receiverRole': receiverRole,
//       'content': content,
//       'type': type.name,
//       'attachments':
//           attachments.map((attachment) => attachment.toMap()).toList(),
//       'sentAt': sentAt.toIso8601String(),
//       'readAt': readAt?.toIso8601String(),
//       'status': status.name,
//       'replyToMessageId': replyToMessageId,
//       'isEdited': isEdited,
//       'editedAt': editedAt?.toIso8601String(),
//       'isDeleted': isDeleted,
//     };
//   }

//   ChatMessageModel copyWith({
//     String? id,
//     String? courseId,
//     String? conversationId,
//     String? senderId,
//     String? senderName,
//     String? senderRole,
//     String? receiverId,
//     String? receiverName,
//     String? receiverRole,
//     String? content,
//     MessageType? type,
//     List<AttachmentModel>? attachments,
//     DateTime? sentAt,
//     DateTime? readAt,
//     MessageStatus? status,
//     String? replyToMessageId,
//     bool? isEdited,
//     DateTime? editedAt,
//     bool? isDeleted,
//   }) {
//     return ChatMessageModel(
//       id: id ?? this.id,
//       courseId: courseId ?? this.courseId,
//       conversationId: conversationId ?? this.conversationId,
//       senderId: senderId ?? this.senderId,
//       senderName: senderName ?? this.senderName,
//       senderRole: senderRole ?? this.senderRole,
//       receiverId: receiverId ?? this.receiverId,
//       receiverName: receiverName ?? this.receiverName,
//       receiverRole: receiverRole ?? this.receiverRole,
//       content: content ?? this.content,
//       type: type ?? this.type,
//       attachments: attachments ?? this.attachments,
//       sentAt: sentAt ?? this.sentAt,
//       readAt: readAt ?? this.readAt,
//       status: status ?? this.status,
//       replyToMessageId: replyToMessageId ?? this.replyToMessageId,
//       isEdited: isEdited ?? this.isEdited,
//       editedAt: editedAt ?? this.editedAt,
//       isDeleted: isDeleted ?? this.isDeleted,
//     );
//   }

//   // ========================================
//   // GETTER: isRead
//   // ========================================
//   bool get isRead => readAt != null;

//   // ========================================
//   // GETTER: hasAttachments
//   // ========================================
//   bool get hasAttachments => attachments.isNotEmpty;

//   // ========================================
//   // GETTER: isReply
//   // ========================================
//   bool get isReply => replyToMessageId != null;

//   // ========================================
//   // GETTER: timeAgo
//   // ========================================
//   String get timeAgo {
//     final now = DateTime.now();
//     final difference = now.difference(sentAt);

//     if (difference.inDays > 0) {
//       return '${difference.inDays} ngày trước';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours} giờ trước';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes} phút trước';
//     } else {
//       return 'Vừa xong';
//     }
//   }

//   // ========================================
//   // HÀM: markAsRead()
//   // ========================================
//   ChatMessageModel markAsRead() {
//     return copyWith(
//       readAt: DateTime.now(),
//       status: MessageStatus.read,
//     );
//   }

//   // ========================================
//   // HÀM: isSentBy()
//   // ========================================
//   bool isSentBy(String userId) => senderId == userId;

//   static MessageType _parseMessageType(String type) {
//     switch (type.toLowerCase()) {
//       case 'text':
//         return MessageType.text;
//       case 'file':
//         return MessageType.file;
//       case 'image':
//         return MessageType.image;
//       case 'system':
//         return MessageType.system;
//       default:
//         return MessageType.text;
//     }
//   }

//   static MessageStatus _parseStatus(String status) {
//     switch (status.toLowerCase()) {
//       case 'sending':
//         return MessageStatus.sending;
//       case 'sent':
//         return MessageStatus.sent;
//       case 'delivered':
//         return MessageStatus.delivered;
//       case 'read':
//         return MessageStatus.read;
//       case 'failed':
//         return MessageStatus.failed;
//       default:
//         return MessageStatus.sent;
//     }
//   }

//   static DateTime? _parseDateTime(dynamic dateData) {
//     if (dateData == null) return null;
//     if (dateData is DateTime) return dateData;
//     try {
//       return DateTime.parse(dateData.toString());
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   String toString() =>
//       'ChatMessageModel(id: $id, sender: $senderName, content: ${content.length > 20 ? '${content.substring(0, 20)}...' : content})';

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is ChatMessageModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }

// // ========================================
// // CLASS: ConversationModel
// // MÔ TẢ: Model cuộc trò chuyện
// // ========================================
// class ConversationModel {
//   final String id;
//   final String courseId;
//   final List<String> participantIds;
//   final Map<String, String> participantNames; // {uid: name}
//   final Map<String, String> participantRoles; // {uid: role}
//   final String? lastMessageId;
//   final String? lastMessageContent;
//   final DateTime? lastMessageAt;
//   final DateTime createdAt;
//   final Map<String, DateTime?> lastReadAt; // {uid: lastReadTime}
//   final Map<String, int> unreadCounts; // {uid: unreadCount}
//   final bool isActive;

//   const ConversationModel({
//     required this.id,
//     required this.courseId,
//     required this.participantIds,
//     required this.participantNames,
//     required this.participantRoles,
//     this.lastMessageId,
//     this.lastMessageContent,
//     this.lastMessageAt,
//     required this.createdAt,
//     this.lastReadAt = const {},
//     this.unreadCounts = const {},
//     this.isActive = true,
//   });

//   factory ConversationModel.fromMap(Map<String, dynamic> map) {
//     return ConversationModel(
//       id: map['id'] ?? '',
//       courseId: map['courseId'] ?? '',
//       participantIds: List<String>.from(map['participantIds'] ?? []),
//       participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
//       participantRoles: Map<String, String>.from(map['participantRoles'] ?? {}),
//       lastMessageId: map['lastMessageId'],
//       lastMessageContent: map['lastMessageContent'],
//       lastMessageAt: map['lastMessageAt'] != null
//           ? DateTime.parse(map['lastMessageAt'])
//           : null,
//       createdAt:
//           DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
//       lastReadAt: (map['lastReadAt'] as Map<String, dynamic>?)?.map((key,
//                   value) =>
//               MapEntry(key, value != null ? DateTime.parse(value) : null)) ??
//           {},
//       unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
//       isActive: map['isActive'] ?? true,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'courseId': courseId,
//       'participantIds': participantIds,
//       'participantNames': participantNames,
//       'participantRoles': participantRoles,
//       'lastMessageId': lastMessageId,
//       'lastMessageContent': lastMessageContent,
//       'lastMessageAt': lastMessageAt?.toIso8601String(),
//       'createdAt': createdAt.toIso8601String(),
//       'lastReadAt': lastReadAt
//           .map((key, value) => MapEntry(key, value?.toIso8601String())),
//       'unreadCounts': unreadCounts,
//       'isActive': isActive,
//     };
//   }

//   // ========================================
//   // HÀM: getUnreadCount()
//   // ========================================
//   int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

//   // ========================================
//   // HÀM: getOtherParticipant()
//   // ========================================
//   String? getOtherParticipant(String currentUserId) {
//     return participantIds.firstWhere(
//       (id) => id != currentUserId,
//       orElse: () => '',
//     );
//   }
// }

// // ========================================
// // ENUM: MessageType
// // ========================================
// enum MessageType {
//   text, // Tin nhắn text
//   file, // File đính kèm
//   image, // Hình ảnh
//   system, // Tin nhắn hệ thống
// }

// extension MessageTypeExtension on MessageType {
//   String get displayName {
//     switch (this) {
//       case MessageType.text:
//         return 'Tin nhắn';
//       case MessageType.file:
//         return 'File';
//       case MessageType.image:
//         return 'Hình ảnh';
//       case MessageType.system:
//         return 'Hệ thống';
//     }
//   }

//   String get name {
//     switch (this) {
//       case MessageType.text:
//         return 'text';
//       case MessageType.file:
//         return 'file';
//       case MessageType.image:
//         return 'image';
//       case MessageType.system:
//         return 'system';
//     }
//   }
// }

// // ========================================
// // ENUM: MessageStatus
// // ========================================
// enum MessageStatus {
//   sending, // Đang gửi
//   sent, // Đã gửi
//   delivered, // Đã chuyển
//   read, // Đã đọc
//   failed, // Gửi thất bại
// }

// extension MessageStatusExtension on MessageStatus {
//   String get displayName {
//     switch (this) {
//       case MessageStatus.sending:
//         return 'Đang gửi';
//       case MessageStatus.sent:
//         return 'Đã gửi';
//       case MessageStatus.delivered:
//         return 'Đã chuyển';
//       case MessageStatus.read:
//         return 'Đã đọc';
//       case MessageStatus.failed:
//         return 'Thất bại';
//     }
//   }

//   String get name {
//     switch (this) {
//       case MessageStatus.sending:
//         return 'sending';
//       case MessageStatus.sent:
//         return 'sent';
//       case MessageStatus.delivered:
//         return 'delivered';
//       case MessageStatus.read:
//         return 'read';
//       case MessageStatus.failed:
//         return 'failed';
//     }
//   }
// }

// // ========================================
// // CLASS: AttachmentModel (Reused)
// // ========================================
// class AttachmentModel {
//   final String id;
//   final String name;
//   final String url;
//   final String mimeType;
//   final int sizeInBytes;
//   final DateTime uploadedAt;

//   const AttachmentModel({
//     required this.id,
//     required this.name,
//     required this.url,
//     required this.mimeType,
//     required this.sizeInBytes,
//     required this.uploadedAt,
//   });

//   factory AttachmentModel.fromMap(Map<String, dynamic> map) {
//     return AttachmentModel(
//       id: map['id'] ?? '',
//       name: map['name'] ?? '',
//       url: map['url'] ?? '',
//       mimeType: map['mimeType'] ?? '',
//       sizeInBytes: map['sizeInBytes'] ?? 0,
//       uploadedAt:
//           DateTime.parse(map['uploadedAt'] ?? DateTime.now().toIso8601String()),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'url': url,
//       'mimeType': mimeType,
//       'sizeInBytes': sizeInBytes,
//       'uploadedAt': uploadedAt.toIso8601String(),
//     };
//   }
// }
