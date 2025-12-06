import 'package:flutter/material.dart';
import 'dart:math' as math;

class PieChartWidget extends StatefulWidget {
  final double completed;
  final double pending;
  final String title;
  final Color completedColor;
  final Color pendingColor;
  final double? trendPercent; // Trend percentage vs last month/semester
  final String? trendLabel; // Label for trend (e.g., "vs last month", "vs previous semester")

  const PieChartWidget({
    super.key,
    required this.completed,
    required this.pending,
    required this.title,
    this.completedColor = const Color(0xFF22C55E),
    this.pendingColor = const Color(0xFFFF6B6B),
    this.trendPercent,
    this.trendLabel,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double? _previousCompleted;
  double? _previousPending;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _previousCompleted = widget.completed;
    _previousPending = widget.pending;
    
    // Trigger animation when widget is first created - use multiple callbacks for web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAnimation();
    });
    
    // Additional callback for web compatibility
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_hasAnimated) {
        _triggerAnimation();
      }
    });
  }
  
  void _triggerAnimation() {
    if (mounted) {
      if (_animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
        _hasAnimated = true;
      } else if (_animationController.status == AnimationStatus.completed) {
        // If already completed, ensure it's visible
        setState(() {});
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Được gọi khi hot reload xảy ra - reset và trigger lại animation
    _hasAnimated = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.reset();
        _animationController.forward();
        _hasAnimated = true;
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Trigger animation when app becomes visible
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _animationController.status == AnimationStatus.dismissed) {
          _triggerAnimation();
        }
      });
    }
  }

  @override
  void didUpdateWidget(PieChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu data thay đổi, reset và trigger lại animation
    if (oldWidget.completed != widget.completed || 
        oldWidget.pending != widget.pending) {
      _previousCompleted = widget.completed;
      _previousPending = widget.pending;
      _animationController.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đảm bảo animation được trigger khi widget được hiển thị lại
    // (ví dụ khi navigate đến trang) - chỉ trigger nếu animation chưa chạy
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_animationController.status == AnimationStatus.dismissed) {
          // Nếu animation chưa chạy, trigger nó
          _triggerAnimation();
        } else if (_animationController.status == AnimationStatus.completed && !_hasAnimated) {
          // Nếu animation đã hoàn thành nhưng chưa được đánh dấu, đánh dấu lại
          _hasAnimated = true;
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo animation được trigger nếu chưa chạy
    // Điều này đảm bảo biểu đồ hiển thị ngay cả khi vào trang lần đầu
    if (!_hasAnimated && _animationController.status == AnimationStatus.dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAnimation();
      });
    }
    
    // Normalize input values
    final double completedValue = _safeDouble(widget.completed);
    final double pendingValue = _safeDouble(widget.pending);
    final double total = completedValue + pendingValue;

    final bool hasData = total > 0;

    final double completedPercent = hasData ? (completedValue / total) * 100 : 0.0;
    final double pendingPercent = hasData ? (pendingValue / total) * 100 : 0.0;
    
    // Apply animation - ensure chart is visible even if animation hasn't started
    // On web, animation might not start immediately, so show full values if animation is dismissed
    final double animationValue = _animationController.status == AnimationStatus.dismissed 
        ? 1.0  // Show full chart if animation hasn't started (web compatibility)
        : _animation.value;
    final double animatedCompleted = hasData ? completedValue * animationValue : 0.0;
    final double animatedPending = hasData ? pendingValue * animationValue : 0.0;
    final double animatedCompletedPercent = hasData ? (animatedCompleted / total) * 100 : 0.0;
    final double animatedPendingPercent = hasData ? (animatedPending / total) * 100 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 300;
        final double chartSize = isNarrow ? 180.0 : 220.0;
        // Check if this is assignments chart to adjust legend alignment
        final bool isAssignments = widget.title.toLowerCase().contains('assignment');

        return Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isNarrow ? 320 : 280,
              child: isNarrow
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: chartSize,
                            height: chartSize,
                            child: _PieChartPainter(
                              completed: animatedCompleted,
                              pending: animatedPending,
                              completedColor: widget.completedColor,
                              pendingColor: widget.pendingColor,
                              completedPercent: animatedCompletedPercent,
                              pendingPercent: animatedPendingPercent,
                              title: widget.title,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: _buildLegend(completedValue, pendingValue, hasData ? total : 1.0),
                        ),
                        if (!hasData) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (widget.trendPercent != null) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: _buildTrendIndicator(widget.trendPercent!, widget.trendLabel),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: chartSize,
                                height: chartSize,
                                child: _PieChartPainter(
                                  completed: animatedCompleted,
                                  pending: animatedPending,
                                  completedColor: widget.completedColor,
                                  pendingColor: widget.pendingColor,
                                  completedPercent: animatedCompletedPercent,
                                  pendingPercent: animatedPendingPercent,
                                  title: widget.title,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: isAssignments 
                                    ? Alignment(-0.2, 0) // Lệch về trái một chút cho assignments
                                    : Alignment.centerLeft,
                                child: _buildLegend(completedValue, pendingValue, hasData ? total : 1.0),
                              ),
                              if (!hasData) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'No data available',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (widget.trendPercent != null) ...[
                                const SizedBox(height: 20),
                                _buildTrendIndicator(widget.trendPercent!, widget.trendLabel),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  double _safeDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    return value < 0 ? 0.0 : value;
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildLegend(double completedValue, double pendingValue, double total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendItem(
          color: widget.completedColor,
          label: 'Completed',
        ),
        const SizedBox(height: 18),
        _LegendItem(
          color: widget.pendingColor,
          label: 'Pending',
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(double trendPercent, String? trendLabel) {
    final isPositive = trendPercent >= 0;
    final trendColor = isPositive ? const Color(0xFF22C55E) : const Color(0xFFFF6B6B);
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    final trendText = '${isPositive ? '+' : ''}${trendPercent.toStringAsFixed(0)}%';
    final label = trendLabel ?? 'vs last month';

    // Dùng Wrap để tránh tràn ngang trên màn hình hẹp
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        Icon(trendIcon, size: 14, color: trendColor),
        Text(
          '$trendText $label',
          style: TextStyle(
            fontSize: 11,
            color: trendColor,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
        ),
      ],
    );
  }
}

class _PieChartPainter extends StatefulWidget {
  final double completed;
  final double pending;
  final Color completedColor;
  final Color pendingColor;
  final double completedPercent;
  final double pendingPercent;
  final String title;

  const _PieChartPainter({
    required this.completed,
    required this.pending,
    required this.completedColor,
    required this.pendingColor,
    required this.completedPercent,
    required this.pendingPercent,
    required this.title,
  });

  @override
  State<_PieChartPainter> createState() => _PieChartPainterState();
}

class _PieChartPainterState extends State<_PieChartPainter> {
  String? _hoveredSegment;
  Offset? _hoverPosition;
  final GlobalKey _key = GlobalKey();

  String? _getSegmentAtPosition(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 15;
    
    // Calculate distance from center
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Check if point is within the donut (between inner and outer radius)
    final innerRadius = radius * 0.6;
    if (distance < innerRadius || distance > radius) {
      return null; // Point is outside the donut
    }
    
    // Calculate angle
    var angle = math.atan2(dy, dx);
    // Normalize to 0-2π starting from top (-π/2)
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);
    
    final total = widget.completed + widget.pending;
    if (total <= 0) return null;
    
    final completedAngle = (widget.completed / total) * 2 * math.pi;
    
    // Check which segment
    if (angle <= completedAngle) {
      return 'completed';
    } else {
      return 'pending';
    }
  }

  Widget _buildTooltip() {
    if (_hoveredSegment == null || _hoverPosition == null) {
      return const SizedBox.shrink();
    }

    final total = widget.completed + widget.pending;
    final completedValue = widget.completed;
    final pendingValue = widget.pending;
    final completedPercent = (completedValue / total) * 100;
    final pendingPercent = (pendingValue / total) * 100;

    return Positioned(
      left: _hoverPosition!.dx + 10,
      top: _hoverPosition!.dy - 60,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1F2937),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 180),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _buildTooltipRow(
                'Completed',
                completedValue.toInt(),
                completedPercent,
                widget.completedColor,
              ),
              const SizedBox(height: 4),
              _buildTooltipRow(
                'Pending',
                pendingValue.toInt(),
                pendingPercent,
                widget.pendingColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipRow(String label, int value, double percent, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        Text(
          '$value (${percent.toStringAsFixed(0)}%)',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MouseRegion(
          onHover: (event) {
            final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
            final size = renderBox?.size ?? Size.zero;
            final segment = _getSegmentAtPosition(event.localPosition, size);
            setState(() {
              _hoveredSegment = segment;
              _hoverPosition = event.localPosition;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredSegment = null;
              _hoverPosition = null;
            });
          },
          child: CustomPaint(
            key: _key,
            size: Size.infinite,
            painter: _PieChartCustomPainter(
              completed: widget.completed,
              pending: widget.pending,
              completedColor: widget.completedColor,
              pendingColor: widget.pendingColor,
              completedPercent: widget.completedPercent,
              pendingPercent: widget.pendingPercent,
              hoveredSegment: _hoveredSegment,
            ),
          ),
        ),
        if (_hoveredSegment != null && _hoverPosition != null)
          _buildTooltip(),
      ],
    );
  }
}

class _PieChartCustomPainter extends CustomPainter {
  final double completed;
  final double pending;
  final Color completedColor;
  final Color pendingColor;
  final double completedPercent;
  final double pendingPercent;
  final String? hoveredSegment;

  _PieChartCustomPainter({
    required this.completed,
    required this.pending,
    required this.completedColor,
    required this.pendingColor,
    required this.completedPercent,
    required this.pendingPercent,
    this.hoveredSegment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 15;
    final total = completed + pending;

    if (total <= 0) {
      // Draw empty circle when no data
      final centerPaint = Paint()
        ..color = const Color(0xFF111827).withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.6, centerPaint);
      return;
    }

    // Calculate angles
    final completedAngle = (completed / total) * 2 * math.pi;
    final pendingAngle = (pending / total) * 2 * math.pi;

    // Draw completed section with semi-transparent fill and colored outline
    if (completed > 0) {
      final isHovered = hoveredSegment == 'completed';
      final completedFillPaint = Paint()
        ..color = completedColor.withOpacity(isHovered ? 0.35 : 0.25)
        ..style = PaintingStyle.fill;
      
      final completedOutlinePaint = Paint()
        ..color = completedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 10.0 : 8.0
        ..strokeCap = StrokeCap.round;
      
      final rect = Rect.fromCircle(center: center, radius: radius);
      // Draw fill
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start from top
        completedAngle,
        true,
        completedFillPaint,
      );
      
      // Draw outline on outer edge
      canvas.drawArc(
        rect,
        -math.pi / 2,
        completedAngle,
        false, // Don't connect to center
        completedOutlinePaint,
      );
      
      // Draw outline on inner edge (donut edge) - thinner
      final innerOutlinePaint = Paint()
        ..color = completedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 // Thinner inner edge
        ..strokeCap = StrokeCap.round;
      final innerRect = Rect.fromCircle(center: center, radius: radius * 0.6);
      canvas.drawArc(
        innerRect,
        -math.pi / 2,
        completedAngle,
        false,
        innerOutlinePaint,
      );
    }

    // Draw pending section with semi-transparent fill and colored outline
    if (pending > 0) {
      final isHovered = hoveredSegment == 'pending';
      final pendingFillPaint = Paint()
        ..color = pendingColor.withOpacity(isHovered ? 0.35 : 0.25)
        ..style = PaintingStyle.fill;
      
      final pendingOutlinePaint = Paint()
        ..color = pendingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 10.0 : 8.0
        ..strokeCap = StrokeCap.round;
      
      final startAngle = -math.pi / 2 + completedAngle;
      final rect = Rect.fromCircle(center: center, radius: radius);
      // Draw fill
      canvas.drawArc(
        rect,
        startAngle,
        pendingAngle,
        true,
        pendingFillPaint,
      );
      
      // Draw outline on outer edge
      canvas.drawArc(
        rect,
        startAngle,
        pendingAngle,
        false, // Don't connect to center
        pendingOutlinePaint,
      );
      
      // Draw outline on inner edge (donut edge) - thinner
      final innerOutlinePaint = Paint()
        ..color = pendingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 // Thinner inner edge
        ..strokeCap = StrokeCap.round;
      final innerRect = Rect.fromCircle(center: center, radius: radius * 0.6);
      canvas.drawArc(
        innerRect,
        startAngle,
        pendingAngle,
        false,
        innerOutlinePaint,
      );
    }
    
    // Draw separator line between sections if both exist
    if (completed > 0 && pending > 0) {
      final separatorPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      final startAngle = -math.pi / 2 + completedAngle;
      final startX = center.dx + radius * math.cos(startAngle);
      final startY = center.dy + radius * math.sin(startAngle);
      final endX = center.dx + (radius * 0.6) * math.cos(startAngle);
      final endY = center.dy + (radius * 0.6) * math.sin(startAngle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        separatorPaint,
      );
    }

    // Draw center circle for donut effect with semi-transparent background
    final centerPaint = Paint()
      ..color = const Color(0xFF111827).withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.6, centerPaint);

    // Calculate text position in the middle of each sector
    final textRadius = radius * 0.8; // Position text at 80% of radius
    
    // Draw completed percentage in the completed sector
    if (completed > 0 && completedAngle > 0.1) {
      final completedText = '${completedPercent.toStringAsFixed(0)}%';
      // Calculate middle angle of completed sector
      final completedMiddleAngle = -math.pi / 2 + completedAngle / 2;
      // Calculate position
      final completedTextX = center.dx + textRadius * math.cos(completedMiddleAngle);
      final completedTextY = center.dy + textRadius * math.sin(completedMiddleAngle);
      
      final completedTextPainter = TextPainter(
        text: TextSpan(
          text: completedText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      completedTextPainter.layout(minWidth: 0, maxWidth: double.infinity);
      completedTextPainter.paint(
        canvas,
        Offset(
          completedTextX - (completedTextPainter.width / 2),
          completedTextY - (completedTextPainter.height / 2),
        ),
      );
    }

    // Draw pending percentage in the pending sector
    if (pending > 0 && pendingAngle > 0.1) {
      final pendingText = '${pendingPercent.toStringAsFixed(0)}%';
      // Calculate middle angle of pending sector
      final pendingMiddleAngle = -math.pi / 2 + completedAngle + pendingAngle / 2;
      // Calculate position
      final pendingTextX = center.dx + textRadius * math.cos(pendingMiddleAngle);
      final pendingTextY = center.dy + textRadius * math.sin(pendingMiddleAngle);
      
      final pendingTextPainter = TextPainter(
        text: TextSpan(
          text: pendingText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      pendingTextPainter.layout(minWidth: 0, maxWidth: double.infinity);
      pendingTextPainter.paint(
        canvas,
        Offset(
          pendingTextX - (pendingTextPainter.width / 2),
          pendingTextY - (pendingTextPainter.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartCustomPainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.pending != pending ||
        oldDelegate.completedColor != completedColor ||
        oldDelegate.pendingColor != pendingColor ||
        oldDelegate.hoveredSegment != hoveredSegment;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
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
