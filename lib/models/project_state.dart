import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/ffmpeg_service.dart';
import '../theme.dart';

class MediaFile {
  final String id;
  final String name;
  final String path;
  final double duration;
  final int width;
  final int height;
  String? thumbnailPath;

  MediaFile({
    required this.id,
    required this.name,
    required this.path,
    required this.duration,
    required this.width,
    required this.height,
    this.thumbnailPath,
  });
}

class TimelineClip {
  final String id;
  final String mediaId;
  final String name;
  final double start;
  final double duration;
  final double mediaOffset;
  final Color color;
  final IconData icon;

  // Canvas transform
  final double positionX;
  final double positionY;
  final double scaleX; // 1.0 = full canvas width
  final double scaleY; // 1.0 = full canvas height

  const TimelineClip({
    required this.id,
    required this.mediaId,
    required this.name,
    required this.start,
    required this.duration,
    this.mediaOffset = 0,
    required this.color,
    required this.icon,
    this.positionX = 0,
    this.positionY = 0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
  });

  TimelineClip copyWith({
    double? start,
    double? duration,
    double? mediaOffset,
    double? positionX,
    double? positionY,
    double? scaleX,
    double? scaleY,
  }) {
    return TimelineClip(
      id: id,
      mediaId: mediaId,
      name: name,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      mediaOffset: mediaOffset ?? this.mediaOffset,
      color: color,
      icon: icon,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
    );
  }
}

class TimelineTrack {
  final String label;
  final IconData icon;
  final List<TimelineClip> clips;
  bool isMuted;
  bool isLocked;

  TimelineTrack({
    required this.label,
    required this.icon,
    List<TimelineClip>? clips,
    this.isMuted = false,
    this.isLocked = false,
  }) : clips = clips ?? [];
}

class ProjectStateData {
  final List<MediaFile> mediaFiles;
  final List<TimelineTrack> tracks;
  final double playheadPosition;
  final int? selectedClipTrack;
  final int? selectedClipIndex;
  final String? currentFramePath;
  final bool isLoadingFrame;

  const ProjectStateData({
    this.mediaFiles = const [],
    this.tracks = const [],
    this.playheadPosition = 0,
    this.selectedClipTrack,
    this.selectedClipIndex,
    this.currentFramePath,
    this.isLoadingFrame = false,
  });

  double get totalDuration {
    double maxEnd = 10;
    for (final track in tracks) {
      for (final clip in track.clips) {
        final end = clip.start + clip.duration;
        if (end > maxEnd) maxEnd = end;
      }
    }
    return maxEnd + 5;
  }

  ProjectStateData copyWith({
    List<MediaFile>? mediaFiles,
    List<TimelineTrack>? tracks,
    double? playheadPosition,
    int? Function()? selectedClipTrack,
    int? Function()? selectedClipIndex,
    String? Function()? currentFramePath,
    bool? isLoadingFrame,
  }) {
    return ProjectStateData(
      mediaFiles: mediaFiles ?? this.mediaFiles,
      tracks: tracks ?? this.tracks,
      playheadPosition: playheadPosition ?? this.playheadPosition,
      selectedClipTrack: selectedClipTrack != null ? selectedClipTrack() : this.selectedClipTrack,
      selectedClipIndex: selectedClipIndex != null ? selectedClipIndex() : this.selectedClipIndex,
      currentFramePath: currentFramePath != null ? currentFramePath() : this.currentFramePath,
      isLoadingFrame: isLoadingFrame ?? this.isLoadingFrame,
    );
  }
}

class ProjectState extends Cubit<ProjectStateData> {
  final FfmpegService _ffmpeg = FfmpegService();
  int _clipIdCounter = 0;
  int _mediaIdCounter = 0;
  String? _lastFrameKey;
  late Directory _tempDir;

  // Mutable backing lists that we expose via state snapshots
  final List<MediaFile> _mediaFiles = [];
  final List<TimelineTrack> _tracks = [
    TimelineTrack(label: 'Video 1', icon: Icons.videocam_outlined),
  ];

  ProjectState() : super(ProjectStateData(
    tracks: [TimelineTrack(label: 'Video 1', icon: Icons.videocam_outlined)],
  ));

  Future<void> init() async {
    _tempDir = await Directory.systemTemp.createTemp('editor2_');
  }

  void _emitState({
    double? playheadPosition,
    int? Function()? selectedClipTrack,
    int? Function()? selectedClipIndex,
    String? Function()? currentFramePath,
    bool? isLoadingFrame,
  }) {
    emit(state.copyWith(
      mediaFiles: List<MediaFile>.from(_mediaFiles),
      tracks: List<TimelineTrack>.from(_tracks),
      playheadPosition: playheadPosition,
      selectedClipTrack: selectedClipTrack,
      selectedClipIndex: selectedClipIndex,
      currentFramePath: currentFramePath,
      isLoadingFrame: isLoadingFrame,
    ));
  }

  Future<void> importMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (file.path == null) continue;

      try {
        final info = await _ffmpeg.getVideoInfo(file.path!);
        final id = 'media_${_mediaIdCounter++}';
        final thumbPath = '${_tempDir.path}/thumb_$id.jpg';

        final media = MediaFile(
          id: id,
          name: file.name,
          path: file.path!,
          duration: info.duration,
          width: info.width,
          height: info.height,
        );

        try {
          await _ffmpeg.generateThumbnail(file.path!, thumbPath);
          media.thumbnailPath = thumbPath;
        } catch (_) {}

        _mediaFiles.add(media);
      } catch (e) {
        debugPrint('Failed to import ${file.name}: $e');
      }
    }

    _emitState();
  }

  void addToTimeline(MediaFile media, {int? trackIndex}) {
    final ti = trackIndex ?? 0;

    while (_tracks.length <= ti) {
      _tracks.add(TimelineTrack(
        label: 'Video ${_tracks.length + 1}',
        icon: Icons.videocam_outlined,
      ));
    }

    final track = _tracks[ti];

    double insertAt = 0;
    for (final clip in track.clips) {
      final end = clip.start + clip.duration;
      if (end > insertAt) insertAt = end;
    }

    final colors = [
      EditorColors.accentPurple,
      EditorColors.accentBlue,
      EditorColors.accentGreen,
      EditorColors.accentYellow,
    ];

    track.clips.add(TimelineClip(
      id: 'clip_${_clipIdCounter++}',
      mediaId: media.id,
      name: media.name,
      start: insertAt,
      duration: media.duration,
      color: colors[track.clips.length % colors.length],
      icon: Icons.movie_outlined,
    ));

    _emitState();
    _extractFrameAtPlayhead();
  }

  void setPlayheadPosition(double position) {
    final clamped = position.clamp(0.0, state.totalDuration);
    _emitState(playheadPosition: clamped);
    _extractFrameAtPlayhead();
  }

  void selectClip(int? trackIndex, int? clipIndex) {
    _emitState(
      selectedClipTrack: () => trackIndex,
      selectedClipIndex: () => clipIndex,
    );
  }

  void toggleTrackMute(int trackIndex) {
    if (trackIndex < _tracks.length) {
      _tracks[trackIndex].isMuted = !_tracks[trackIndex].isMuted;
      _emitState();
    }
  }

  void toggleTrackLock(int trackIndex) {
    if (trackIndex < _tracks.length) {
      _tracks[trackIndex].isLocked = !_tracks[trackIndex].isLocked;
      _emitState();
    }
  }

  void updateClipTransform(int trackIndex, int clipIndex, {
    double? positionX,
    double? positionY,
    double? scaleX,
    double? scaleY,
  }) {
    if (trackIndex >= _tracks.length) return;
    final track = _tracks[trackIndex];
    if (clipIndex >= track.clips.length) return;
    track.clips[clipIndex] = track.clips[clipIndex].copyWith(
      positionX: positionX,
      positionY: positionY,
      scaleX: scaleX,
      scaleY: scaleY,
    );
    _emitState();
  }

  void trimClipStart(int trackIndex, int clipIndex, double deltaSec) {
    if (trackIndex >= _tracks.length) return;
    final track = _tracks[trackIndex];
    if (clipIndex >= track.clips.length) return;
    final clip = track.clips[clipIndex];

    final media = _mediaFiles.firstWhere((m) => m.id == clip.mediaId);
    final maxTrim = clip.duration - 0.1; // keep at least 0.1s
    final clampedDelta = deltaSec.clamp(-clip.mediaOffset, maxTrim);

    final newStart = clip.start + clampedDelta;
    final newDuration = clip.duration - clampedDelta;
    final newMediaOffset = clip.mediaOffset + clampedDelta;

    if (newStart < 0 || newDuration < 0.1 || newMediaOffset < 0) return;
    if (newMediaOffset > media.duration - 0.1) return;

    track.clips[clipIndex] = clip.copyWith(
      start: newStart,
      duration: newDuration,
      mediaOffset: newMediaOffset,
    );
    _emitState();
  }

  void trimClipEnd(int trackIndex, int clipIndex, double deltaSec) {
    if (trackIndex >= _tracks.length) return;
    final track = _tracks[trackIndex];
    if (clipIndex >= track.clips.length) return;
    final clip = track.clips[clipIndex];

    final media = _mediaFiles.firstWhere((m) => m.id == clip.mediaId);
    final maxDuration = media.duration - clip.mediaOffset;
    final newDuration = (clip.duration + deltaSec).clamp(0.1, maxDuration);

    track.clips[clipIndex] = clip.copyWith(duration: newDuration);
    _emitState();
  }

  /// Returns the clip and its indices at the current playhead position
  ({TimelineClip clip, int trackIndex, int clipIndex})? getActiveClip() {
    for (int ti = 0; ti < _tracks.length; ti++) {
      final track = _tracks[ti];
      if (track.isMuted) continue;
      for (int ci = 0; ci < track.clips.length; ci++) {
        final clip = track.clips[ci];
        if (state.playheadPosition >= clip.start &&
            state.playheadPosition < clip.start + clip.duration) {
          return (clip: clip, trackIndex: ti, clipIndex: ci);
        }
      }
    }
    return null;
  }

  void addTrack() {
    _tracks.add(TimelineTrack(
      label: 'Video ${_tracks.length + 1}',
      icon: Icons.videocam_outlined,
    ));
    _emitState();
  }

  void removeTrack() {
    if (_tracks.length > 1) {
      _tracks.removeLast();
      _emitState();
    }
  }

  Future<void> _extractFrameAtPlayhead() async {
    TimelineClip? activeClip;
    MediaFile? activeMedia;

    for (final track in _tracks) {
      if (track.isMuted) continue;
      for (final clip in track.clips) {
        if (state.playheadPosition >= clip.start &&
            state.playheadPosition < clip.start + clip.duration) {
          activeClip = clip;
          break;
        }
      }
      if (activeClip != null) break;
    }

    if (activeClip == null) {
      if (state.currentFramePath != null) {
        _emitState(currentFramePath: () => null);
      }
      return;
    }

    try {
      activeMedia = _mediaFiles.firstWhere((m) => m.id == activeClip!.mediaId);
    } catch (_) {
      return;
    }

    final timeInClip = state.playheadPosition - activeClip.start + activeClip.mediaOffset;
    final roundedTime = (timeInClip * 10).round() / 10;
    final frameKey = '${activeMedia.id}_$roundedTime';

    if (frameKey == _lastFrameKey) return;
    _lastFrameKey = frameKey;

    final framePath = '${_tempDir.path}/frame_${activeMedia.id}_$roundedTime.jpg';

    if (await File(framePath).exists()) {
      _emitState(currentFramePath: () => framePath);
      return;
    }

    _emitState(isLoadingFrame: true);

    try {
      await _ffmpeg.extractFrame(activeMedia.path, roundedTime, framePath);
      _emitState(currentFramePath: () => framePath, isLoadingFrame: false);
    } catch (e) {
      debugPrint('Frame extraction failed: $e');
      _emitState(isLoadingFrame: false);
    }
  }

  @override
  Future<void> close() async {
    try {
      _tempDir.deleteSync(recursive: true);
    } catch (_) {}
    return super.close();
  }
}
