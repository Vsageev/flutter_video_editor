import 'dart:io';
import 'dart:convert';

class VideoInfo {
  final double duration;
  final int width;
  final int height;

  const VideoInfo({
    required this.duration,
    required this.width,
    required this.height,
  });
}

class FfmpegService {
  static final FfmpegService _instance = FfmpegService._();
  factory FfmpegService() => _instance;
  FfmpegService._();

  Future<VideoInfo> getVideoInfo(String path) async {
    final result = await Process.run('ffprobe', [
      '-v', 'quiet',
      '-print_format', 'json',
      '-show_format',
      '-show_streams',
      path,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ffprobe failed: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final streams = json['streams'] as List<dynamic>;
    final videoStream = streams.firstWhere(
      (s) => s['codec_type'] == 'video',
      orElse: () => null,
    );

    double duration = 0;
    if (json['format'] != null && json['format']['duration'] != null) {
      duration = double.tryParse(json['format']['duration'].toString()) ?? 0;
    }

    int width = 1920;
    int height = 1080;
    if (videoStream != null) {
      width = videoStream['width'] as int? ?? 1920;
      height = videoStream['height'] as int? ?? 1080;
    }

    return VideoInfo(duration: duration, width: width, height: height);
  }

  Future<String> extractFrame(String videoPath, double timeSeconds, String outputPath) async {
    final result = await Process.run('ffmpeg', [
      '-y',
      '-ss', timeSeconds.toStringAsFixed(3),
      '-i', videoPath,
      '-frames:v', '1',
      '-q:v', '2',
      outputPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ffmpeg frame extraction failed: ${result.stderr}');
    }

    return outputPath;
  }

  Future<String> generateThumbnail(String videoPath, String outputPath) async {
    return extractFrame(videoPath, 0.0, outputPath);
  }
}
