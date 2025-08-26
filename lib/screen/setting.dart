import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../connect.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final supabase = DatabaseConfig.client;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  File? _imageFile;
  Uint8List? _webImageBytes; // For web platform
  bool _isLoading = false;
  String? _currentAvatarUrl;
  String? _errorMessage;
  String? _successMessage;
  String? _profileId; // ID dari tabel profiles (UUID string)

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Load username from user_metadata
      final username = user.userMetadata?['username'] ?? user.email?.split('@').first;
      _usernameController.text = username ?? '';
      
      // Load profile data dari tabel profiles berdasarkan u_id
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
      
      print('Profile data response: $response'); // Debugging
      if (response != null) {
        setState(() {
          _profileId = response['id'] as String?;
          _currentAvatarUrl = response['avatar_url'] as String?;
          print('Loaded profile_id: $_profileId, avatar_url: $_currentAvatarUrl'); // Debugging
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
        _currentAvatarUrl = null; // Pastikan state direset jika error
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _imageFile = null; // Clear mobile file
          });
        } else {
          // For mobile platforms
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImageBytes = null; // Clear web bytes
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
    
    // 1. Update username di user_metadata Supabase Auth
    await supabase.auth.updateUser(
      UserAttributes(
        data: {'username': _usernameController.text.trim()},
      ),
    );
    
    // 2. Update password jika diisi
    if (_passwordController.text.isNotEmpty) {
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
    }
    
    // 3. Upload avatar ke Supabase Storage jika dipilih
    String? avatarUrl;
    if (_imageFile != null || _webImageBytes != null) {
      final user = supabase.auth.currentUser!;
      final fileExt = 'jpg'; // Default extension
      
      // Generate unique filename dengan timestamp untuk mencegah overwrite
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}_$timestamp.$fileExt';
      final filePath = fileName;
      
      print('Uploading new avatar with filename: $fileName'); // Debugging
      
      if (kIsWeb && _webImageBytes != null) {
        // Upload from web bytes - tidak menggunakan upsert
        await supabase.storage
          .from('avatars')
          .uploadBinary(filePath, _webImageBytes!);
      } else if (_imageFile != null) {
        // Upload from mobile file - tidak menggunakan upsert
        await supabase.storage
          .from('avatars')
          .upload(filePath, _imageFile!);
      }
      
      avatarUrl = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);
      print('Generated new avatar URL: $avatarUrl'); // Debugging
    }
    
    // 4. Update data di tabel profiles dengan avatar_url baru (jika ada)
    if (_profileId != null) {
      // Profile exists, update berdasarkan id (primary key)
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Hanya update avatar_url jika ada foto baru yang diupload
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
        print('Updating existing profile (id: $_profileId) with new avatar URL: $avatarUrl'); // Debugging
      }
      
      // PERBAIKAN: Tambahkan null check untuk _profileId
      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', _profileId!); // Gunakan ! untuk assert non-null
    } else {
      // Profile doesn't exist, insert new record
      final insertData = {
        'u_id': user.id,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('Creating new profile with u_id: ${user.id}, avatar URL: $avatarUrl'); // Debugging
      final insertResponse = await supabase
          .from('profiles')
          .insert(insertData)
          .select('id')
          .single();
      
      // Update _profileId dengan ID yang baru dibuat
      setState(() {
        _profileId = insertResponse['id'] as String?;
      });
    }
    
    setState(() {
      _successMessage = 'Profil berhasil diperbarui!';
      _passwordController.clear();
      _confirmPasswordController.clear();
      _imageFile = null;
      _webImageBytes = null; // Clear web bytes
      
      // Update current avatar URL hanya jika ada URL baru
      if (avatarUrl != null) {
        _currentAvatarUrl = avatarUrl;
      }
    });
    
    // Reload profile data untuk memastikan sinkronisasi
    await _loadProfileData(user.id);
    
  } catch (e) {
    print('Update profile error: $e'); // Debugging
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
          'Pengaturan Pengguna',
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
                    if (_profileId != null)
                      Text(
                        'Profile ID: $_profileId',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Username Field
              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan username baru',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
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
    // Priority: newly selected image > current avatar URL > default icon
    if (kIsWeb && _webImageBytes != null) {
      // Web platform with selected image
      return Image.memory(
        _webImageBytes!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (!kIsWeb && _imageFile != null) {
      // Mobile platform with selected image
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (_currentAvatarUrl != null) {
      // Current avatar from server
      print('Attempting to load image from: $_currentAvatarUrl'); // Debugging
      return Image.network(
        _currentAvatarUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          print('Image load error: $error'); // Debugging
          return const Icon(
            Icons.person,
            size: 60,
            color: Colors.grey,
          );
        },
      );
    } else {
      // Default icon
      return const Icon(
        Icons.person,
        size: 60,
        color: Colors.grey,
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}