// ========================================
// FILE: instructor_progress_charts.dart
// MÔ TẢ: Progress charts cho instructor dashboard - CHỈ MOCK DATA
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/progress_overview/pie_chart_widget.dart';
import 'dart:math' as math;
import 'dart:async';

// Assignment Submission Progress Chart
class AssignmentSubmissionChart extends StatelessWidget {
  const AssignmentSubmissionChart({super.key});

  // Mock data - không động vào repository
  Map<String, int> get _mockData => const {
        'notSubmitted': 45,
        'submitted': 120,
        'late': 15,
        'graded': 100,
      };

  @override
  Widget build(BuildContext context) {
    final data = _mockData;
    final total = data.values.reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignment Submission Progress',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return isNarrow
                  ? Column(
                      children: [
                        _buildDonutChart(data, total),
                        const SizedBox(height: 16),
                        _buildLegend(data),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDonutChart(data, total),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _buildLegend(data),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, int> data, int total) {
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: _AssignmentPieChartPainter(
        notSubmitted: data['notSubmitted']!.toDouble(),
        submitted: data['submitted']!.toDouble(),
        late: data['late']!.toDouble(),
        graded: data['graded']!.toDouble(),
      ),
    );
  }

  Widget _buildLegend(Map<String, int> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendItem(
          color: const Color(0xFFFF6B6B), // Red
          label: 'Not Submitted',
          value: data['notSubmitted']!,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: const Color(0xFF60A5FA), // Blue
          label: 'Submitted',
          value: data['submitted']!,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: const Color(0xFFFFB347), // Orange
          label: 'Late',
          value: data['late']!,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: const Color(0xFF34D399), // Green
          label: 'Graded',
          value: data['graded']!,
        ),
      ],
    );
  }
}

// Quiz Completion Progress Chart
class QuizCompletionChart extends StatelessWidget {
  const QuizCompletionChart({super.key});

  // Mock data - không động vào repository
  Map<String, int> get _mockData => const {
        'notStarted': 30,
        'completed': 80,
        'passed': 65,
        'failed': 15,
      };

  @override
  Widget build(BuildContext context) {
    final data = _mockData;
    final total = data.values.reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Completion Progress',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return isNarrow
                  ? Column(
                      children: [
                        _buildDonutChart(data, total),
                        const SizedBox(height: 16),
                        _buildLegend(data),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDonutChart(data, total),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _buildLegend(data),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, int> data, int total) {
    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: _QuizPieChartPainter(
        notStarted: data['notStarted']!.toDouble(),
        completed: data['completed']!.toDouble(),
        passed: data['passed']!.toDouble(),
        failed: data['failed']!.toDouble(),
      ),
    );
  }

  Widget _buildLegend(Map<String, int> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendItem(
          color: const Color(0xFF9CA3AF), // Gray
          label: 'Not Started',
          value: data['notStarted']!,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: const Color(0xFF0EA5E9), // Blue
          label: 'Completed',
          value: data['completed']!,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: const Color(0xFF34D399), // Green
          label: 'Passed',
          value: data['passed']!,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: const Color(0xFFFF6B6B), // Red
          label: 'Failed',
          value: data['failed']!,
        ),
      ],
    );
  }
}

// Activity Timeline Chart
class ActivityTimelineChart extends StatelessWidget {
  const ActivityTimelineChart({super.key});

  // Mock data - không động vào repository
  List<Map<String, dynamic>> get _mockData => [
        {'date': 'Mon', 'submissions': 12, 'quizzes': 5, 'announcements': 2},
        {'date': 'Tue', 'submissions': 18, 'quizzes': 8, 'announcements': 1},
        {'date': 'Wed', 'submissions': 15, 'quizzes': 6, 'announcements': 3},
        {'date': 'Thu', 'submissions': 22, 'quizzes': 10, 'announcements': 2},
        {'date': 'Fri', 'submissions': 20, 'quizzes': 7, 'announcements': 1},
        {'date': 'Sat', 'submissions': 8, 'quizzes': 3, 'announcements': 0},
        {'date': 'Sun', 'submissions': 5, 'quizzes': 2, 'announcements': 0},
      ];

  @override
  Widget build(BuildContext context) {
    final data = _mockData;
    final maxValue = data
        .map((d) => math.max(
            math.max(d['submissions'] as int, d['quizzes'] as int),
            d['announcements'] as int))
        .reduce(math.max)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Timeline',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                data: data,
                maxValue: maxValue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimelineLegendItem(
                color: const Color(0xFF60A5FA),
                label: 'Submissions',
              ),
              const SizedBox(width: 24),
              _TimelineLegendItem(
                color: const Color(0xFF0EA5E9),
                label: 'Quizzes',
              ),
              const SizedBox(width: 24),
              _TimelineLegendItem(
                color: const Color(0xFF34D399),
                label: 'Announcements',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painters with hover support
class _AssignmentPieChartPainter extends StatefulWidget {
  final double notSubmitted;
  final double submitted;
  final double late;
  final double graded;

  const _AssignmentPieChartPainter({
    required this.notSubmitted,
    required this.submitted,
    required this.late,
    required this.graded,
  });

  @override
  State<_AssignmentPieChartPainter> createState() =>
      _AssignmentPieChartPainterState();
}

class _AssignmentPieChartPainterState
    extends State<_AssignmentPieChartPainter> {
  String? _hoveredSegment;
  Offset? _hoverPosition;
  final GlobalKey _key = GlobalKey();
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  String? _getSegmentAtPosition(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 15;
    final innerRadius = radius * 0.6;

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Check if point is within the donut (between inner and outer radius)
    if (distance < innerRadius || distance > radius) return null;

    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);

    final total =
        widget.notSubmitted + widget.submitted + widget.late + widget.graded;
    if (total <= 0) return null;

    final segments = [
      ('notSubmitted', widget.notSubmitted),
      ('submitted', widget.submitted),
      ('late', widget.late),
      ('graded', widget.graded),
    ];

    double currentAngle = 0;
    for (final (segment, value) in segments) {
      final segmentAngle = (value / total) * 2 * math.pi;
      if (angle >= currentAngle && angle < currentAngle + segmentAngle) {
        return segment;
      }
      currentAngle += segmentAngle;
    }
    return null;
  }

  Widget _buildTooltip() {
    if (_hoveredSegment == null || _hoverPosition == null) {
      return const SizedBox.shrink();
    }

    final total =
        widget.notSubmitted + widget.submitted + widget.late + widget.graded;
    if (total <= 0) return const SizedBox.shrink();

    final Map<String, Map<String, dynamic>> segmentData = {
      'notSubmitted': {
        'value': widget.notSubmitted,
        'label': 'Not Submitted',
        'color': const Color(0xFFFF6B6B),
      },
      'submitted': {
        'value': widget.submitted,
        'label': 'Submitted',
        'color': const Color(0xFF60A5FA),
      },
      'late': {
        'value': widget.late,
        'label': 'Late',
        'color': const Color(0xFFFFB347),
      },
      'graded': {
        'value': widget.graded,
        'label': 'Graded',
        'color': const Color(0xFF34D399),
      },
    };

    final data = segmentData[_hoveredSegment]!;
    final value = data['value'] as double;
    final percent = (value / total) * 100;
    final color = data['color'] as Color;
    final label = data['label'] as String;

    return Positioned(
      left: _hoverPosition!.dx + 15,
      top: _hoverPosition!.dy - 80,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minWidth: 160),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Value: ${value.toInt()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Percentage: ${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${total.toInt()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MouseRegion(
            hitTestBehavior: HitTestBehavior.opaque,
            onHover: (event) {
              if (!mounted) return;
              // Cancel previous timer
              _hoverTimer?.cancel();
              // Store values to use in callback
              final localPosition = event.localPosition;
              // Use microtask to delay setState outside device update phase
              _hoverTimer = Timer(Duration.zero, () {
                if (!mounted) return;
                try {
                  final RenderBox? renderBox =
                      _key.currentContext?.findRenderObject() as RenderBox?;
                  if (renderBox == null ||
                      !renderBox.hasSize ||
                      !renderBox.attached) return;
                  final size = renderBox.size;
                  final segment = _getSegmentAtPosition(localPosition, size);
                  // Use Future.microtask to ensure setState is called outside device update
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _hoveredSegment = segment;
                        _hoverPosition = localPosition;
                      });
                    }
                  });
                } catch (e) {
                  // Ignore errors during hover
                }
              });
            },
            onExit: (_) {
              _hoverTimer?.cancel();
              if (mounted) {
                // Immediate update on exit for better UX
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _hoveredSegment = null;
                      _hoverPosition = null;
                    });
                  }
                });
              }
            },
            child: CustomPaint(
              key: _key,
              size: const Size(220, 220),
              painter: _AssignmentPieChartCustomPainter(
                notSubmitted: widget.notSubmitted,
                submitted: widget.submitted,
                late: widget.late,
                graded: widget.graded,
                hoveredSegment: _hoveredSegment,
              ),
            ),
          ),
          if (_hoveredSegment != null && _hoverPosition != null)
            _buildTooltip(),
        ],
      ),
    );
  }
}

class _AssignmentPieChartCustomPainter extends CustomPainter {
  final double notSubmitted;
  final double submitted;
  final double late;
  final double graded;
  final String? hoveredSegment;

  _AssignmentPieChartCustomPainter({
    required this.notSubmitted,
    required this.submitted,
    required this.late,
    required this.graded,
    this.hoveredSegment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 15;
    final innerRadius = baseRadius * 0.6; // Donut hole
    final total = notSubmitted + submitted + late + graded;

    if (total <= 0) return;

    final colors = [
      const Color(0xFFFF6B6B), // Not Submitted - Red
      const Color(0xFF60A5FA), // Submitted - Blue
      const Color(0xFFFFB347), // Late - Orange
      const Color(0xFF34D399), // Graded - Green
    ];

    final segments = [
      ('notSubmitted', notSubmitted),
      ('submitted', submitted),
      ('late', late),
      ('graded', graded),
    ];

    double startAngle = -math.pi / 2;

    // Draw all segments first (for proper layering)
    for (int i = 0; i < segments.length; i++) {
      final (segment, value) = segments[i];
      if (value > 0) {
        final isHovered = hoveredSegment == segment;
        final radius = isHovered ? baseRadius + 10 : baseRadius;
        final innerR = isHovered ? innerRadius + 6 : innerRadius;
        final offset = isHovered ? 8.0 : 0.0;
        final sweepAngle = (value / total) * 2 * math.pi;
        final middleAngle = startAngle + sweepAngle / 2;
        final offsetX = offset * math.cos(middleAngle);
        final offsetY = offset * math.sin(middleAngle);
        final adjustedCenter = Offset(center.dx + offsetX, center.dy + offsetY);

        // Shadow for elevation (always draw, stronger when hovered)
        final shadowOpacity = isHovered ? 0.4 : 0.2;
        final shadowBlur = isHovered ? 12.0 : 6.0;
        final shadowOffset = isHovered ? 4.0 : 2.0;
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: shadowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);

        // Draw shadow with slight offset
        final shadowCenter = Offset(
          adjustedCenter.dx + shadowOffset,
          adjustedCenter.dy + shadowOffset,
        );
        final shadowRect =
            Rect.fromCircle(center: shadowCenter, radius: radius);
        canvas.drawArc(shadowRect, startAngle, sweepAngle, true, shadowPaint);

        // Draw donut segment with fill
        final rect = Rect.fromCircle(center: adjustedCenter, radius: radius);
        final innerRect =
            Rect.fromCircle(center: adjustedCenter, radius: innerR);

        // Create path for donut segment
        final path = Path()
          ..moveTo(
            adjustedCenter.dx + radius * math.cos(startAngle),
            adjustedCenter.dy + radius * math.sin(startAngle),
          )
          ..arcTo(rect, startAngle, sweepAngle, false)
          ..arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false)
          ..close();

        // Draw base fill
        final fillPaint = Paint()
          ..color = colors[i]
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);

        // Create a radial gradient mask for inner edge depth
        final depthGradient = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.black.withValues(alpha: 0.0), // Transparent at outer edge
            Colors.black.withValues(alpha: 0.4), // Darker at inner edge
          ],
          stops: const [0.6, 1.0],
        );

        final depthPaint = Paint()
          ..shader = depthGradient.createShader(rect)
          ..blendMode = BlendMode.multiply;

        // Draw depth gradient
        canvas.drawPath(path, depthPaint);

        // Draw inner edge shadow for depth
        final innerShadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawArc(
            innerRect, startAngle, sweepAngle, false, innerShadowPaint);

        // Draw inner edge highlight
        final innerHighlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(
            innerRect, startAngle, sweepAngle, false, innerHighlightPaint);

        // Draw border for better definition
        final borderPaint = Paint()
          ..color = colors[i].withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(path, borderPaint);

        startAngle += sweepAngle;
      }
    }

    // Center circle for donut effect
    final centerPaint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerPaint);

    // Center circle border
    final centerBorderPaint = Paint()
      ..color = Colors.grey[800]!.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, innerRadius, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _AssignmentPieChartCustomPainter oldDelegate) {
    return oldDelegate.notSubmitted != notSubmitted ||
        oldDelegate.submitted != submitted ||
        oldDelegate.late != late ||
        oldDelegate.graded != graded ||
        oldDelegate.hoveredSegment != hoveredSegment;
  }
}

class _QuizPieChartPainter extends StatefulWidget {
  final double notStarted;
  final double completed;
  final double passed;
  final double failed;

  const _QuizPieChartPainter({
    required this.notStarted,
    required this.completed,
    required this.passed,
    required this.failed,
  });

  @override
  State<_QuizPieChartPainter> createState() => _QuizPieChartPainterState();
}

class _QuizPieChartPainterState extends State<_QuizPieChartPainter> {
  String? _hoveredSegment;
  Offset? _hoverPosition;
  final GlobalKey _key = GlobalKey();
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  String? _getSegmentAtPosition(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 15;
    final innerRadius = radius * 0.6;

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Check if point is within the donut (between inner and outer radius)
    if (distance < innerRadius || distance > radius) return null;

    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);

    final total =
        widget.notStarted + widget.completed + widget.passed + widget.failed;
    if (total <= 0) return null;

    final segments = [
      ('notStarted', widget.notStarted),
      ('completed', widget.completed),
      ('passed', widget.passed),
      ('failed', widget.failed),
    ];

    double currentAngle = 0;
    for (final (segment, value) in segments) {
      final segmentAngle = (value / total) * 2 * math.pi;
      if (angle >= currentAngle && angle < currentAngle + segmentAngle) {
        return segment;
      }
      currentAngle += segmentAngle;
    }
    return null;
  }

  Widget _buildTooltip() {
    if (_hoveredSegment == null || _hoverPosition == null) {
      return const SizedBox.shrink();
    }

    final total =
        widget.notStarted + widget.completed + widget.passed + widget.failed;
    if (total <= 0) return const SizedBox.shrink();

    final Map<String, Map<String, dynamic>> segmentData = {
      'notStarted': {
        'value': widget.notStarted,
        'label': 'Not Started',
        'color': const Color(0xFF9CA3AF),
      },
      'completed': {
        'value': widget.completed,
        'label': 'Completed',
        'color': const Color(0xFF0EA5E9),
      },
      'passed': {
        'value': widget.passed,
        'label': 'Passed',
        'color': const Color(0xFF34D399),
      },
      'failed': {
        'value': widget.failed,
        'label': 'Failed',
        'color': const Color(0xFFFF6B6B),
      },
    };

    final data = segmentData[_hoveredSegment]!;
    final value = data['value'] as double;
    final percent = (value / total) * 100;
    final color = data['color'] as Color;
    final label = data['label'] as String;

    return Positioned(
      left: _hoverPosition!.dx + 15,
      top: _hoverPosition!.dy - 80,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minWidth: 160),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Value: ${value.toInt()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Percentage: ${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${total.toInt()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MouseRegion(
            hitTestBehavior: HitTestBehavior.opaque,
            onHover: (event) {
              if (!mounted) return;
              // Cancel previous timer
              _hoverTimer?.cancel();
              // Store values to use in callback
              final localPosition = event.localPosition;
              // Use microtask to delay setState outside device update phase
              _hoverTimer = Timer(Duration.zero, () {
                if (!mounted) return;
                try {
                  final RenderBox? renderBox =
                      _key.currentContext?.findRenderObject() as RenderBox?;
                  if (renderBox == null ||
                      !renderBox.hasSize ||
                      !renderBox.attached) return;
                  final size = renderBox.size;
                  final segment = _getSegmentAtPosition(localPosition, size);
                  // Use Future.microtask to ensure setState is called outside device update
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _hoveredSegment = segment;
                        _hoverPosition = localPosition;
                      });
                    }
                  });
                } catch (e) {
                  // Ignore errors during hover
                }
              });
            },
            onExit: (_) {
              _hoverTimer?.cancel();
              if (mounted) {
                // Immediate update on exit for better UX
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _hoveredSegment = null;
                      _hoverPosition = null;
                    });
                  }
                });
              }
            },
            child: CustomPaint(
              key: _key,
              size: const Size(220, 220),
              painter: _QuizPieChartCustomPainter(
                notStarted: widget.notStarted,
                completed: widget.completed,
                passed: widget.passed,
                failed: widget.failed,
                hoveredSegment: _hoveredSegment,
              ),
            ),
          ),
          if (_hoveredSegment != null && _hoverPosition != null)
            _buildTooltip(),
        ],
      ),
    );
  }
}

class _QuizPieChartCustomPainter extends CustomPainter {
  final double notStarted;
  final double completed;
  final double passed;
  final double failed;
  final String? hoveredSegment;

  _QuizPieChartCustomPainter({
    required this.notStarted,
    required this.completed,
    required this.passed,
    required this.failed,
    this.hoveredSegment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 15;
    final innerRadius = baseRadius * 0.6; // Donut hole
    final total = notStarted + completed + passed + failed;

    if (total <= 0) return;

    final colors = [
      const Color(0xFF9CA3AF), // Not Started - Gray
      const Color(0xFF0EA5E9), // Completed - Blue
      const Color(0xFF34D399), // Passed - Green
      const Color(0xFFFF6B6B), // Failed - Red
    ];

    final segments = [
      ('notStarted', notStarted),
      ('completed', completed),
      ('passed', passed),
      ('failed', failed),
    ];

    double startAngle = -math.pi / 2;

    // Draw all segments first (for proper layering)
    for (int i = 0; i < segments.length; i++) {
      final (segment, value) = segments[i];
      if (value > 0) {
        final isHovered = hoveredSegment == segment;
        final radius = isHovered ? baseRadius + 10 : baseRadius;
        final innerR = isHovered ? innerRadius + 6 : innerRadius;
        final offset = isHovered ? 8.0 : 0.0;
        final sweepAngle = (value / total) * 2 * math.pi;
        final middleAngle = startAngle + sweepAngle / 2;
        final offsetX = offset * math.cos(middleAngle);
        final offsetY = offset * math.sin(middleAngle);
        final adjustedCenter = Offset(center.dx + offsetX, center.dy + offsetY);

        // Shadow for elevation (always draw, stronger when hovered)
        final shadowOpacity = isHovered ? 0.4 : 0.2;
        final shadowBlur = isHovered ? 12.0 : 6.0;
        final shadowOffset = isHovered ? 4.0 : 2.0;
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: shadowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);

        // Draw shadow with slight offset
        final shadowCenter = Offset(
          adjustedCenter.dx + shadowOffset,
          adjustedCenter.dy + shadowOffset,
        );
        final shadowRect =
            Rect.fromCircle(center: shadowCenter, radius: radius);
        canvas.drawArc(shadowRect, startAngle, sweepAngle, true, shadowPaint);

        // Draw donut segment with fill
        final rect = Rect.fromCircle(center: adjustedCenter, radius: radius);
        final innerRect =
            Rect.fromCircle(center: adjustedCenter, radius: innerR);

        // Create path for donut segment
        final path = Path()
          ..moveTo(
            adjustedCenter.dx + radius * math.cos(startAngle),
            adjustedCenter.dy + radius * math.sin(startAngle),
          )
          ..arcTo(rect, startAngle, sweepAngle, false)
          ..arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false)
          ..close();

        // Draw base fill
        final fillPaint = Paint()
          ..color = colors[i]
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);

        // Create a radial gradient mask for inner edge depth
        final depthGradient = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.black.withValues(alpha: 0.0), // Transparent at outer edge
            Colors.black.withValues(alpha: 0.4), // Darker at inner edge
          ],
          stops: const [0.6, 1.0],
        );

        final depthPaint = Paint()
          ..shader = depthGradient.createShader(rect)
          ..blendMode = BlendMode.multiply;

        // Draw depth gradient
        canvas.drawPath(path, depthPaint);

        // Draw inner edge shadow for depth
        final innerShadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawArc(
            innerRect, startAngle, sweepAngle, false, innerShadowPaint);

        // Draw inner edge highlight
        final innerHighlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(
            innerRect, startAngle, sweepAngle, false, innerHighlightPaint);

        // Draw border for better definition
        final borderPaint = Paint()
          ..color = colors[i].withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(path, borderPaint);

        startAngle += sweepAngle;
      }
    }

    // Center circle for donut effect
    final centerPaint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerPaint);

    // Center circle border
    final centerBorderPaint = Paint()
      ..color = Colors.grey[800]!.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, innerRadius, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _QuizPieChartCustomPainter oldDelegate) {
    return oldDelegate.notStarted != notStarted ||
        oldDelegate.completed != completed ||
        oldDelegate.passed != passed ||
        oldDelegate.failed != failed ||
        oldDelegate.hoveredSegment != hoveredSegment;
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final stepX = chartWidth / (data.length - 1);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw lines for each metric
    _drawLine(
      canvas,
      data.map((d) => d['submissions'] as int).toList(),
      const Color(0xFF60A5FA),
      stepX,
      chartHeight,
      padding,
    );

    _drawLine(
      canvas,
      data.map((d) => d['quizzes'] as int).toList(),
      const Color(0xFF0EA5E9),
      stepX,
      chartHeight,
      padding,
    );

    _drawLine(
      canvas,
      data.map((d) => d['announcements'] as int).toList(),
      const Color(0xFF34D399),
      stepX,
      chartHeight,
      padding,
    );

    // Draw labels
    final textStyle = TextStyle(
      color: Colors.white70,
      fontSize: 10,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < data.length; i++) {
      textPainter.text = TextSpan(
        text: data[i]['date'] as String,
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          padding + stepX * i - textPainter.width / 2,
          size.height - padding + 8,
        ),
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    List<int> values,
    Color color,
    double stepX,
    double chartHeight,
    double padding,
  ) {
    final path = Path();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < values.length; i++) {
      final x = padding + stepX * i;
      final y = padding + chartHeight - (values[i] / maxValue) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}

// Legend Widgets
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TimelineLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _TimelineLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
