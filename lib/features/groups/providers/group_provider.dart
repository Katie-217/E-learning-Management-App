// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../repositories/group_repository.dart';

// final groupRepositoryProvider = Provider((ref) => GroupRepository());

// final groupProvider = StateNotifierProvider<GroupNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
//   return GroupNotifier(ref.read);
// });

// class GroupNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
//   final Reader _read;
//   GroupNotifier(this._read) : super(const AsyncValue.loading()) {
//     loadGroups();
//   }

//   Future<void> loadGroups() async {
//     final repo = _read(groupRepositoryProvider);
//     final groups = await repo.getGroups();
//     state = AsyncValue.data(groups);
//   }

//   Future<void> addGroup(Map<String, dynamic> data) async {
//     final repo = _read(groupRepositoryProvider);
//     await repo.addGroup(data);
//     await loadGroups();
//   }

//   Future<void> addMember(String groupId, Map<String, dynamic> member) async {
//     final repo = _read(groupRepositoryProvider);
//     await repo.addMember(groupId, member);
//     await loadGroups();
//   }

//   Future<void> removeMember(String groupId, String memberId) async {
//     final repo = _read(groupRepositoryProvider);
//     await repo.removeMember(groupId, memberId);
//     await loadGroups();
//   }
// }
