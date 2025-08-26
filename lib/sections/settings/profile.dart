// profile.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../connect.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = DatabaseConfig.client;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  String? _currentAvatarUrl;
  String? _errorMessage;
  String? _successMessage;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await _loadProfileData(user.id);
    }
  }

  Future<void> _loadProfileData(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id, avatar_url')
          .eq('u_id', userId)
          .maybeSingle();
      
      print('Profile data response: $response');
      if (response != null) {
        setState(() {
          _profileId = response['id'] as String?;
          _currentAvatarUrl = response['avatar_url'] as String?;
          print('Loaded profile_id: $_profileId, avatar_url: $_currentAvatarUrl');
        });
      } else {
        setState(() {
          _profileId = null;
          _currentAvatarUrl = null;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _currentAvatarUrl = null;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih gambar: ${e.toString()}';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User tidak ditemukan');
      
      // 1. Update password jika diisi
      bool passwordUpdated = false;
      if (_passwordController.text.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim()),
        );
        passwordUpdated = true;
        print('Password berhasil diupdate');
      }
      
      // 2. Upload avatar ke Supabase Storage jika dipilih
      String? avatarUrl;
      if (_imageFile != null || _webImageBytes != null) {
        final user = supabase.auth.currentUser!;
        final fileExt = 'jpg';
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${user.id}_$timestamp.$fileExt';
        final filePath = fileName;
        
        print('Uploading new avatar with filename: $fileName');
        
        if (kIsWeb && _webImageBytes != null) {
          await supabase.storage
            .from('avatars')
            .uploadBinary(filePath, _webImageBytes!);
        } else if (_imageFile != null) {
          await supabase.storage
            .from('avatars')
            .upload(filePath, _imageFile!);
        }
        
        avatarUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);
        print('Generated new avatar URL: $avatarUrl');
      }
      
      // 3. Update atau insert data di tabel profiles
      if (_profileId != null) {
        final updateData = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (avatarUrl != null) {
          updateData['avatar_url'] = avatarUrl;
          print('Updating existing profile (id: $_profileId) with new avatar URL: $avatarUrl');
        }
        
        await supabase
            .from('profiles')
            .update(updateData)
            .eq('id', _profileId!);
      } else {
        final insertData = {
          'u_id': user.id,
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        print('Creating new profile with u_id: ${user.id}, avatar URL: $avatarUrl');
        final insertResponse = await supabase
            .from('profiles')
            .insert(insertData)
            .select('id')
            .single();
        
        setState(() {
          _profileId = insertResponse['id'] as String?;
        });
      }
      
      setState(() {
        _successMessage = 'Profil berhasil diperbarui!';
        _passwordController.clear();
        _confirmPasswordController.clear();
        _imageFile = null;
        _webImageBytes = null;
        
        if (avatarUrl != null) {
          _currentAvatarUrl = avatarUrl;
        }
      });
      
      await _loadProfileData(user.id);
      
    } catch (e) {
      print('Update profile error: $e');
      setState(() {
        _errorMessage = 'Gagal memperbarui profil: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validatePassword(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 6) {
        return 'Password minimal 6 karakter';
      }
      if (value != _confirmPasswordController.text) {
        return 'Password tidak cocok';
      }
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Pengaturan Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A4877),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4A4877),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _buildProfileImage(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A4877),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Foto Profil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Password Field
              const Text(
                'Password Baru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Masukkan password baru (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF6A679E),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: _validatePassword,
              ),
              
              const SizedBox(height: 20),
              
              // Confirm Password Field
              const Text(
                'Konfirmasi Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Konfirmasi password baru',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF6A679E),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              
              const SizedBox(height: 30),
              
              // Error/Success Messages
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              
              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              
              if (_errorMessage != null || _successMessage != null)
                const SizedBox(height: 20),
              
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4877),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Perbarui Profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildProfileImage() {
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (!kIsWeb && _imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (_currentAvatarUrl != null) {
      return Image.network(
        _currentAvatarUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            size: 60,
            color: Colors.grey,
          );
        },
      );
    } else {
      return const Icon(
        Icons.person,
        size: 60,
        color: Colors.grey,
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}