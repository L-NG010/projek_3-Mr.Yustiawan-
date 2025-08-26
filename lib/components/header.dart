// header.dart
import 'package:flutter/material.dart';
import '../connect.dart';
import '../screen/setting.dart';
import '../screen/auth_screen.dart'; // Import for manual navigation

class Header extends StatefulWidget implements PreferredSizeWidget {
  const Header({super.key});
  
  @override
  State<Header> createState() => _HeaderState();
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
  final supabase = DatabaseConfig.client;
  String? email;
  String? avatarUrl;
  OverlayEntry? _overlayEntry;
  bool _isLoggingOut = false;
  
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
            .select('avatar_url')
            .eq('u_id', user.id)
            .maybeSingle();
            
        if (response != null) {
          setState(() {
            email = user.email;
            avatarUrl = response['avatar_url'];
          });
        } else {
          // Fallback jika tidak ada profile
          setState(() {
            email = user.email;
            avatarUrl = null;
          });
        }
      } catch (e) {
        // Fallback jika error
        setState(() {
          email = user.email;
          avatarUrl = null;
        });
        print('Error loading user profile: $e');
      }
    }
  }
  
  void _showProfileMenu(BuildContext context) {
    if (_isLoggingOut) return;
    
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
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
                          // Email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email ?? 'Pengguna',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (email != null && email!.length > 20)
                                  Text(
                                    email!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    // Settings Menu Item
                    InkWell(
                      onTap: _isLoggingOut ? null : () {
                        _hideProfileMenu();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        ).then((_) {
                          _loadUserProfile();
                        });
                      },
                      child: Opacity(
                        opacity: _isLoggingOut ? 0.5 : 1.0,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.settings, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Pengaturan',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _isLoggingOut ? null : () {
                        _hideProfileMenu();
                        _showLogoutConfirmation(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (_isLoggingOut) ...[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.logout, size: 18, color: Colors.red),
                            ],
                            const SizedBox(width: 8),
                            Text(
                              _isLoggingOut ? 'Keluar...' : 'Keluar',
                              style: TextStyle(
                                color: _isLoggingOut ? Colors.grey : Colors.red,
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
              onTap: _isLoggingOut ? null : () => _showProfileMenu(context),
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
                  child: _isLoggingOut
                      ? const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : avatarUrl != null
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
    if (_isLoggingOut) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: _isLoggingOut ? null : () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: _isLoggingOut ? Colors.grey : null,
              ),
            ),
          ),
          TextButton(
            onPressed: _isLoggingOut ? null : () async {
              await _performLogout(context);
            },
            child: _isLoggingOut
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Keluar...', style: TextStyle(color: Colors.red)),
                    ],
                  )
                : const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      print('Starting logout process...');
      print('Current user before logout: ${supabase.auth.currentUser?.email}');
      
      // Hide menu overlay if still showing
      _hideProfileMenu();
      
      // Sign out from Supabase
      await supabase.auth.signOut();
      
      print('Supabase signOut completed');
      print('Current user after logout: ${supabase.auth.currentUser?.email}');
      
      // Close dialog if it's still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Manual navigation as backup if stream doesn't work
      // This forces navigation back to login screen
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      
    } catch (e) {
      print('Logout error: $e');
      
      if (mounted) {
        // Close dialog if it's still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
}