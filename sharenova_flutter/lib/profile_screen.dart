// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'share_state.dart';
import 'services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      final p = await authService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = p;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final state = Provider.of<ShareState>(context, listen: false);
    await authService.signOut();
    state.navigateTo('splash');
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5)
                ],
              ),
              child: const Icon(LucideIcons.log_out, size: 20, color: Color(0xFF4B5563)),
            ),
            onPressed: _signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(_profile?.avatarUrl ?? "https://api.dicebear.com/7.x/avataaars/png?seed=Felix"),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?.name ?? "Loading...",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "@\${_profile?.username ?? 'loading'}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: const [
                                Icon(LucideIcons.crown, size: 12, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text(
                                  "PRO",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Storage Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: -10,
                    right: -10,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(LucideIcons.hard_drive, size: 100, color: Colors.white),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(LucideIcons.hard_drive, size: 16, color: Color(0xFFD1D5DB)),
                                  SizedBox(width: 8),
                                  Text(
                                    "INTERNAL STORAGE",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD1D5DB), letterSpacing: 1.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: const [
                                  Text(
                                    "75%",
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Used",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => state.navigateTo('clean'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Clean Up",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.75,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF34D399)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("96 GB Used", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
                          Text("128 GB Total", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions List
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                children: [
                  _buildActionRow(context, "replicate", LucideIcons.smartphone_charging, "Phone Replicate", "Clone data to a new device", const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
                  _buildActionRow(context, "webshare", LucideIcons.globe, "WebShare", "Share without network via browser", const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                  _buildActionRow(context, "invite", LucideIcons.users, "Invite Friends", "QR Code & Bluetooth Share", const Color(0xFF10B981), const Color(0xFFECFDF5)),
                  _buildActionRow(context, "analytics", Icons.bar_chart, "Transfer Analytics", "View your sharing history stats", const Color(0xFFF97316), const Color(0xFFFFF7ED)),
                  _buildActionRow(context, "file_manager", LucideIcons.folder_open, "My Files", "Received content & Downloads", const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, String route, IconData icon, String title, String subtitle, Color iconColor, Color bg) {
    return GestureDetector(
      onTap: () => Provider.of<ShareState>(context, listen: false).navigateTo(route),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
            const Icon(LucideIcons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
