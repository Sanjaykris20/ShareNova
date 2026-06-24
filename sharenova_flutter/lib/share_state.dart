// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'services/p2p_service.dart';
import 'models/nearby_user.dart';
import 'mock_data.dart';
import 'room_service.dart';

class ShareState extends ChangeNotifier {
  // P2P session handling
  P2pSession? _currentSession;
  P2pSession? get currentSession => _currentSession;

  void setCurrentSession(P2pSession session) {
    _currentSession = session;
    notifyListeners();
  }

  // Navigation Helper
  String _currentRoute = 'splash';
  String get currentRoute => _currentRoute;

  Map<String, dynamic>? _routeArguments;
  Map<String, dynamic>? get routeArguments => _routeArguments;

  int _currentTab = 0;
  int get currentTab => _currentTab;

  String _previousRoute = 'home';
  String get previousRoute => _previousRoute;

  void navigateTo(String route, {Map<String, dynamic>? arguments}) {
    if (route == 'profile') {
      setTab(4);
    } else if (route == 'room_gateway') {
      setTab(3);
    } else {
      if (route != _currentRoute) {
        _previousRoute = _currentRoute;
      }
      _currentRoute = route;
      _routeArguments = arguments;
      notifyListeners();
    }
  }

  void goBack() {
    navigateTo(_previousRoute);
  }

  void setTab(int index) {
    _currentTab = index;
    _currentRoute = 'home'; // Reset root navigator to home shell
    notifyListeners();
  }

  // File Selector State
  final List<dynamic> _selectedContentIds = [];
  List<dynamic> get selectedContentIds => _selectedContentIds;
  
  final Map<String, dynamic> _selectedObjects = {};

  final List<File> _pickedFiles = [];
  List<File> get pickedFiles => List.unmodifiable(_pickedFiles);

  void addPickedFiles(List<File> files) {
    for (var file in files) {
      if (!_pickedFiles.any((f) => f.path == file.path)) {
        _pickedFiles.add(file);
        _selectedContentIds.add("file_${file.path}");
      }
    }
    notifyListeners();
  }

  void removePickedFile(File file) {
    _pickedFiles.removeWhere((f) => f.path == file.path);
    _selectedContentIds.remove("file_${file.path}");
    notifyListeners();
  }

  void toggleSelectContent(dynamic id, [dynamic object]) {
    if (_selectedContentIds.contains(id)) {
      _selectedContentIds.remove(id);
      _selectedObjects.remove(id);
      // Also clean up pickedFiles if it's a generic file
      if (id.toString().startsWith("file_")) {
        final filePath = id.toString().replaceFirst("file_", "");
        _pickedFiles.removeWhere((f) => f.path == filePath);
      }
    } else {
      _selectedContentIds.add(id);
      if (object != null) {
        _selectedObjects[id.toString()] = object;
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedContentIds.clear();
    _selectedObjects.clear();
    _pickedFiles.clear();
    notifyListeners();
  }

  Future<List<File>> resolveSelectedFiles() async {
    List<File> filesToTransfer = List.from(_pickedFiles);
    
    final tempDir = await getTemporaryDirectory();

    for (String id in _selectedContentIds) {
      if (!_selectedObjects.containsKey(id)) continue;
      
      final obj = _selectedObjects[id];
      
      try {
        if (obj is Application) {
          final file = File(obj.apkFilePath);
          if (file.existsSync()) filesToTransfer.add(file);
        } else if (obj is Contact) {
          final vCard = obj.toVCard();
          final file = File('${tempDir.path}/${obj.displayName.replaceAll(" ", "_")}.vcf');
          await file.writeAsString(vCard);
          filesToTransfer.add(file);
        } else if (obj is AssetEntity) {
          final file = await obj.file;
          if (file != null) filesToTransfer.add(file);
        }
      } catch (e) {
        print('Error resolving file for $id: $e');
      }
    }
    
    return filesToTransfer;
  }

  // Security configuration rules
  String _destructRule = 'Never';
  String get destructRule => _destructRule;

  void setDestructRule(String rule) {
    _destructRule = rule;
    notifyListeners();
  }

  // Chat Room State
  final List<ChatMessage> _chatMessages = List.from(MockData.mockChatMessages);
  List<ChatMessage> get chatMessages => _chatMessages;

  void sendChatMessage(String text) {
    _chatMessages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      sender: "Me",
      text: text,
      time: "Just now",
      isMine: true,
      type: "text",
    ));
    notifyListeners();
  }

  // P2P Handshake & Transfer Simulation
  int _transferPhase = 0; // 0: KeyGen, 1: Exchange, 2: SharedSecret, 3: EncryptedStream, 4: Complete
  double _transferProgress = 0.0;
  bool _isTransferPaused = false;

  int get transferPhase => _transferPhase;
  double get transferProgress => _transferProgress;
  bool get isTransferPaused => _isTransferPaused;

  void setTransferPhase(int phase) {
    _transferPhase = phase;
    notifyListeners();
  }

  void setTransferProgress(double progress) {
    _transferProgress = progress;
    notifyListeners();
  }

  void toggleTransferPause() {
    _isTransferPaused = !_isTransferPaused;
    notifyListeners();
  }

  void resetTransfer() {
    _transferPhase = 0;
    _transferProgress = 0.0;
    _isTransferPaused = false;
    _transferFiles.clear();
    notifyListeners();
  }

  // Individual File Transfer State
  List<TransferFile> _transferFiles = [];
  List<TransferFile> get transferFiles => _transferFiles;

  void setTransferFiles(List<TransferFile> files) {
    _transferFiles = files;
    notifyListeners();
  }

  void updateFileTransfer(String name, int totalBytes, int transferredBytes, String status) {
    final idx = _transferFiles.indexWhere((f) => f.name == name);
    if (idx != -1) {
      _transferFiles[idx].transferredBytes = transferredBytes;
      if (totalBytes > 0) _transferFiles[idx].sizeBytes = totalBytes;
      _transferFiles[idx].status = status;
    } else {
      _transferFiles.add(TransferFile(
        id: name,
        name: name,
        sizeBytes: totalBytes,
        transferredBytes: transferredBytes,
        status: status,
      ));
    }
    notifyListeners();
  }

  // Room State
  final RoomService _roomService = RoomService();
  bool get inRoom => _roomService.isConnected;
  bool get isHost => _roomService.isHost;
  
  List<String> _roomMembers = [];
  List<String> get roomMembers => _roomMembers;

  Future<int> startRoom(String hostName) async {
    _setupRoomListeners();
    // Use an ephemeral port
    final port = await _roomService.startHost(0);
    _chatMessages.clear();
    _chatMessages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      sender: "System",
      text: "Room started. Waiting for others...",
      time: "Now",
      isMine: false,
      type: "text",
    ));
    notifyListeners();
    return port;
  }

  Future<void> joinRoom(String ip, int port, String myName) async {
    _setupRoomListeners();
    await _roomService.joinRoom(ip, port, myName);
    _chatMessages.clear();
    _chatMessages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      sender: "System",
      text: "Joined Room",
      time: "Now",
      isMine: false,
      type: "text",
    ));
    notifyListeners();
  }

  void _setupRoomListeners() {
    _roomService.onMessageReceived = (msg) {
      if (msg['type'] == 'system') {
        _chatMessages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          sender: "System",
          text: msg['text'],
          time: "Now",
          isMine: false,
          type: "text",
        ));
      } else if (msg['type'] == 'chat') {
        _chatMessages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          sender: msg['sender'],
          text: msg['text'],
          time: "Now",
          isMine: msg['sender'] == 'Host' ? isHost : false, // Needs better ID matching in prod
          type: "text",
        ));
      }
      notifyListeners();
    };

    _roomService.onMemberListUpdated = (members) {
      _roomMembers = members;
      notifyListeners();
    };

    _roomService.onDisconnected = () {
      _chatMessages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        sender: "System",
        text: "Disconnected from room",
        time: "Now",
        isMine: false,
        type: "text",
      ));
      notifyListeners();
    };
  }

  void sendRoomMessage(String text) {
    if (inRoom) {
      _roomService.sendMessage({
        'type': 'chat',
        'text': text,
      });
    } else {
      // Fallback to legacy 1-to-1 send
      sendChatMessage(text);
    }
  }

  void leaveRoom() {
    _roomService.stop();
    _roomMembers.clear();
    notifyListeners();
  }
}

class TransferFile {
  final String id;
  final String name;
  int sizeBytes;
  int transferredBytes;
  String status;

  TransferFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    this.transferredBytes = 0,
    this.status = 'pending',
  });
}
