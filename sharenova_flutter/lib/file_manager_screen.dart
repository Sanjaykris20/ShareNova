// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import 'share_state.dart';
import 'mock_data.dart';
import '../services/app_service.dart';
import '../services/contact_service.dart';
import '../services/media_service.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Apps', 'Contacts', 'Photos', 'Files', 'Videos'];
  bool _showSecurityOptions = false;
  
  bool _isLoading = true;
  List<Application> _apps = [];
  List<Contact> _contacts = [];
  List<AssetEntity> _photos = [];
  List<AssetEntity> _videos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadRealData();
  }
  
  Future<void> _loadRealData() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final appService = AppService();
      final contactService = ContactService();
      final mediaService = MediaService();

      final results = await Future.wait([
        appService.getInstalledApps(),
        contactService.getContacts(),
        mediaService.getPhotos(),
        mediaService.getVideos(),
      ]);

      if (mounted) {
        setState(() {
          _apps = results[0] as List<Application>;
          _contacts = results[1] as List<Contact>;
          _photos = results[2] as List<AssetEntity>;
          _videos = results[3] as List<AssetEntity>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading real data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateGroup(DateTime? date) {
    if (date == null) return "Unknown Date";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) return "Today";
    if (targetDate == yesterday) return "Yesterday";
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFF111827)),
          onPressed: () => state.navigateTo('home'),
        ),
        title: const Text(
          "Select Content",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: Color(0xFF4B5563)),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppsTab(state),
                    _buildContactsTab(state),
                    _buildPhotosTab(state),
                    _buildFilesTab(state),
                    _buildVideosTab(state),
                  ],
                ),

          // Selection Action Footer
          if (state.selectedContentIds.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFF3F4F6)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Selected: ${state.selectedContentIds.length}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 10,
                        shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      ),
                      onPressed: () {
                        setState(() {
                          _showSecurityOptions = true;
                        });
                      },
                      child: Row(
                        children: const [
                          Text(
                            "Next",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrow_right, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Security Drawer Overlay
          if (_showSecurityOptions) _buildSecurityDrawer(state),
        ],
      ),
    );
  }

  Widget _buildAppsTab(ShareState state) {
    if (_apps.isEmpty) {
      return const Center(child: Text("No apps found", style: TextStyle(color: Colors.grey)));
    }
    
    // Group apps by date
    final Map<String, List<Application>> groupedApps = {};
    for (var app in _apps) {
      final date = DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis);
      final group = _formatDateGroup(date);
      if (!groupedApps.containsKey(group)) {
        groupedApps[group] = [];
      }
      groupedApps[group]!.add(app);
    }

    final groups = groupedApps.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: CustomScrollView(
        slivers: groups.expand((entry) {
          final dateHeader = entry.key;
          final appsInGroup = entry.value;
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Text(
                  dateHeader,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4B5563), letterSpacing: 1),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = appsInGroup[index];
                  final id = "app_${app.packageName}";
                  final isSelected = state.selectedContentIds.contains(id);

                  return GestureDetector(
                    onTap: () => state.toggleSelectContent(id, app),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF3F4F6)),
                                image: app is ApplicationWithIcon
                                    ? DecorationImage(
                                        image: MemoryImage(app.icon),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: app is! ApplicationWithIcon ? Colors.grey[200] : null,
                              ),
                              child: app is! ApplicationWithIcon 
                                  ? const Icon(LucideIcons.app_window, color: Colors.grey) 
                                  : null,
                            ),
                            if (isSelected)
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.black.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: isSelected
                                    ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.appName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
                childCount: appsInGroup.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ];
        }).toList(),
      ),
    );
  }

  Widget _buildContactsTab(ShareState state) {
    if (_contacts.isEmpty) {
      return const Center(child: Text("No contacts found", style: TextStyle(color: Colors.grey)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final id = "contact_${contact.id}";
        final isSelected = state.selectedContentIds.contains(id);
        
        final name = contact.displayName;
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : "No number";
        final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

        return GestureDetector(
          onTap: () => state.toggleSelectContent(id, contact),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFF3F4F6),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE5E7EB),
                  backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
                  child: contact.photo == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF4B5563),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab(ShareState state) {
    if (_photos.isEmpty) {
      return const Center(child: Text("No photos found", style: TextStyle(color: Colors.grey)));
    }
    
    // Group photos by date
    final Map<String, List<AssetEntity>> groupedPhotos = {};
    for (var photo in _photos) {
      final date = photo.createDateTime;
      final group = _formatDateGroup(date);
      if (!groupedPhotos.containsKey(group)) {
        groupedPhotos[group] = [];
      }
      groupedPhotos[group]!.add(photo);
    }

    final groups = groupedPhotos.entries.toList();

    return Scrollbar(
      interactive: true,
      thickness: 8,
      radius: const Radius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CustomScrollView(
          slivers: groups.expand((entry) {
            final dateHeader = entry.key;
            final photosInGroup = entry.value;
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  child: Text(
                    dateHeader,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4B5563), letterSpacing: 1),
                  ),
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final photo = photosInGroup[index];
                    final id = "photo_${photo.id}";
                    final isSelected = state.selectedContentIds.contains(id);

                    return GestureDetector(
                      onTap: () => state.toggleSelectContent(id, photo),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FutureBuilder<Uint8List?>(
                              future: photo.thumbnailData,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                }
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return Container(color: Colors.grey[200]);
                              },
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.black.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: isSelected
                                    ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: photosInGroup.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ];
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickRealFiles(ShareState state) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final files = result.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
        state.addPickedFiles(files);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files: $e")),
      );
    }
  }

  Widget _buildFilesTab(ShareState state) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Pick Real File Action Card
        GestureDetector(
          onTap: () => _pickRealFiles(state),
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.file_up, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Pick Files from Device",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Select actual photos, videos, or documents",
                        style: TextStyle(fontSize: 12, color: Color(0xFFBFDBFE)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),

        // Picked Real Files Section
        if (state.pickedFiles.isNotEmpty) ...[
          const Text(
            "REAL FILES PICKED",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563), letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          ...state.pickedFiles.map((file) {
            final basename = file.uri.pathSegments.last;
            final id = "picked_$basename";
            final isSelected = state.selectedContentIds.contains(id);

            // Format size
            int sizeBytes = 0;
            try { sizeBytes = file.lengthSync(); } catch (_) {}
            
            String sizeStr = "${(sizeBytes / 1024).toStringAsFixed(1)} KB";
            if (sizeBytes > 1024 * 1024) {
              sizeStr = "${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB";
            }

            return GestureDetector(
              onTap: () => state.toggleSelectContent(id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFEFF6FF),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.file_check, color: Color(0xFF10B981), size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            basename,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sizeStr,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash_2, color: Colors.red, size: 20),
                      onPressed: () => state.removePickedFile(file),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Mock Files Section
        const Text(
          "RECENT FILES",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563), letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        ...MockData.recentTransfers.map((item) {
          final id = "f${item.id}";
          final isSelected = state.selectedContentIds.contains(id);

          return GestureDetector(
            onTap: () => state.toggleSelectContent(id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFF3F4F6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.file_text, color: Color(0xFF3B82F6), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.size,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVideosTab(ShareState state) {
    if (_videos.isEmpty) {
      return const Center(child: Text("No videos found", style: TextStyle(color: Colors.grey)));
    }
    
    // Group videos by date
    final Map<String, List<AssetEntity>> groupedVideos = {};
    for (var video in _videos) {
      final date = video.createDateTime;
      final group = _formatDateGroup(date);
      if (!groupedVideos.containsKey(group)) {
        groupedVideos[group] = [];
      }
      groupedVideos[group]!.add(video);
    }

    final groups = groupedVideos.entries.toList();

    return Scrollbar(
      interactive: true,
      thickness: 8,
      radius: const Radius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CustomScrollView(
          slivers: groups.expand((entry) {
            final dateHeader = entry.key;
            final videosInGroup = entry.value;
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  child: Text(
                    dateHeader,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4B5563), letterSpacing: 1),
                  ),
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = videosInGroup[index];
                    final id = "video_${video.id}";
                    final isSelected = state.selectedContentIds.contains(id);

                    return GestureDetector(
                      onTap: () => state.toggleSelectContent(id, video),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FutureBuilder<Uint8List?>(
                              future: video.thumbnailData,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                }
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return Container(color: Colors.grey[200]);
                              },
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.2),
                              child: const Center(
                                child: Icon(LucideIcons.video, color: Colors.white, size: 24),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.black.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: isSelected
                                    ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: videosInGroup.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ];
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSecurityDrawer(ShareState state) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSecurityOptions = false;
        });
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.2),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent tap propagation
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.shield_check, color: Color(0xFF10B981), size: 24),
                          SizedBox(width: 8),
                          Text(
                            "Security & Rules",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          setState(() {
                            _showSecurityOptions = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const Text(
                    "These rules travel encrypted with the file.",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(LucideIcons.timer, color: Color(0xFF2563EB), size: 16),
                            SizedBox(width: 8),
                            Text(
                              "Auto-Destruct Rule",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Receiver's app will delete the data upon trigger.",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: ['Never', '1 View', '24 Hours', '7 Days'].map((opt) {
                            final selected = state.destructRule == opt;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: selected ? const Color(0xFF2563EB) : Colors.white,
                                    foregroundColor: selected ? Colors.white : const Color(0xFF4B5563),
                                    elevation: selected ? 4 : 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: selected ? Colors.transparent : const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => state.setDestructRule(opt),
                                  child: Text(opt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.lock, color: Color(0xFF065F46), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "ECDH Ready",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Awaiting nearby peer to generate keys...",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.circle_check, color: Color(0xFF10B981), size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSecurityOptions = false;
                      });
                      state.navigateTo('device_discovery');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.radio, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Scan Nearby Devices",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
