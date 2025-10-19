// giáo viên dùng (thêm/sửa/xóa)
import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/group_provider.dart';

class ManageGroupPage extends StatefulWidget {
  const ManageGroupPage({super.key});

  @override
  State<ManageGroupPage> createState() => _ManageGroupPageState();
}

class _ManageGroupPageState extends State<ManageGroupPage> {
  final _formKey = GlobalKey<FormState>();
  String name = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Group"), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Group Name",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                onChanged: (v) => name = v,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // ref.read(groupProvider.notifier).addGroup({
                    //   "id": DateTime.now().millisecondsSinceEpoch.toString(),
                    //   "name": name,
                    //   "course": "IT4409 - Web Programming",
                    //   "members": [],
                    //   "teacher": "Dr. Nguyen Van A",
                    // });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group management feature coming soon')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
