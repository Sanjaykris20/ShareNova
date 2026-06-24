// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../services/auth_service.dart';
import '../../share_state.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String _selectedAvatar = "https://api.dicebear.com/7.x/avataaars/png?seed=Felix";

  final List<String> _avatars = [
    "https://api.dicebear.com/7.x/avataaars/png?seed=Felix",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Aneka",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Mimi",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Leo",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Lily",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Mia",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Max",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Sam",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and username')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          username: username,
          name: name,
          avatarUrl: _selectedAvatar,
        );
        await authService.saveUserProfile(profile);
        
        if (mounted) {
          Provider.of<ShareState>(context, listen: false).navigateTo('home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: \$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712), // gray-950
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Complete Profile",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose an avatar and set up your details.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              
              // Avatar Selection Grid
              const Text(
                "Select Avatar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatarUrl = _avatars[index];
                  final isSelected = _selectedAvatar == avatarUrl;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatarUrl;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF1F2937),
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Inputs
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Display Name",
                    hintStyle: TextStyle(color: Color(0xFF4B5563)),
                    prefixIcon: Icon(LucideIcons.user, color: Color(0xFF6B7280)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Username (e.g. jdoe99)",
                    hintStyle: TextStyle(color: Color(0xFF4B5563)),
                    prefixIcon: Icon(LucideIcons.at_sign, color: Color(0xFF6B7280)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // blue-600
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Save & Continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
