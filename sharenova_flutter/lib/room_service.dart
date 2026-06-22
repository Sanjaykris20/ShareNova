// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class RoomMember {
  final String name;
  final Socket? socket;

  RoomMember({required this.name, this.socket});
}

class RoomService {
  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  bool _isWebHost = false;
  bool _isWebClient = false;
  Timer? _webTimer;
  Timer? _webTimerRoster;
  
  bool get isHost => _serverSocket != null || _isWebHost;
  bool get isConnected => _clientSocket != null || _isWebHost || _isWebClient;
  
  final List<RoomMember> _members = [];
  
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(List<String>)? onMemberListUpdated;
  Function()? onDisconnected;

  // Host methods
  Future<int> startHost(int port) async {
    if (kIsWeb) {
      _isWebHost = true;
      _members.clear();
      _members.add(RoomMember(name: "Host (You)"));
      
      // Schedule simulated join events on Web
      _webTimerRoster = Timer(const Duration(seconds: 4), () {
        _members.add(RoomMember(name: "Sarah (Web Client)"));
        _broadcastMemberList();
        
        if (onMessageReceived != null) {
          onMessageReceived!({
            'type': 'system',
            'text': 'Sarah (Web Client) joined the room',
          });
        }
        
        _webTimer = Timer(const Duration(seconds: 2), () {
          if (onMessageReceived != null) {
            onMessageReceived!({
              'type': 'chat',
              'sender': 'Sarah (Web Client)',
              'text': 'Hi! Connected from Chrome browser.',
            });
          }
        });
      });
      
      return 8080;
    }

    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _serverSocket!.listen((Socket client) {
      _handleNewConnection(client);
    });
    return _serverSocket!.port;
  }

  void _handleNewConnection(Socket client) {
    client.listen(
      (List<int> data) {
        final messageStr = utf8.decode(data);
        try {
          final msgs = messageStr.split('\n').where((s) => s.trim().isNotEmpty);
          for (var msg in msgs) {
            final Map<String, dynamic> parsed = jsonDecode(msg);
            _processMessageAsHost(client, parsed);
          }
        } catch (e) {
          print("Error parsing message: $e");
        }
      },
      onDone: () => _handleClientDisconnect(client),
      onError: (e) => _handleClientDisconnect(client),
    );
  }

  void _processMessageAsHost(Socket client, Map<String, dynamic> msg) {
    if (msg['type'] == 'join') {
      final name = msg['name'] ?? 'Unknown';
      _members.add(RoomMember(name: name, socket: client));
      _broadcastMemberList();
      
      if (onMessageReceived != null) {
        onMessageReceived!({
          'type': 'system',
          'text': '$name joined the room',
        });
      }
    } else if (msg['type'] == 'chat' || msg['type'] == 'file_manifest') {
      final sender = _members.firstWhere((m) => m.socket == client, orElse: () => RoomMember(name: "Unknown", socket: client));
      msg['sender'] = sender.name;
      
      _broadcastMessage(msg, exclude: client);
      
      if (onMessageReceived != null) {
        onMessageReceived!(msg);
      }
    }
  }

  void _broadcastMemberList() {
    final names = _members.map((m) => m.name).toList();
    if (onMemberListUpdated != null) {
      onMemberListUpdated!(names);
    }
    
    if (!kIsWeb) {
      _broadcastMessage({
        'type': 'roster',
        'members': names,
      });
    }
  }

  void _broadcastMessage(Map<String, dynamic> msg, {Socket? exclude}) {
    if (kIsWeb) return;
    final str = '${jsonEncode(msg)}\n';
    for (var member in _members) {
      if (member.socket != exclude && member.socket != null) {
        member.socket!.write(str);
      }
    }
  }

  void _handleClientDisconnect(Socket client) {
    final index = _members.indexWhere((m) => m.socket == client);
    if (index != -1) {
      final name = _members[index].name;
      _members.removeAt(index);
      _broadcastMemberList();
      
      if (onMessageReceived != null) {
        onMessageReceived!({
          'type': 'system',
          'text': '$name left the room',
        });
      }
    }
  }

  // Client methods
  Future<void> joinRoom(String ip, int port, String myName) async {
    if (kIsWeb) {
      _isWebClient = true;
      
      Timer(const Duration(seconds: 1), () {
        if (onMemberListUpdated != null) {
          onMemberListUpdated!(["Host", myName]);
        }
      });
      
      _webTimer = Timer(const Duration(seconds: 2), () {
        if (onMessageReceived != null) {
          onMessageReceived!({
            'type': 'chat',
            'sender': 'Host',
            'text': 'Welcome to the local room! Feel free to chat.',
          });
        }
      });
      return;
    }

    _clientSocket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
    
    sendMessage({
      'type': 'join',
      'name': myName,
    });
    
    _clientSocket!.listen(
      (List<int> data) {
        final messageStr = utf8.decode(data);
        try {
          final msgs = messageStr.split('\n').where((s) => s.trim().isNotEmpty);
          for (var msg in msgs) {
            final Map<String, dynamic> parsed = jsonDecode(msg);
            if (parsed['type'] == 'roster') {
              if (onMemberListUpdated != null) {
                final membersList = List<String>.from(parsed['members']);
                onMemberListUpdated!(membersList);
              }
            } else {
              if (onMessageReceived != null) {
                onMessageReceived!(parsed);
              }
            }
          }
        } catch (e) {
          print("Error parsing message: $e");
        }
      },
      onDone: _handleHostDisconnect,
      onError: (e) => _handleHostDisconnect(),
    );
  }

  void _handleHostDisconnect() {
    _clientSocket?.destroy();
    _clientSocket = null;
    if (onDisconnected != null) {
      onDisconnected!();
    }
  }

  void sendMessage(Map<String, dynamic> msg) {
    if (kIsWeb) {
      if (isHost) {
        msg['sender'] = 'Host';
        if (onMessageReceived != null) {
          onMessageReceived!(msg);
        }
      } else {
        msg['sender'] = 'Participant';
        if (onMessageReceived != null) {
          onMessageReceived!(msg);
        }
        
        // Simulating host reply on web
        _webTimer = Timer(const Duration(seconds: 1), () {
          if (onMessageReceived != null) {
            onMessageReceived!({
              'type': 'chat',
              'sender': 'Host',
              'text': 'Echo from Host: "${msg['text']}"',
            });
          }
        });
      }
      return;
    }

    if (isHost) {
      msg['sender'] = 'Host';
      _broadcastMessage(msg);
      if (onMessageReceived != null) {
        onMessageReceived!(msg);
      }
    } else if (_clientSocket != null) {
      final str = '${jsonEncode(msg)}\n';
      _clientSocket!.write(str);
    }
  }

  void stop() {
    _webTimer?.cancel();
    _webTimerRoster?.cancel();
    _isWebHost = false;
    _isWebClient = false;

    if (!kIsWeb) {
      for (var member in _members) {
        member.socket?.destroy();
      }
      _serverSocket?.close();
      _serverSocket = null;
      _clientSocket?.destroy();
      _clientSocket = null;
    }
    _members.clear();
  }
}
