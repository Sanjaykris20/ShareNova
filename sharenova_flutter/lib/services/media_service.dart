// ignore_for_file: unused_import, avoid_print, use_build_context_synchronously

import 'package:photo_manager/photo_manager.dart';

/// Service to fetch media (photos and videos) from device galleries.
class MediaService {
  /// Request permission and fetch all image assets.
  Future<List<AssetEntity>> getPhotos() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) return [];
    // Load only image type assets.
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return [];
    return await albums.first.getAssetListPaged(page: 0, size: 100);
  }

  /// Request permission and fetch all video assets.
  Future<List<AssetEntity>> getVideos() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) return [];
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );
    if (albums.isEmpty) return [];
    return await albums.first.getAssetListPaged(page: 0, size: 50);
  }
}
