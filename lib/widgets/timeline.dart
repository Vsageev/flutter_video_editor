import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme.dart';
import '../models/project_state.dart';

class Timeline extends StatefulWidget {
  const Timeline({super.key});

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  final double _pixelsPerSecond = 30.0;
  final double _trackHeaderWidth = 140.0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectState, ProjectStateData>(
      builder: (context, state) {
        final tracks = state.tracks;
        final totalDuration = state.totalDuration;
        final playheadPosition = state.playheadPosition;
        final project = context.read<ProjectState>();

        return Container(
          decoration: const BoxDecoration(
            color: EditorColors.secondary,
            border: Border(
              top: BorderSide(color: EditorColors.borderSubtle),
            ),
          ),
          child: Column(
            children: [
              _buildTimelineToolbar(project),
              const Divider(height: 1, color: EditorColors.borderSubtle),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: _trackHeaderWidth,
                      child: Column(
                        children: [
                          Container(
                            height: 28,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: EditorColors.borderSubtle),
                                right: BorderSide(color: EditorColors.borderSubtle),
                              ),
                            ),
                          ),
                          ...tracks.asMap().entries.map((e) => _TrackHeader(
                                track: e.value,
                                trackIndex: e.key,
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (details) {
                          final localX = details.localPosition.dx;
                          final time = localX / _pixelsPerSecond;
                          project.setPlayheadPosition(time);
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalDuration * _pixelsPerSecond,
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    _buildRuler(totalDuration),
                                    ...tracks.asMap().entries.map((e) =>
                                        _buildTrackRow(e.key, e.value, state)),
                                  ],
                                ),
                                Positioned(
                                  left: playheadPosition * _pixelsPerSecond,
                                  top: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: (d) {
                                      final newPos = playheadPosition +
                                          d.delta.dx / _pixelsPerSecond;
                                      project.setPlayheadPosition(newPos);
                                    },
                                    child: SizedBox(
                                      width: 16,
                                      child: Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: const BorderRadius.vertical(
                                                bottom: Radius.circular(3),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.4),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 18,
                                            bottom: 0,
                                            child: Container(
                                              width: 1.5,
                                              color: Colors.white.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineToolbar(ProjectState project) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('TIMELINE', style: EditorTextStyles.label.copyWith(fontSize: 11)),
          const Spacer(),
          _TimelineToolButton(
            icon: Icons.add,
            tooltip: 'Add Track',
            onTap: () => project.addTrack(),
          ),
          _TimelineToolButton(
            icon: Icons.remove,
            tooltip: 'Remove Track',
            onTap: () => project.removeTrack(),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: EditorColors.borderSubtle,
          ),
          const SizedBox(width: 8),
          _TimelineToolButton(
            icon: Icons.zoom_out,
            tooltip: 'Zoom Out',
            onTap: () {},
          ),
          _TimelineToolButton(
            icon: Icons.zoom_in,
            tooltip: 'Zoom In',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _TimelineToolButton(
            icon: Icons.grid_on_outlined,
            tooltip: 'Snap to Grid',
            onTap: () {},
            isActive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRuler(double totalDuration) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EditorColors.borderSubtle),
        ),
      ),
      child: CustomPaint(
        painter: _RulerPainter(
          pixelsPerSecond: _pixelsPerSecond,
          totalDuration: totalDuration,
        ),
        size: Size(totalDuration * _pixelsPerSecond, 28),
      ),
    );
  }

  Widget _buildTrackRow(int trackIndex, TimelineTrack track, ProjectStateData state) {
    final project = context.read<ProjectState>();
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: EditorColors.borderSubtle),
        ),
      ),
      child: Stack(
        children: track.clips.asMap().entries.map((e) {
          final clip = e.value;
          final clipIndex = e.key;
          final isSelected =
              state.selectedClipTrack == trackIndex &&
              state.selectedClipIndex == clipIndex;
          final clipWidth = clip.duration * _pixelsPerSecond;

          return Positioned(
            left: clip.start * _pixelsPerSecond,
            top: 4,
            child: GestureDetector(
              onTap: () {
                project.selectClip(trackIndex, clipIndex);
              },
              child: _ClipWidget(
                clip: clip,
                width: clipWidth,
                isSelected: isSelected,
                isMuted: track.isMuted,
                pixelsPerSecond: _pixelsPerSecond,
                onTrimStart: (deltaPx) {
                  final deltaSec = deltaPx / _pixelsPerSecond;
                  project.trimClipStart(trackIndex, clipIndex, deltaSec);
                },
                onTrimEnd: (deltaPx) {
                  final deltaSec = deltaPx / _pixelsPerSecond;
                  project.trimClipEnd(trackIndex, clipIndex, deltaSec);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TrackHeader extends StatefulWidget {
  final TimelineTrack track;
  final int trackIndex;

  const _TrackHeader({
    required this.track,
    required this.trackIndex,
  });

  @override
  State<_TrackHeader> createState() => _TrackHeaderState();
}

class _TrackHeaderState extends State<_TrackHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final project = context.read<ProjectState>();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _hovered ? EditorColors.card : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: EditorColors.borderSubtle),
            right: BorderSide(color: EditorColors.borderSubtle),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(widget.track.icon, size: 15, color: EditorColors.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.track.label,
                style: EditorTextStyles.small.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hovered) ...[
              GestureDetector(
                onTap: () => project.toggleTrackMute(widget.trackIndex),
                child: _MiniButton(
                  icon: widget.track.isMuted
                      ? Icons.volume_off
                      : Icons.volume_up_outlined,
                  isActive: widget.track.isMuted,
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: () => project.toggleTrackLock(widget.trackIndex),
                child: _MiniButton(
                  icon: widget.track.isLocked
                      ? Icons.lock_outlined
                      : Icons.lock_open_outlined,
                  isActive: widget.track.isLocked,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _MiniButton({required this.icon, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Icon(
        icon,
        size: 13,
        color: isActive ? EditorColors.accentYellow : EditorColors.textTertiary,
      ),
    );
  }
}

class _ClipWidget extends StatefulWidget {
  final TimelineClip clip;
  final double width;
  final bool isSelected;
  final bool isMuted;
  final double pixelsPerSecond;
  final ValueChanged<double> onTrimStart;
  final ValueChanged<double> onTrimEnd;

  const _ClipWidget({
    required this.clip,
    required this.width,
    required this.isSelected,
    required this.isMuted,
    required this.pixelsPerSecond,
    required this.onTrimStart,
    required this.onTrimEnd,
  });

  @override
  State<_ClipWidget> createState() => _ClipWidgetState();
}

class _ClipWidgetState extends State<_ClipWidget> {
  bool _hovered = false;
  bool _trimHoveredLeft = false;
  bool _trimHoveredRight = false;
  bool _isDraggingLeft = false;
  bool _isDraggingRight = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.clip.color.withValues(alpha: widget.isMuted ? 0.08 : 0.15);
    final borderColor = widget.isSelected
        ? widget.clip.color.withValues(alpha: 0.6)
        : _hovered
            ? widget.clip.color.withValues(alpha: 0.3)
            : widget.clip.color.withValues(alpha: 0.15);

    const trimHandleWidth = 7.0;
    final showHandles = _hovered || widget.isSelected || _isDraggingLeft || _isDraggingRight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: widget.width,
        height: 40,
        child: Stack(
          children: [
            // Main clip body
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: widget.isSelected ? 1.5 : 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(
                    widget.clip.icon,
                    size: 13,
                    color: widget.clip.color.withValues(alpha: widget.isMuted ? 0.4 : 0.8),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      widget.clip.name,
                      style: EditorTextStyles.tiny.copyWith(
                        color: widget.clip.color.withValues(alpha: widget.isMuted ? 0.4 : 0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Left trim handle
            if (showHandles)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  onEnter: (_) => setState(() => _trimHoveredLeft = true),
                  onExit: (_) => setState(() => _trimHoveredLeft = false),
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => setState(() => _isDraggingLeft = true),
                    onHorizontalDragUpdate: (d) => widget.onTrimStart(d.delta.dx),
                    onHorizontalDragEnd: (_) => setState(() => _isDraggingLeft = false),
                    child: Container(
                      width: trimHandleWidth,
                      decoration: BoxDecoration(
                        color: (_trimHoveredLeft || _isDraggingLeft)
                            ? widget.clip.color.withValues(alpha: 0.8)
                            : widget.clip.color.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                      ),
                      child: Center(
                        child: Container(
                          width: 2,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Right trim handle
            if (showHandles)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  onEnter: (_) => setState(() => _trimHoveredRight = true),
                  onExit: (_) => setState(() => _trimHoveredRight = false),
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => setState(() => _isDraggingRight = true),
                    onHorizontalDragUpdate: (d) => widget.onTrimEnd(d.delta.dx),
                    onHorizontalDragEnd: (_) => setState(() => _isDraggingRight = false),
                    child: Container(
                      width: trimHandleWidth,
                      decoration: BoxDecoration(
                        color: (_trimHoveredRight || _isDraggingRight)
                            ? widget.clip.color.withValues(alpha: 0.8)
                            : widget.clip.color.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                      ),
                      child: Center(
                        child: Container(
                          width: 2,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineToolButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _TimelineToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_TimelineToolButton> createState() => _TimelineToolButtonState();
}

class _TimelineToolButtonState extends State<_TimelineToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? EditorColors.accentBlueBg
                  : _hovered
                      ? EditorColors.cardHover
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.isActive
                  ? EditorColors.accentBlue
                  : _hovered
                      ? EditorColors.textPrimary
                      : EditorColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double pixelsPerSecond;
  final double totalDuration;

  _RulerPainter({
    required this.pixelsPerSecond,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EditorColors.borderSubtle
      ..strokeWidth = 1;

    final textStyle = EditorTextStyles.tiny.copyWith(fontSize: 10);

    for (int s = 0; s <= totalDuration.toInt(); s++) {
      final x = s * pixelsPerSecond;
      final isMajor = s % 5 == 0;

      canvas.drawLine(
        Offset(x, isMajor ? 10 : 18),
        Offset(x, 28),
        paint,
      );

      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}',
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 3, 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
