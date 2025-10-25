import 'package:flutter/material.dart';
import '../../../../data/models/course_model.dart';
import 'upcoming_widget.dart';

class StreamTab extends StatelessWidget {
  final CourseModel course;
  const StreamTab({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: composer + posts (scrollable)
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnnouncementComposer(),
                        const SizedBox(height: 12),
                        _PostItem(
                          title: 'Welcome to ${course.name}',
                          subtitle: 'Share your questions and resources here.',
                          meta: 'Teacher • just now',
                        ),
                        const SizedBox(height: 10),
                        const _PostItem(
                          title: 'Project 1 Guidelines',
                          subtitle: 'Please read the instructions before starting.',
                          meta: 'Teacher • 2 days ago',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // RIGHT: upcoming fixed width
                const SizedBox(
                  width: 320,
                  child: UpcomingWidget(),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnnouncementComposer(),
                  const SizedBox(height: 12),
                  _PostItem(
                    title: 'Welcome to ${course.name}',
                    subtitle: 'Share your questions and resources here.',
                    meta: 'Teacher • just now',
                  ),
                  const SizedBox(height: 10),
                  const _PostItem(
                    title: 'Project 1 Guidelines',
                    subtitle: 'Please read the instructions before starting.',
                    meta: 'Teacher • 2 days ago',
                  ),
                  const SizedBox(height: 16),
                  const UpcomingWidget(),
                ],
              ),
            ),
    );
  }
}

class _AnnouncementComposer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[800]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Announce something to your class",
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.attach_file, color: Colors.white70),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.image_outlined, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PostItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  const _PostItem({required this.title, required this.subtitle, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(meta, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: Colors.white70),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(color: Colors.grey[300])),

          const SizedBox(height: 12),
          Divider(color: Colors.grey[800]),

          // Comments preview
          const _CommentItem(
            name: 'Student A',
            time: '1 hour ago',
            content: 'This is helpful, thanks!',
          ),
          const SizedBox(height: 8),
          const _CommentItem(
            name: 'Student B',
            time: 'yesterday',
            content: 'Can we get an example for section 2?',
          ),

          const SizedBox(height: 8),
          // Add comment input
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Add class comment...',
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final String name;
  final String time;
  final String content;
  const _CommentItem({required this.name, required this.time, required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF374151),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 16, color: Colors.white70),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}


