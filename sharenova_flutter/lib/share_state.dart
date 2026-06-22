// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/p2p_service.dart';
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

  int _currentTab = 0;
  int get currentTab => _currentTab;

  void navigateTo(String route) {
    if (route == 'profile') {
      setTab(4);
    } else if (route == 'room_gateway') {
      setTab(3);
    } else {
      _currentRoute = route;
      notifyListeners();
    }
  }

  void setTab(int index) {
    _currentTab = index;
    _currentRoute = 'home'; // Reset root navigator to home shell
    notifyListeners();
  }

  // File Selector State
  final List<dynamic> _selectedContentIds = [];
  List<dynamic> get selectedContentIds => _selectedContentIds;

  final List<PlatformFile> _pickedFiles = [];
  List<PlatformFile> get pickedFiles => _pickedFiles;

  void addPickedFiles(List<PlatformFile> files) {
    for (var file in files) {
      if (!_pickedFiles.any((f) => f.name == file.name)) {
        _pickedFiles.add(file);
        _selectedContentIds.add("picked_${file.name}");
      }
    }
    notifyListeners();
  }

  void removePickedFile(PlatformFile file) {
    _pickedFiles.removeWhere((f) => f.name == file.name);
    _selectedContentIds.remove("picked_${file.name}");
    notifyListeners();
  }

  void toggleSelectContent(dynamic id) {
    if (_selectedContentIds.contains(id)) {
      _selectedContentIds.remove(id);
      // Also clean up pickedFiles if it's a picked file
      if (id.toString().startsWith("picked_")) {
        final filename = id.toString().replaceFirst("picked_", "");
        _pickedFiles.removeWhere((f) => f.name == filename);
      }
    } else {
      _selectedContentIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedContentIds.clear();
    _pickedFiles.clear();
    notifyListeners();
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
