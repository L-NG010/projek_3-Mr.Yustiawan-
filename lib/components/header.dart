// header.dart
import 'package:flutter/material.dart';
import '../connect.dart';
import '../main.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() {
    final user = supabase.auth.currentUser;
    if (user != null && user.email != null) {
      // Ambil username dari email (username@example.com -> username)
      final email = user.email!;
      setState(() {
        username = email.split('@')[0];
      });
    }
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
          // Profile info
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 6),
                Text(
                  username ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin logout?'),
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
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A4877)),
      ),
    );

    try {
      // Logout dengan Supabase Auth
      await supabase.auth.signOut();
      
      if (!mounted) return;
      
      // Tutup loading dialog
      Navigator.of(context).pop();
      
      // Redirect ke auth screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      // Tutup loading dialog
      Navigator.of(context).pop();
      
      // Show error
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Logout gagal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}