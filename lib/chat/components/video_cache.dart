import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCache {
  VideoCache._();

  static final CacheManager _cache = DefaultCacheManager();

  /// Get cached local file for a remote video URL.
  /// Downloads once, reuses thereafter.
  static Future<File> get(String url) async {
    return _cache.getSingleFile(url);
  }

  /// Optional: prefetch in background (e.g., when bubble appears)
  static Future<void> prefetch(String url) async {
    await _cache.downloadFile(url);
  }

  /// Optional: check if already cached
  static Future<File?> getIfCached(String url) async {
    final info = await _cache.getFileFromCache(url);
    return info?.file;
  }
}
