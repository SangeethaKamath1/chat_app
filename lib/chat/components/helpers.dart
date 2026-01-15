import 'dart:io';

bool isVideo(String url) {
  return url.toLowerCase().endsWith('.mp4') ||
         url.toLowerCase().endsWith('.mov') ||
         url.toLowerCase().endsWith('.avi') ||
         url.toLowerCase().endsWith('.webm');
}
  bool isValidMedia(dynamic path) {
    return path.startsWith('http') || File(path).existsSync();
  }