import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme.dart';
import '../models/project_state.dart';

enum _CanvasMode { move, resize }
enum _ResizeHandle { none, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom }

class PreviewPanel extends StatefulWidget {
  const PreviewPanel({super.key});

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  Timer? _playbackTimer;
  _CanvasMode _mode = _CanvasMode.move;

  String _formatTime(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toInt();
    final ms = ((seconds % 1) * 100).toInt();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }

  bool get _isPlaying => _playbackTimer != null;

  void _togglePlayback() {
    final project = context.read<ProjectState>();
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _playbackTimer = null;
    } else {
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final state = project.state;
        final newPos = state.playheadPosition + 0.1;
        if (newPos >= state.totalDuration) {
          _playbackTimer?.cancel();
          _playbackTimer = null;
          project.setPlayheadPosition(0);
        } else {
          project.setPlayheadPosition(newPos);
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectState, ProjectStateData>(
      builder: (context, state) {
        final currentTime = state.playheadPosition;
        final totalTime = state.totalDuration;
        final framePath = state.currentFramePath;
        final isLoading = state.isLoadingFrame;
        final project = context.read<ProjectState>();

        final activeInfo = project.getActiveClip();

        return Container(
          color: EditorColors.primary,
          child: Column(
            children: [
              _buildModeBar(),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasW = constraints.maxWidth;
                        final canvasH = constraints.maxHeight;

                        return Container(
                          decoration: BoxDecoration(
                            color: EditorColors.card,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: EditorColors.borderSubtle),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                if (framePath != null && File(framePath).existsSync() && activeInfo != null)
                                  _CanvasVideo(
                                    framePath: framePath,
                                    clip: activeInfo.clip,
                                    trackIndex: activeInfo.trackIndex,
                                    clipIndex: activeInfo.clipIndex,
                                    canvasWidth: canvasW,
                                    canvasHeight: canvasH,
                                    mode: _mode,
                                  )
                                else if (framePath != null && File(framePath).existsSync())
                                  Positioned.fill(
                                    child: Image.file(
                                      File(framePath),
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  )
                                else
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isLoading ? Icons.hourglass_top : Icons.movie_outlined,
                                          size: 48,
                                          color: EditorColors.textTertiary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isLoading
                                              ? 'Extracting frame...'
                                              : 'Import media and add to timeline',
                                          style: EditorTextStyles.small.copyWith(
                                            color: EditorColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (isLoading && framePath != null)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: EditorColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EditorColors.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: EditorColors.borderSubtle),
                                    ),
                                    child: Text(
                                      '1920 x 1080',
                                      style: EditorTextStyles.tiny,
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(currentTime),
                          style: EditorTextStyles.small.copyWith(
                            color: EditorColors.textPrimary,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          ' / ${_formatTime(totalTime)}',
                          style: EditorTextStyles.small.copyWith(
                            color: EditorColors.textTertiary,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TransportButton(
                          icon: Icons.skip_previous,
                          onTap: () => project.setPlayheadPosition(0),
                        ),
                        const SizedBox(width: 4),
                        _TransportButton(
                          icon: Icons.fast_rewind,
                          onTap: () {
                            project.setPlayheadPosition(
                              (currentTime - 5).clamp(0, totalTime),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _PlayButton(
                          isPlaying: _isPlaying,
                          onTap: _togglePlayback,
                        ),
                        const SizedBox(width: 8),
                        _TransportButton(
                          icon: Icons.fast_forward,
                          onTap: () {
                            project.setPlayheadPosition(
                              (currentTime + 5).clamp(0, totalTime),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _TransportButton(
                          icon: Icons.skip_next,
                          onTap: () => project.setPlayheadPosition(totalTime),
                        ),
                      ],
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

  Widget _buildModeBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: EditorColors.borderSubtle)),
      ),
      child: Row(
        children: [
          _ModeButton(
            icon: Icons.open_with,
            label: 'Move',
            isActive: _mode == _CanvasMode.move,
            onTap: () => setState(() => _mode = _CanvasMode.move),
          ),
          const SizedBox(width: 4),
          _ModeButton(
            icon: Icons.aspect_ratio,
            label: 'Resize',
            isActive: _mode == _CanvasMode.resize,
            onTap: () => setState(() => _mode = _CanvasMode.resize),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isActive
                ? EditorColors.accentBlueBg
                : _hovered
                    ? EditorColors.cardHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isActive
                    ? EditorColors.accentBlue
                    : EditorColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: EditorTextStyles.tiny.copyWith(
                  color: widget.isActive
                      ? EditorColors.accentBlue
                      : EditorColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanvasVideo extends StatefulWidget {
  final String framePath;
  final TimelineClip clip;
  final int trackIndex;
  final int clipIndex;
  final double canvasWidth;
  final double canvasHeight;
  final _CanvasMode mode;

  const _CanvasVideo({
    required this.framePath,
    required this.clip,
    required this.trackIndex,
    required this.clipIndex,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.mode,
  });

  @override
  State<_CanvasVideo> createState() => _CanvasVideoState();
}

class _CanvasVideoState extends State<_CanvasVideo> {
  double get _x => widget.clip.positionX;
  double get _y => widget.clip.positionY;
  double get _sx => widget.clip.scaleX;
  double get _sy => widget.clip.scaleY;
  double get _w => widget.canvasWidth * _sx;
  double get _h => widget.canvasHeight * _sy;

  bool get _isTransformed => _x != 0 || _y != 0 || _sx != 1.0 || _sy != 1.0;

  void _onMoveDrag(DragUpdateDetails d) {
    context.read<ProjectState>().updateClipTransform(
      widget.trackIndex,
      widget.clipIndex,
      positionX: _x + d.delta.dx,
      positionY: _y + d.delta.dy,
    );
  }

  void _onResizeDrag(DragUpdateDetails d, _ResizeHandle handle) {
    final project = context.read<ProjectState>();
    final cW = widget.canvasWidth;
    final cH = widget.canvasHeight;
    final dx = d.delta.dx;
    final dy = d.delta.dy;

    double newX = _x, newY = _y, newSx = _sx, newSy = _sy;

    switch (handle) {
      // Edge handles: free resize in one axis
      case _ResizeHandle.left:
        final newW = (_w - dx).clamp(cW * 0.05, cW * 4.0);
        newSx = newW / cW;
        newX = _x + (_w - newW);
      case _ResizeHandle.right:
        final newW = (_w + dx).clamp(cW * 0.05, cW * 4.0);
        newSx = newW / cW;
      case _ResizeHandle.top:
        final newH = (_h - dy).clamp(cH * 0.05, cH * 4.0);
        newSy = newH / cH;
        newY = _y + (_h - newH);
      case _ResizeHandle.bottom:
        final newH = (_h + dy).clamp(cH * 0.05, cH * 4.0);
        newSy = newH / cH;

      // Corner handles: preserve aspect ratio
      case _ResizeHandle.bottomRight:
        // Use the larger delta to drive the resize
        final aspect = _sx / _sy;
        final newW = (_w + dx).clamp(cW * 0.05, cW * 4.0);
        newSx = newW / cW;
        newSy = newSx / aspect;
      case _ResizeHandle.bottomLeft:
        final aspect = _sx / _sy;
        final newW = (_w - dx).clamp(cW * 0.05, cW * 4.0);
        newSx = newW / cW;
        newSy = newSx / aspect;
        newX = _x + (_w - newW);
      case _ResizeHandle.topRight:
        final aspect = _sx / _sy;
        final newW = (_w + dx).clamp(cW * 0.05, cW * 4.0);
        newSx = newW / cW;
        newSy = newSx / aspect;
        final newH = cH * newSy;
        newY = _y + (_h - newH);
      case _ResizeHandle.topLeft:
        final aspect = _sx / _sy;
        final newW = (_w - dx).clamp(cW * 0.05, cW * 4.0);
        newSx = newW / cW;
        newSy = newSx / aspect;
        final newH = cH * newSy;
        newX = _x + (_w - newW);
        newY = _y + (_h - newH);

      case _ResizeHandle.none:
        return;
    }

    project.updateClipTransform(
      widget.trackIndex,
      widget.clipIndex,
      positionX: newX,
      positionY: newY,
      scaleX: newSx,
      scaleY: newSy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoWidget = Image.file(
      File(widget.framePath),
      fit: BoxFit.fill,
      gaplessPlayback: true,
    );

    if (widget.mode == _CanvasMode.move) {
      return Stack(
        children: [
          Positioned(
            left: _x,
            top: _y,
            width: _w,
            height: _h,
            child: GestureDetector(
              onPanUpdate: _onMoveDrag,
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: videoWidget,
              ),
            ),
          ),
          if (_isTransformed)
            Positioned(
              left: _x,
              top: _y,
              width: _w,
              height: _h,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: EditorColors.accentBlue.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Resize mode
    return Stack(
      children: [
        Positioned(
          left: _x,
          top: _y,
          width: _w,
          height: _h,
          child: videoWidget,
        ),
        // Border
        Positioned(
          left: _x,
          top: _y,
          width: _w,
          height: _h,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
        // Edge handles
        ..._buildEdgeHandles(),
        // Corner handles
        ..._buildCornerHandles(),
      ],
    );
  }

  List<Widget> _buildEdgeHandles() {
    const ht = 16.0; // hit target thickness
    return [
      // Left
      Positioned(
        left: _x - ht / 2,
        top: _y,
        width: ht,
        height: _h,
        child: GestureDetector(
          onPanUpdate: (d) => _onResizeDrag(d, _ResizeHandle.left),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeft,
            child: Center(child: Container(width: 3, height: 32, decoration: _handleDeco())),
          ),
        ),
      ),
      // Right
      Positioned(
        left: _x + _w - ht / 2,
        top: _y,
        width: ht,
        height: _h,
        child: GestureDetector(
          onPanUpdate: (d) => _onResizeDrag(d, _ResizeHandle.right),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeRight,
            child: Center(child: Container(width: 3, height: 32, decoration: _handleDeco())),
          ),
        ),
      ),
      // Top
      Positioned(
        left: _x,
        top: _y - ht / 2,
        width: _w,
        height: ht,
        child: GestureDetector(
          onPanUpdate: (d) => _onResizeDrag(d, _ResizeHandle.top),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUp,
            child: Center(child: Container(width: 32, height: 3, decoration: _handleDeco())),
          ),
        ),
      ),
      // Bottom
      Positioned(
        left: _x,
        top: _y + _h - ht / 2,
        width: _w,
        height: ht,
        child: GestureDetector(
          onPanUpdate: (d) => _onResizeDrag(d, _ResizeHandle.bottom),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeDown,
            child: Center(child: Container(width: 32, height: 3, decoration: _handleDeco())),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildCornerHandles() {
    const area = 20.0;
    const dot = 10.0;

    Widget corner(_ResizeHandle handle, double left, double top, MouseCursor cursor) {
      return Positioned(
        left: left - area / 2,
        top: top - area / 2,
        width: area,
        height: area,
        child: GestureDetector(
          onPanUpdate: (d) => _onResizeDrag(d, handle),
          child: MouseRegion(
            cursor: cursor,
            child: Center(
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return [
      corner(_ResizeHandle.topLeft, _x, _y, SystemMouseCursors.resizeUpLeft),
      corner(_ResizeHandle.topRight, _x + _w, _y, SystemMouseCursors.resizeUpRight),
      corner(_ResizeHandle.bottomLeft, _x, _y + _h, SystemMouseCursors.resizeDownLeft),
      corner(_ResizeHandle.bottomRight, _x + _w, _y + _h, SystemMouseCursors.resizeDownRight),
    ];
  }

  BoxDecoration _handleDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(2),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 2),
      ],
    );
  }
}

class _PlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({required this.isPlaying, required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _TransportButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TransportButton({required this.icon, required this.onTap});

  @override
  State<_TransportButton> createState() => _TransportButtonState();
}

class _TransportButtonState extends State<_TransportButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered ? EditorColors.cardHover : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovered
                ? EditorColors.textPrimary
                : EditorColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
