// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// Import your app screens
import 'home_screen.dart';
import 'chat_room_screen.dart';
import 'discover_feed_screen.dart';
import 'workspace_hub_screen.dart';
import 'profile_screen.dart';
import 'splash_screen.dart';
import 'file_manager_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/device_discovery_screen.dart';
import 'transfer_screen.dart';
import 'room_gateway_screen.dart';
import 'room_host_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'auto_sync_screen.dart';
import 'replicate_screen.dart';
import 'web_share_screen.dart';
import 'invite_screen.dart';

// Import shared state
import 'share_state.dart';
import 'services/p2p_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShareState()),
        Provider(create: (_) => P2pService()),
      ],
      child: const ShareNovaApp(),
    ),
  );
}

class ShareNovaApp extends StatelessWidget {
  const ShareNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareNova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);
    switch (state.currentRoute) {
      case 'splash':
        return SplashScreen();
      case 'home':
        return MainShell();
      case 'file_manager':
        return FileManagerScreen();
      case 'device_discovery':
        return DeviceDiscoveryScreen();
      case 'receive':
        return const ReceiveScreen();
      case 'transfer':
        return TransferScreen();
      case 'room_gateway':
        return RoomGatewayScreen();
      case 'room_host':
        return RoomHostScreen();
      case 'chat_room':
        return ChatRoomScreen();
      case 'history':
        return HistoryScreen();
      case 'analytics':
        return AnalyticsScreen();
      case 'autosync':
        return AutoSyncScreen();
      case 'replicate':
        return ReplicateScreen();
      case 'webshare':
        return WebShareScreen();
      case 'invite':
        return InviteScreen();
      case 'clean':
        return MainShell();
      default:
        return SplashScreen();
    }
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);
    final List<Widget> tabs = [
      HomeScreen(),
      ChatRoomScreen(),
      DiscoverFeedScreen(),
      WorkspaceHubScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: state.currentTab,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: state.currentTab,
          onTap: (index) {
            state.setTab(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF2563EB),
          unselectedItemColor: Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.send),
              label: 'Share',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.message_square),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.compass),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.users),
              label: 'Spaces',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
