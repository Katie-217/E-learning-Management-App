import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/application/controllers/forum/forum_provider.dart';
import 'package:elearning_management_app/core/theme/app_colors.dart';
import 'package:elearning_management_app/presentation/widgets/common/sidebar_model.dart';
import 'package:elearning_management_app/presentation/widgets/forum/Student/create_topic_dialog.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart'
    as auth_repo;
import 'package:url_launcher/url_launcher.dart';
import 'package:elearning_management_app/presentation/widgets/forum/common/forum_file_preview_widget.dart';
import 'package:elearning_management_app/presentation/widgets/forum/common/forum_file_upload_widget.dart';
import 'package:file_picker/file_picker.dart';

enum _ForumView {
  courses,
  topics,
  topicDetail,
}

class CourseForumsListScreen extends ConsumerStatefulWidget {
  final bool showSidebar;
  const CourseForumsListScreen({super.key, this.showSidebar = true});

  @override
  ConsumerState<CourseForumsListScreen> createState() => _CourseForumsListScreenState();
}

class _CourseForumsListScreenState extends ConsumerState<CourseForumsListScreen> {
  String _searchQuery = '';
  String _selectedSemester = 'Tất cả học kì';
  _ForumView _view = _ForumView.courses;
  String? _selectedCourseId;
  String? _selectedCourseName;
  String? _selectedCourseCode;
  String? _selectedTopicId;
  Map<String, dynamic>? _selectedTopicData;
  final TextEditingController _replyInputController = TextEditingController();
  final TextEditingController _rootCommentController = TextEditingController();
  bool _isSendingReply = false;
  String? _replyingToId;
  String? _replyingToAuthor;
  Set<String> _expandedReplies = {};
  List<PlatformFile> _rootCommentFiles = [];
  List<PlatformFile> _replyFiles = [];
  final TextEditingController _topicSearchController = TextEditingController();
  String _topicSearchQuery = '';
  final ScrollController _repliesScrollController = ScrollController();

  @override
  void dispose() {
    _topicSearchController.dispose();
    _replyInputController.dispose();
    _rootCommentController.dispose();
    _repliesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forumsAsync = ref.watch(courseForumsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: widget.showSidebar
          ? AppBar(
              backgroundColor: AppColors.bgAppbar,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                    'E-Learning',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                // Ô tìm kiếm - responsive width với Flexible để tránh overflow
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    // Giảm width để tránh overflow
                    final searchWidth = screenWidth > 1200
                        ? 280.0
                        : screenWidth > 800
                            ? 200.0
                            : screenWidth > 600
                                ? 150.0
                                : screenWidth > 400
                                    ? 120.0
                                    : 0.0; // Ẩn search bar trên màn hình rất nhỏ
                    
                    if (searchWidth == 0) {
                      return const SizedBox.shrink();
                    }
                    
                    return Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: searchWidth,
                          minWidth: 0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: screenWidth > 600 ? 'Search forums, topics...' : 'Search...',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              filled: true,
                              fillColor: AppColors.bgInput,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Thông báo
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                ),
                // Avatar + tên - ẩn tên trên màn hình nhỏ
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.indigo, Colors.purple]),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (screenWidth > 700) ...[
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'Jara Khan',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            )
          : null,

      // ==================== BODY ====================
      body: Row(
        children: [
          // Sidebar - chỉ hiện khi màn hình rộng và showSidebar = true
          if (widget.showSidebar && MediaQuery.of(context).size.width > 800)
            const SidebarWidget(),

          // Nội dung chính - một cột dọc duy nhất
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final outerPad = constraints.maxWidth > 1200
                    ? 48.0
                    : constraints.maxWidth > 900
                        ? 32.0
                        : constraints.maxWidth > 600
                            ? 20.0
                            : 14.0;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: outerPad),
                  child: Column(
                    children: [
                      // Khoảng cách giữa thanh bar và header card
                      const SizedBox(height: 40),
                      // Header Section - responsive padding
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final padding = screenWidth > 800
                              ? 20.0
                              : screenWidth > 600
                                  ? 16.0
                                  : 12.0;
                          return Container(
                            padding: EdgeInsets.all(padding),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Back buttons theo level
                                if (_view == _ForumView.topics)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20.0),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _view = _ForumView.courses;
                                          _selectedCourseId = null;
                                          _selectedCourseName = null;
                                          _selectedCourseCode = null;
                                          _topicSearchQuery = '';
                                          _topicSearchController.clear();
                                        });
                                      },
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white70, size: 18),
                                      label: const Text(
                                        'Back to courses',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  )
                                else if (_view == _ForumView.topicDetail)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20.0),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _view = _ForumView.topics;
                                          _selectedTopicId = null;
                                          _selectedTopicData = null;
                                        });
                                      },
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white70, size: 18),
                                      label: const Text(
                                        'Back to topics',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(screenWidth > 600 ? 12 : 10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Colors.indigo, Colors.purple],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.forum, 
                                          color: Colors.white, 
                                          size: screenWidth > 600 ? 28 : 24),
                                    ),
                                    SizedBox(width: screenWidth > 600 ? 16 : 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            () {
                                              switch (_view) {
                                                case _ForumView.courses:
                                                  return 'Course Forums';
                                                case _ForumView.topics:
                                                  if (_selectedCourseCode != null &&
                                                      _selectedCourseName != null) {
                                                    return screenWidth > 600
                                                        ? '$_selectedCourseCode - $_selectedCourseName • Forum'
                                                        : '$_selectedCourseCode Forum';
                                                  }
                                                  return 'Course Forum';
                                                case _ForumView.topicDetail:
                                                  return _selectedTopicData != null
                                                      ? (_selectedTopicData!['title'] ?? 'Topic')
                                                      : 'Topic Discussion';
                                              }
                                            }(),
                                            style: TextStyle(
                                                fontSize: screenWidth > 800
                                                    ? 24
                                                    : screenWidth > 600
                                                        ? 20
                                                        : 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            () {
                                              switch (_view) {
                                                case _ForumView.courses:
                                                  return 'Select a course to view its discussion forums';
                                                case _ForumView.topics:
                                                  return 'Browse and manage discussion topics for this course';
                                                case _ForumView.topicDetail:
                                                  return 'View full discussion and replies for this topic';
                                              }
                                            }(),
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: screenWidth > 600 ? 14 : 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              // Search bar chỉ hiện ở courses view
                              if (_view == _ForumView.courses) ...[
                                const SizedBox(height: 20),
                                TextField(
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search courses by name or code...',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                                    filled: true,
                                    fillColor: const Color(0xFF111827),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Content: switch theo flow forum - nằm trong cùng một cột
                      Expanded(
                        child: () {
                          switch (_view) {
                            case _ForumView.courses:
                              return _buildCoursesView(forumsAsync);
                            case _ForumView.topics:
                              return _buildTopicsView();
                            case _ForumView.topicDetail:
                              return _buildTopicDetailView();
                          }
                        }(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filter forums by search query and semester
  List<Map<String, dynamic>> _getFilteredForums(List<Map<String, dynamic>> forums) {
    return forums.where((forum) {
      final matchesSearch = _searchQuery.isEmpty ||
          (forum['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (forum['code'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesSemester = _selectedSemester == 'Tất cả học kì' || 
          (forum['semester'] ?? '').toString() == _selectedSemester;
      
      return matchesSearch && matchesSemester;
    }).toList();
  }

  Widget _buildCoursesView(AsyncValue<List<Map<String, dynamic>>> forumsAsync) {
    return forumsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading forums',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (forums) {
        final filteredForums = _getFilteredForums(forums);
        if (filteredForums.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Colors.grey[600],
                ),
                        const SizedBox(height: 24),
                        const Text(
                  'No courses found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                  _searchQuery.isEmpty
                      ? 'You don\'t have any courses yet'
                      : 'Try adjusting your search or filters',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                        ),
                      ],
                    ),
                  );
                }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(courseForumsProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 3
                  : constraints.maxWidth > 800
                      ? 2
                      : 1;
              // Điều chỉnh aspect ratio để tránh overflow trên màn hình nhỏ
              final childAspectRatio = screenWidth > 600
                  ? 1.5
                  : screenWidth > 400
                      ? 1.3
                      : 1.1; // Giảm aspect ratio trên màn hình nhỏ để card cao hơn
              final padding = screenWidth > 600 ? 16.0 : screenWidth > 400 ? 12.0 : 8.0;
              final spacing = screenWidth > 600 ? 16.0 : screenWidth > 400 ? 12.0 : 8.0;
              
              return GridView.builder(
                padding: EdgeInsets.all(padding),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: filteredForums.length,
                itemBuilder: (context, index) {
                  final forum = filteredForums[index];
                  return _CourseForumCard(
                    courseId: forum['id'],
                    courseName: forum['name'] ?? 'Unknown Course',
                    courseCode: forum['code'] ?? '',
                    semester: forum['semester'] ?? 'N/A',
                    onTap: () {
                      setState(() {
                        _selectedCourseId = forum['id'];
                        _selectedCourseName = forum['name'] ?? 'Unknown Course';
                        _selectedCourseCode = forum['code'] ?? '';
                        _view = _ForumView.topics;
                        _topicSearchQuery = '';
                        _topicSearchController.clear();
                      });
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is DateTime) return dateData;
    try {
      if (dateData is Timestamp) return dateData.toDate();
      return DateTime.parse(dateData.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _initialLetter(dynamic name) {
    final str = (name ?? '').toString().trim();
    if (str.isEmpty) return '?';
    return str.isNotEmpty ? str[0].toUpperCase() : '?';
  }

  Widget _buildTopicsView() {
    final courseId = _selectedCourseId;
    if (courseId == null) {
      return const Center(
        child: Text(
          'Select a course to view topics.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final topicsAsync = _topicSearchQuery.isEmpty
        ? ref.watch(topicsProvider(courseId))
        : ref.watch(
            searchTopicsProvider((courseId: courseId, query: _topicSearchQuery)),
          );

    return Stack(
      children: [
        Column(
          children: [
            // Header with search
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final padding = screenWidth > 600 ? 16.0 : screenWidth > 400 ? 12.0 : 10.0;
                return Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[800]!),
                    ),
                  ),
                  child: TextField(
                    controller: _topicSearchController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 16 : screenWidth > 400 ? 15 : 14,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _topicSearchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: screenWidth > 400 ? 'Search topics...' : 'Search...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: screenWidth > 600 ? 16 : screenWidth > 400 ? 15 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                        size: screenWidth > 600 ? 24 : screenWidth > 400 ? 22 : 20,
                      ),
                      suffixIcon: _topicSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: screenWidth > 600 ? 24 : screenWidth > 400 ? 22 : 20,
                              ),
                              onPressed: () {
                                _topicSearchController.clear();
                                setState(() {
                                  _topicSearchQuery = '';
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: screenWidth > 600 ? 48 : screenWidth > 400 ? 44 : 40,
                                minHeight: screenWidth > 600 ? 48 : screenWidth > 400 ? 44 : 40,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF111827),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 16 : screenWidth > 400 ? 14 : 12,
                        vertical: screenWidth > 600 ? 16 : screenWidth > 400 ? 14 : 12,
                      ),
                      isDense: screenWidth <= 400,
                    ),
                  ),
                );
              },
            ),

            // Topics List
            Expanded(
              child: topicsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading topics',
                        style: TextStyle(color: Colors.red[400], fontSize: 16),
                      ),
                    ],
                  ),
                ),
                data: (topics) {
                  if (topics.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.topic_outlined, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            _topicSearchQuery.isEmpty ? 'No topics yet' : 'No topics found',
                            style: TextStyle(color: Colors.grey[400], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(topicsProvider(courseId));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        return _StudentTopicCardInline(
                          title: topic['title'] ?? 'Untitled',
                          authorName: topic['authorName'] ?? 'Unknown',
                          replyCount: topic['replyCount'] ?? 0,
                          createdAt: _formatTimeAgo(
                            _parseDateTime(topic['createdAt']),
                          ),
                          isPinned: topic['isPinned'] ?? false,
                          onTap: () {
                            setState(() {
                              _selectedTopicId = topic['id'];
                              _selectedTopicData = topic;
                              _view = _ForumView.topicDetail;
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Floating Action Button hình vuông ở góc phải dưới
        Positioned(
          bottom: 16,
          right: 16,
          child: Material(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => CreateTopicDialog(
                    courseId: courseId,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicDetailView() {
    final courseId = _selectedCourseId;
    final topicId = _selectedTopicId;
    final topic = _selectedTopicData;

    if (courseId == null || topicId == null || topic == null) {
      return const Center(
        child: Text(
          'Select a topic to view its discussion.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final repliesAsync = ref.watch(repliesProvider((
      courseId: courseId,
      topicId: topicId,
    )));

    return repliesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Error loading replies: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (replies) {
              // Build reply map
              final Map<String, Map<String, dynamic>> replyMap = {};
              for (final r in replies) {
                final id = r['id']?.toString();
                if (id != null && id.isNotEmpty) {
                  replyMap[id] = r;
                }
              }

              // Separate root and children
              final List<Map<String, dynamic>> rootReplies = [];
              final Map<String, List<Map<String, dynamic>>> childrenByParent = {};

              for (final r in replies) {
                final parentId = r['replyToId']?.toString();
                if (parentId == null || parentId.isEmpty) {
                  rootReplies.add(r);
                } else {
                  if (replyMap.containsKey(parentId)) {
                    childrenByParent.putIfAbsent(parentId, () => []).add(r);
                  } else {
                    rootReplies.add(r);
                  }
                }
              }

              // Sort
              rootReplies.sort((a, b) {
                final aTime = _parseDateTime(a['createdAt']);
                final bTime = _parseDateTime(b['createdAt']);
                return aTime.compareTo(bTime);
              });

              for (final key in childrenByParent.keys) {
                childrenByParent[key]!.sort((a, b) {
                  final aTime = _parseDateTime(a['createdAt']);
                  final bTime = _parseDateTime(b['createdAt']);
                  return aTime.compareTo(bTime);
                });
              }

              // Build ordered list with depth
              final List<Map<String, dynamic>> orderedReplies = [];

              void addWithChildren(Map<String, dynamic> reply, int depth) {
                reply['_depth'] = depth;
                orderedReplies.add(reply);
                final id = reply['id']?.toString();
                if (id == null || id.isEmpty) return;

                if (_expandedReplies.contains(id)) {
                  final children = childrenByParent[id] ?? const [];
                  for (final child in children) {
                    addWithChildren(child, depth + 1);
                  }
                }
              }

              for (final root in rootReplies) {
                addWithChildren(root, 0);
              }

              return Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ListView chiếm hết chiều cao còn lại - có thể scroll original post và comments
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final horizontalPadding = screenWidth > 1200
                            ? 24.0
                            : screenWidth > 900
                                ? 20.0
                                : screenWidth > 600
                                    ? 16.0
                                    : 12.0;
                        final topPadding = screenWidth > 600 ? 24.0 : 16.0;
                        return ListView.builder(
                          controller: _repliesScrollController,
                          padding: EdgeInsets.only(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            top: topPadding,
                            bottom: 12,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: orderedReplies.length + 1,
                          itemBuilder: (context, index) {
                            // Original post ở đầu
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOriginalPost(topic),
                                const SizedBox(height: 8),
                                const Text(
                                  'Comments',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                            // Replies (index - 1 vì đã có original post ở index 0)
                            final reply = orderedReplies[index - 1];
                            final bool isChild = reply['replyToId'] != null &&
                                reply['replyToId'].toString().isNotEmpty;
                            final int depth = reply['_depth'] as int? ?? 0;
                            final replyId = reply['id']?.toString();

                            // Determine position in sibling list và check if parent has more children below
                            bool isFirstChild = false;
                            bool isLastChild = false;
                            bool parentHasMoreChildrenBelow = false;
                            bool isLastSibling = false;

                            if (isChild && replyId != null) {
                              final parentId = reply['replyToId']?.toString();
                              if (parentId != null) {
                                final siblings = childrenByParent[parentId] ?? [];
                                if (siblings.isNotEmpty) {
                                  final currentIndex = siblings.indexWhere((s) => s['id']?.toString() == replyId);
                                  isFirstChild = currentIndex == 0;
                                  isLastChild = currentIndex == siblings.length - 1;
                                  
                                  // Check if this is the last sibling in the ordered list
                                  // by looking ahead for replies with same parentId and same depth
                                  bool foundNextSibling = false;
                                  if (index < orderedReplies.length) {
                                    for (int i = index + 1; i < orderedReplies.length; i++) {
                                      final nextReply = orderedReplies[i];
                                      final nextParentId = nextReply['replyToId']?.toString();
                                      final nextDepth = nextReply['_depth'] as int? ?? 0;
                                      
                                      // Nếu depth nhỏ hơn depth hiện tại, đã vượt qua tất cả siblings
                                      if (nextDepth < depth) {
                                        break;
                                      }
                                      
                                      // Nếu depth lớn hơn, vẫn đang trong subtree của parent, tiếp tục tìm
                                      if (nextDepth > depth) {
                                        continue;
                                      }
                                      
                                      // Nếu cùng depth và cùng parent, đây là sibling
                                      if (nextDepth == depth && nextParentId == parentId) {
                                        foundNextSibling = true;
                                        parentHasMoreChildrenBelow = true;
                                        break;
                                      }
                                      
                                      // Nếu cùng depth nhưng khác parent, đã vượt qua tất cả siblings
                                      if (nextDepth == depth && nextParentId != parentId) {
                                        break;
                                      }
                                    }
                                  }
                                  isLastSibling = !foundNextSibling;
                                }
                              }
                            }

                            return _buildReplyItem(
                              reply,
                              depth,
                              isChild,
                              isFirstChild,
                              isLastChild,
                              isLastSibling,
                              parentHasMoreChildrenBelow,
                              childrenByParent,
                              courseId,
                              topicId,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Comment input cố định ở dưới cùng - không scroll
                  SafeArea(
                    top: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final horizontalPadding = screenWidth > 600 ? 8.0 : 4.0;
                        return Padding(
                          padding: EdgeInsets.only(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            bottom: 8,
                          ),
                          child: _buildRootCommentInput(courseId, topicId),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
    );
  }

  Widget _buildOriginalPost(Map<String, dynamic> topic) {
    final attachments = (topic['attachments'] as List?)
            ?.whereType<String>()
            .toList() ??
        const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.indigo.shade700,
            child: Text(
              _initialLetter(topic['authorName']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic['authorName'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeAgo(_parseDateTime(topic['createdAt'])),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  topic['content'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  maxLines: 20,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  AttachmentDisplayWidget(attachments: attachments),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRootCommentInput(String courseId, String topicId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Padding(
          padding: EdgeInsets.only(
            top: screenWidth > 600 ? 16 : 12,
            bottom: screenWidth > 600 ? 16 : 12,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              screenWidth > 600 ? 12 : 8,
              screenWidth > 600 ? 8 : 6,
              screenWidth > 600 ? 12 : 8,
              screenWidth > 600 ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hiển thị file đã chọn
                if (_rootCommentFiles.isNotEmpty) ...[
                  SelectedFilesListWidget(
                    files: _rootCommentFiles,
                    onRemove: (index) {
                      setState(() => _rootCommentFiles.removeAt(index));
                    },
                  ),
                  SizedBox(height: screenWidth > 600 ? 8 : 6),
                ],
                Row(
                  children: [
                    CircleAvatar(
                      radius: screenWidth > 600 ? 16 : 14,
                      backgroundColor: Colors.indigo.shade700,
                      child: Icon(
                        Icons.person,
                        size: screenWidth > 600 ? 16 : 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: screenWidth > 600 ? 8 : 6),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1220),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 16 : 12,
                          vertical: screenWidth > 600 ? 4 : 3,
                        ),
                        child: TextField(
                          controller: _rootCommentController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 600 ? 14 : 13,
                          ),
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: screenWidth > 600 ? 13 : 12,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth > 600 ? 8 : 4),
                    if (screenWidth > 500)
                      OutlinedButton.icon(
                        onPressed: _isSendingReply ? null : () async {
                          final files = await ForumFileUploadHelper.pickFiles(
                            ref: ref,
                            allowMultiple: true,
                          );
                          if (files != null) {
                            setState(() => _rootCommentFiles.addAll(files));
                          }
                        },
                        icon: Icon(
                          Icons.attach_file,
                          size: screenWidth > 600 ? 16 : 14,
                        ),
                        label: Text(
                          'File',
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 12 : 11,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo[400],
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth > 600 ? 12 : 8,
                            vertical: screenWidth > 600 ? 8 : 6,
                          ),
                          minimumSize: Size(0, screenWidth > 600 ? 36 : 32),
                        ),
                      ),
                    if (screenWidth <= 500)
                      IconButton(
                        onPressed: _isSendingReply ? null : () async {
                          final files = await ForumFileUploadHelper.pickFiles(
                            ref: ref,
                            allowMultiple: true,
                          );
                          if (files != null) {
                            setState(() => _rootCommentFiles.addAll(files));
                          }
                        },
                        icon: Icon(
                          Icons.attach_file,
                          size: screenWidth > 600 ? 16 : 14,
                          color: Colors.indigo[400],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    SizedBox(width: screenWidth > 600 ? 8 : 4),
                    IconButton(
                      onPressed: _isSendingReply ? null : () async {
                        final text = _rootCommentController.text.trim();
                        if (text.isEmpty && _rootCommentFiles.isEmpty) return;
                        setState(() => _isSendingReply = true);
                        try {
                          final userRepo = ref.read(auth_repo.authRepositoryProvider);
                          final currentUser = await userRepo.currentUserModel;
                          if (currentUser != null) {
                            List<String> attachmentUrls = [];
                            if (_rootCommentFiles.isNotEmpty) {
                              attachmentUrls = await ForumFileUploadHelper.uploadFiles(
                                ref: ref,
                                files: _rootCommentFiles,
                                folder: 'forum_replies/$courseId',
                              );
                            }
                            await ref.read(forumControllerProvider.notifier).addReply(
                              courseId: courseId,
                              topicId: topicId,
                              content: text.isEmpty ? '[Attachment]' : text,
                              currentUser: currentUser,
                              replyToId: null,
                              replyToAuthor: null,
                              attachments: attachmentUrls,
                            );
                          }
                          if (mounted) {
                            setState(() {
                              _rootCommentController.clear();
                              _rootCommentFiles.clear();
                            });
                          }
                        } catch (_) {
                        } finally {
                          if (mounted) {
                            setState(() => _isSendingReply = false);
                          }
                        }
                      },
                      icon: _isSendingReply
                          ? SizedBox(
                              width: screenWidth > 600 ? 18 : 16,
                              height: screenWidth > 600 ? 18 : 16,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: Colors.blueAccent,
                              size: screenWidth > 600 ? 24 : 20,
                            ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: screenWidth > 600 ? 48 : 40,
                        minHeight: screenWidth > 600 ? 48 : 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyItem(
    Map<String, dynamic> reply,
    int depth,
    bool isChild,
    bool isFirstChild,
    bool isLastChild,
    bool isLastSibling,
    bool parentHasMoreChildrenBelow,
    Map<String, List<Map<String, dynamic>>> childrenByParent,
    String courseId,
    String topicId,
  ) {
    final replyId = reply['id']?.toString();
    final authorName = (reply['authorName'] ?? '').toString().trim();
    final authorReplyTo = (reply['authorReplyTo'] ?? '').toString().trim();
    final children = replyId != null ? (childrenByParent[replyId] ?? []) : [];
    final hasChildren = children.isNotEmpty;
    final isExpanded = replyId != null && _expandedReplies.contains(replyId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Giảm padding depth trên màn hình nhỏ để tránh overflow
        final depthPadding = screenWidth > 600 
            ? 40.0 
            : screenWidth > 400 
                ? 30.0 
                : 20.0;
        final leftPadding = 8.0 + (depth * depthPadding);
        // Đảm bảo không vượt quá 50% chiều rộng màn hình
        final maxLeftPadding = screenWidth * 0.5;
        final finalLeftPadding = leftPadding > maxLeftPadding ? maxLeftPadding : leftPadding;
        
        return Padding(
          padding: EdgeInsets.only(
            left: finalLeftPadding,
            right: 8,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line + Avatar area
              SizedBox(
                width: screenWidth > 600 ? 46 : 36,
                height: (hasChildren && isExpanded) ? 100 : 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Vertical line của parent kéo dài từ trên xuống
                    // Nếu không phải last sibling, kéo dài đến cuối SizedBox để nối liền mạch
                    // Nếu là last sibling, chỉ kéo dài đến vị trí horizontal line
                    if (isChild)
                      Positioned(
                        left: screenWidth > 600 ? 7 : 5,
                        top: 0,
                        bottom: isLastSibling ? 20 : 0, // Last sibling: dừng ở horizontal line, còn lại: kéo dài đến cuối
                        child: Container(
                          width: 2,
                          color: Colors.grey[600],
                        ),
                      ),

                    // Horizontal line từ vertical line của parent đến avatar (chỉ vẽ cho child replies)
                    // Line này nối từ left: 7 (vertical line của parent) đến left: 32 (avatar)
                    if (isChild)
                      Positioned(
                        left: screenWidth > 600 ? 7 : 5,
                        top: 20,
                        child: Container(
                          width: screenWidth > 600 ? 25 : 20, // Từ 7 đến 32 = 25px, hoặc 5 đến 25 = 20px
                          height: 2,
                          color: Colors.grey[600],
                        ),
                      ),

                    // Avatar
                    Positioned(
                      left: screenWidth > 600 ? 32 : 25,
                      top: 6,
                      child: CircleAvatar(
                        radius: screenWidth > 600 ? 14 : 12,
                        backgroundColor: Colors.indigo.shade800,
                        child: Text(
                          _initialLetter(authorName),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 600 ? 12 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Vertical line từ avatar xuống children (chỉ vẽ khi có children và đã expand)
                    // Line này là của chính reply này, kéo dài qua tất cả children
                    // Ở vị trí left: 39 (từ avatar center + radius = 32 + 7 = 39)
                    if (hasChildren && isExpanded)
                      Positioned(
                        left: screenWidth > 600 ? 39 : 30,
                        top: 34,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(width: screenWidth > 600 ? 18 : 12),

              // Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, contentConstraints) {
                    return SizedBox(
                      width: contentConstraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: contentConstraints.maxWidth,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth > 600 ? 14 : 10,
                              vertical: screenWidth > 600 ? 10 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  authorName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth > 600 ? 13 : 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final content = (reply['content'] ?? '').toString();
                                    if (isChild && authorReplyTo.isNotEmpty) {
                                      return RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$authorReplyTo ',
                                              style: TextStyle(
                                                color: Colors.blue[300],
                                                fontSize: screenWidth > 600 ? 14 : 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(
                                              text: content,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth > 600 ? 14 : 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 10,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }
                                    return Text(
                                      content,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth > 600 ? 14 : 12,
                                      ),
                                      maxLines: 10,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _formatTimeAgo(_parseDateTime(reply['createdAt'])),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: screenWidth > 600 ? 11 : 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: screenWidth > 600 ? 12 : 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _replyingToId = replyId;
                                    _replyingToAuthor = authorName;
                                    _replyInputController.clear();
                                    _replyFiles.clear();
                                  });
                                },
                                child: Text(
                                  'Reply',
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontSize: screenWidth > 600 ? 11 : 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (hasChildren && !isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (replyId != null) _expandedReplies.add(replyId);
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: screenWidth > 600 ? 32 : 24,
                                      height: 1,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        children.length == 1
                                            ? 'View 1 reply'
                                            : 'View all ${children.length} replies',
                                        style: TextStyle(
                                          color: Colors.blue[300],
                                          fontSize: screenWidth > 600 ? 12 : 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_replyingToId == replyId) _buildReplyInput(courseId, topicId, reply),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyInput(String courseId, String topicId, Map<String, dynamic> reply) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Padding(
          padding: EdgeInsets.only(top: screenWidth > 600 ? 8 : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hiển thị file đã chọn
              if (_replyFiles.isNotEmpty) ...[
                SelectedFilesListWidget(
                  files: _replyFiles,
                  onRemove: (index) {
                    setState(() => _replyFiles.removeAt(index));
                  },
                ),
                SizedBox(height: screenWidth > 600 ? 8 : 6),
              ],
              Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth > 600 ? 14 : 12,
                    backgroundColor: Colors.indigo.shade700,
                    child: Icon(
                      Icons.person,
                      size: screenWidth > 600 ? 14 : 12,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: screenWidth > 600 ? 8 : 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 16 : 12,
                        vertical: screenWidth > 600 ? 4 : 3,
                      ),
                      child: TextField(
                        controller: _replyInputController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth > 600 ? 14 : 13,
                        ),
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Write a reply...',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: screenWidth > 600 ? 13 : 12,
                          ),
                          prefixIcon: _replyingToAuthor != null
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth > 600 ? 4 : 2,
                                    right: screenWidth > 600 ? 8 : 6,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth > 600 ? 8 : 6,
                                      vertical: screenWidth > 600 ? 4 : 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[800],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _replyingToAuthor!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth > 600 ? 12 : 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                              : null,
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth > 600 ? 8 : 4),
                  if (screenWidth > 500)
                    OutlinedButton.icon(
                      onPressed: _isSendingReply ? null : () async {
                        final files = await ForumFileUploadHelper.pickFiles(
                          ref: ref,
                          allowMultiple: true,
                        );
                        if (files != null) {
                          setState(() => _replyFiles.addAll(files));
                        }
                      },
                      icon: Icon(
                        Icons.attach_file,
                        size: screenWidth > 600 ? 14 : 12,
                      ),
                      label: Text(
                        'File',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 11 : 10,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo[400],
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 10 : 8,
                          vertical: screenWidth > 600 ? 6 : 5,
                        ),
                        minimumSize: Size(0, screenWidth > 600 ? 32 : 28),
                      ),
                    ),
                  if (screenWidth <= 500)
                    IconButton(
                      onPressed: _isSendingReply ? null : () async {
                        final files = await ForumFileUploadHelper.pickFiles(
                          ref: ref,
                          allowMultiple: true,
                        );
                        if (files != null) {
                          setState(() => _replyFiles.addAll(files));
                        }
                      },
                      icon: Icon(
                        Icons.attach_file,
                        size: screenWidth > 600 ? 14 : 12,
                        color: Colors.indigo[400],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  SizedBox(width: screenWidth > 600 ? 8 : 4),
                  IconButton(
                    onPressed: _isSendingReply ? null : () async {
                      final text = _replyInputController.text.trim();
                      if (text.isEmpty && _replyFiles.isEmpty) return;
                      setState(() => _isSendingReply = true);
                      try {
                        final userRepo = ref.read(auth_repo.authRepositoryProvider);
                        final currentUser = await userRepo.currentUserModel;
                        if (currentUser != null) {
                          List<String> attachmentUrls = [];
                          if (_replyFiles.isNotEmpty) {
                            attachmentUrls = await ForumFileUploadHelper.uploadFiles(
                              ref: ref,
                              files: _replyFiles,
                              folder: 'forum_replies/$courseId',
                            );
                          }
                          await ref.read(forumControllerProvider.notifier).addReply(
                            courseId: courseId,
                            topicId: topicId,
                            content: text.isEmpty ? '[Attachment]' : text,
                            currentUser: currentUser,
                            replyToId: reply['id'],
                            replyToAuthor: reply['authorName'],
                            attachments: attachmentUrls,
                          );
                        }
                        if (mounted) {
                          setState(() {
                            _replyInputController.clear();
                            _replyingToId = null;
                            _replyingToAuthor = null;
                            _replyFiles.clear();
                          });
                        }
                      } catch (_) {
                      } finally {
                        if (mounted) {
                          setState(() => _isSendingReply = false);
                        }
                      }
                    },
                    icon: _isSendingReply
                        ? SizedBox(
                            width: screenWidth > 600 ? 18 : 16,
                            height: screenWidth > 600 ? 18 : 16,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: Colors.blueAccent,
                            size: screenWidth > 600 ? 18 : 16,
                          ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: screenWidth > 600 ? 40 : 36,
                      minHeight: screenWidth > 600 ? 40 : 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========================================
// WIDGET: Course Forum Card
// ========================================
class _CourseForumCard extends ConsumerWidget {
  final String courseId;
  final String courseName;
  final String courseCode;
  final String semester;
  final VoidCallback onTap;

  const _CourseForumCard({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.semester,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get forum stats for this course
    final topicsAsync = ref.watch(topicsProvider(courseId));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final padding = screenWidth > 600 ? 20.0 : screenWidth > 400 ? 14.0 : 12.0;
              return SizedBox(
                height: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth > 600 ? 10 : screenWidth > 400 ? 8 : 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.indigo, Colors.purple],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.forum,
                              color: Colors.white,
                              size: screenWidth > 600 ? 24 : screenWidth > 400 ? 20 : 18,
                            ),
                          ),
                          SizedBox(width: screenWidth > 600 ? 12 : screenWidth > 400 ? 10 : 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  courseCode,
                                  style: TextStyle(
                                    color: Colors.indigo[400],
                                    fontSize: screenWidth > 600 ? 12 : screenWidth > 400 ? 11 : 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenWidth > 600 ? 4 : 3),
                                Text(
                                  courseName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth > 600 ? 16 : screenWidth > 400 ? 15 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Semester Tag
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 8 : screenWidth > 400 ? 6 : 5,
                          vertical: screenWidth > 600 ? 4 : screenWidth > 400 ? 3 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: screenWidth > 600 ? 12 : screenWidth > 400 ? 11 : 10,
                              color: Colors.blue[300],
                            ),
                            SizedBox(width: screenWidth > 600 ? 4 : 3),
                            Flexible(
                              child: Text(
                                semester,
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: screenWidth > 600 ? 11 : screenWidth > 400 ? 10 : 9,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenWidth > 600 ? 12 : screenWidth > 400 ? 10 : 8),
                      const Divider(color: Colors.grey, height: 1),
                      SizedBox(height: screenWidth > 600 ? 20 : screenWidth > 400 ? 18 : 16),

                    // Stats
                    topicsAsync.when(
                      loading: () => Center(
                        child: SizedBox(
                          width: screenWidth > 600 ? 20 : 18,
                          height: screenWidth > 600 ? 20 : 18,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) {
                        const topicCount = 0;
                        const replyCount = 0;
                        return Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                label: 'Topics',
                                value: topicCount,
                                icon: Icons.topic,
                                color: Colors.blue,
                                isSmallScreen: screenWidth <= 400,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: screenWidth > 600 ? 30 : screenWidth > 400 ? 28 : 24,
                              color: Colors.grey[700],
                            ),
                            Expanded(
                              child: _StatItem(
                                label: 'Replies',
                                value: replyCount,
                                icon: Icons.comment,
                                color: Colors.green,
                                isSmallScreen: screenWidth <= 400,
                              ),
                            ),
                          ],
                        );
                      },
                      data: (topics) {
                        final topicCount = topics.length;
                        final replyCount = topics.fold<int>(
                          0,
                          (sum, topic) => sum + (topic['replyCount'] as int? ?? 0),
                        );

                        return Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                label: 'Topics',
                                value: topicCount,
                                icon: Icons.topic,
                                color: Colors.blue[400]!,
                                isSmallScreen: screenWidth <= 400,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: screenWidth > 600 ? 30 : screenWidth > 400 ? 28 : 24,
                              color: Colors.grey[700],
                            ),
                            Expanded(
                              child: _StatItem(
                                label: 'Replies',
                                value: replyCount,
                                icon: Icons.comment,
                                color: Colors.green[400]!,
                                isSmallScreen: screenWidth <= 400,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  SizedBox(height: screenWidth > 600 ? 12 : screenWidth > 400 ? 10 : 8),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        Icons.manage_search,
                        size: screenWidth > 600 ? 18 : screenWidth > 400 ? 16 : 14,
                      ),
                      label: Text(
                        'View Forum',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 14 : screenWidth > 400 ? 13 : 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.withOpacity(0.2),
                        foregroundColor: Colors.indigo[300],
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth > 600 ? 10 : screenWidth > 400 ? 8 : 6,
                          horizontal: screenWidth > 600 ? 16 : screenWidth > 400 ? 12 : 8,
                        ),
                        minimumSize: Size(0, screenWidth > 600 ? 40 : screenWidth > 400 ? 36 : 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.indigo.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ========================================
// WIDGET: Stat Item
// ========================================
class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isSmallScreen;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
      mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
      children: [
            Icon(
              icon,
              size: isSmallScreen ? 14 : 16,
              color: color,
            ),
            SizedBox(width: isSmallScreen ? 3 : 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: isSmallScreen ? 11 : 12,
          ),
        ),
      ],
    );
  }
}

class _StudentTopicCardInline extends StatelessWidget {
  final String title;
  final String authorName;
  final int replyCount;
  final String createdAt;
  final bool isPinned;
  final VoidCallback onTap;

  const _StudentTopicCardInline({
    required this.title,
    required this.authorName,
    required this.replyCount,
    required this.createdAt,
    this.isPinned = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPinned ? Colors.amber.withOpacity(0.5) : Colors.grey[800]!,
          width: isPinned ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPinned
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.indigo.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPinned ? Icons.push_pin : Icons.topic,
                    color: isPinned ? Colors.amber[700] : Colors.indigo[400],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isPinned) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Text(
                                'Pinned',
                                style: TextStyle(
                                  color: Colors.amber[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'by $authorName',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(' • ',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                            '$replyCount replies',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Text(' • ',
                              style: TextStyle(color: Colors.grey[600])),
                          Flexible(
                            child: Text(
                              createdAt,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
