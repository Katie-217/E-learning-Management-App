import 'package:flutter/material.dart';
import 'notification_service.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: FilledButton(
          onPressed: () => NotificationService.instance.showSimple(
            'Hello',
            'This is a local notification',
          ),
          child: const Text('Test notification'),
        ),
      ),
    );
  }
}















