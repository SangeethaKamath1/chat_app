import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

Future<XFile?> compressImage(XFile file) async {
  final dir = await getTemporaryDirectory();
  final targetPath = p.join(
    dir.path,
    'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  final result = await FlutterImageCompress.compressAndGetFile(
    file.path,
    targetPath,
    quality: 75,
    minWidth: 1280,
    minHeight: 1280,
    format: CompressFormat.jpeg,
  );

  return result;
}
Future<File?> compressVideo(XFile file) async {
  final info = await VideoCompress.compressVideo(
    file.path,
    quality: VideoQuality.MediumQuality,
    deleteOrigin: false,
    includeAudio: true,
  );

  return info?.file;

}
bool isVideo(XFile file) {
  final mime = lookupMimeType(file.path);
  return mime?.startsWith('video/') ?? false;
}
Future<List<File>> compressMediaFiles(List<XFile> files) async {
  final List<File> result = [];

  for (final file in files) {
    try {
      if (isVideo(file)) {
        final compressedVideo = await compressVideo(file);
        result.add(compressedVideo ?? File(file.path));
      } else {
        final compressedImage = await compressImage(file);
        result.add(
          compressedImage != null
              ? File(compressedImage.path)
              : File(file.path),
        );
      }
    } catch (e) {
      // Fallback to original file if compression fails
      result.add(File(file.path));
    }
  }

  return result;
}
