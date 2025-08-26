// header.dart
import 'package:flutter/material.dart';
import '../connect.dart';
import '../main.dart';
import '../screen/setting.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
  final supabase = DatabaseConfig.client;
  String? username;
  String? avatarUrl;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        // Load profile dari tabel profiles
        final response = await supabase
            .from('profiles')
            .select('username, avatar_url')
            .eq('u_id', user.id)
            .maybeSingle();
            
        if (response != null) {
          setState(() {
            username = response['username'] ?? user.email?.split('@')[0] ?? 'Pengguna';
            avatarUrl = response['avatar_url'];
          });
        } else {
          // Fallback jika tidak ada profile
          setState(() {
            username = user.userMetadata?['username'] ?? user.email?.split('@')[0] ?? 'Pengguna';
            avatarUrl = null;
          });
        }
      } catch (e) {
        // Fallback jika error
        setState(() {
          username = user.email?.split('@')[0] ?? 'Pengguna';
          avatarUrl = null;
        });
        print('Error loading user profile: $e');
      }
    }
  }

  void _showProfileMenu(BuildContext context) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // This GestureDetector captures taps outside the menu
          GestureDetector(
            onTap: _hideProfileMenu,
            behavior: HitTestBehavior.translucent,
          ),
          Positioned(
            right: 16,
            top: position.dy + kToolbarHeight,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Info Section
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4A4877),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null
                                  ? Image.network(
                                      avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 24,
                                          color: Colors.grey,
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 24,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Username
                          Expanded(
                            child: Text(
                              username ?? 'Pengguna',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    // Add Settings Menu Item
                    InkWell(
                      onTap: () {
                        _hideProfileMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const UserSettingsPage()),
                        ).then((_) {
                          // Reload profile setelah kembali dari settings
                          _loadUserProfile();
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Pengaturan',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _hideProfileMenu();
                        _showLogoutConfirmation(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Keluar',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideProfileMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    
    return AppBar(
      title: const Text(
        'Jadwal Pembelajaran',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF4A4877),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      actions: [
        if (user != null) ...[
          // Profile Avatar Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => _showProfileMenu(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _hideProfileMenu();
    super.dispose();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context);
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A4877)),
      ),
    );

    try {
      await supabase.auth.signOut();
      
      if (!mounted) return;
      
      Navigator.of(context).pop();
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context).pop();
      
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Gagal keluar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}