import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ProfileSettings extends StatefulWidget {
  final SupabaseClient supabase;
  final String userId;
  const ProfileSettings({
    super.key,
    required this.supabase,
    required this.userId,
  });

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _profilePhotoUrl;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = widget.supabase.auth.currentUser;
      if (user != null) {
        final response = await widget.supabase
            .from('profiles') // Diubah dari 'users' ke 'profiles'
            .select('username, avatar_url') // Diubah dari 'img_url' ke 'avatar_url'
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          _usernameController.text = response['username'] ?? '';
          if (response['avatar_url'] != null) {
            // Tambahkan cache busting
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            setState(() => _profilePhotoUrl = '${response['avatar_url']}?t=$timestamp');
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      _showSnackBar('Gagal memuat profil: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = widget.supabase.auth.currentUser;
      if (user != null) {
        await widget.supabase.from('profiles').upsert({ // Diubah ke 'profiles'
          'id': user.id,
          'username': _usernameController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      _showSnackBar('Username berhasil diperbarui');
    } catch (e) {
      print('Error updating profile: $e');
      _showSnackBar('Gagal memperbarui username: ${e.toString()}', isError: true);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.trim().isEmpty) {
      _showSnackBar('Masukkan password baru', isError: true);
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      _showSnackBar('Password minimal 6 karakter', isError: true);
      return;
    }

    try {
      await widget.supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      _passwordController.clear();
      _showSnackBar('Password berhasil diperbarui');
    } catch (e) {
      print('Error updating password: $e');
      _showSnackBar('Gagal memperbarui password: ${e.toString()}', isError: true);
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final user = widget.supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${user.id}_$timestamp.jpg';
      
      String photoUrl;
      
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        await widget.supabase.storage
            .from('avatars') // Sesuaikan dengan nama bucket Anda
            .uploadBinary(fileName, bytes, fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ));
      } else {
        final file = File(pickedFile.path);
        await widget.supabase.storage
            .from('avatars') // Sesuaikan dengan nama bucket Anda
            .upload(fileName, file, fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ));
      }

      // Dapatkan URL dengan cache busting
      photoUrl = '${widget.supabase.storage
          .from('avatars')
          .getPublicUrl(fileName)}?t=$timestamp';

      // Update profile dengan upsert
      await widget.supabase.from('profiles').upsert({
        'id': user.id,
        'avatar_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() => _profilePhotoUrl = photoUrl);
      _showSnackBar('Foto profil berhasil diperbarui');
    } catch (e) {
      print('Error uploading photo: $e');
      _showSnackBar('Gagal mengunggah foto: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A679E)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploading ? null : _uploadProfilePhoto,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: ClipOval(
                              child: _isUploading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF6A679E),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : _profilePhotoUrl != null
                                      ? Image.network(
                                          _profilePhotoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.grey,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Foto Profil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isUploading ? null : _uploadProfilePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A4877),
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            _isUploading ? 'Mengunggah...' : 'Unggah Foto',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF6A679E), width: 2),
                                  ),
                                ),
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Masukkan username' : null,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A4877),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    'Simpan Username',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password Baru',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF6A679E), width: 2),
                                  ),
                                ),
                                obscureText: true,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Masukkan password'
                                    : value!.length < 6
                                        ? 'Password minimal 6 karakter'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _updatePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A4877),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text(
                                    'Simpan Password',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}