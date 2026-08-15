import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/toast_utils.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _telegramController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _youtubeController;
  late TextEditingController _discordController;

  final ImagePicker _picker = ImagePicker();
  File? _selectedAvatarFile;
  File? _selectedBannerFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _telegramController = TextEditingController(text: widget.user.telegram ?? '');
    _instagramController = TextEditingController(text: widget.user.instagram ?? '');
    _tiktokController = TextEditingController(text: widget.user.tiktok ?? '');
    _youtubeController = TextEditingController(text: widget.user.youtube ?? '');
    _discordController = TextEditingController(text: widget.user.discord ?? '');
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedAvatarFile = File(image.path);
      });
      // Darhol serverga yuklash
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.uploadAvatar(_selectedAvatarFile!);
      if (mounted) {
        if (success) {
          ToastUtils.showSuccess(context, "Profil rasmi yangilandi!");
        } else {
          ToastUtils.showError(context, "Rasmni yuklashda xatolik yuz berdi");
        }
      }
    }
  }

  Future<void> _pickBanner() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedBannerFile = File(image.path);
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.uploadBanner(_selectedBannerFile!);
      if (mounted) {
        if (success) {
          ToastUtils.showSuccess(context, "Profil banneri yangilandi!");
        } else {
          ToastUtils.showError(context, "Bannerni yuklashda xatolik yuz berdi");
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      telegram: _telegramController.text.trim(),
      instagram: _instagramController.text.trim(),
      tiktok: _tiktokController.text.trim(),
      youtube: _youtubeController.text.trim(),
      discord: _discordController.text.trim(),
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess(context, "Profil muvaffaqiyatli saqlandi!");
        Navigator.pop(context);
      } else {
        ToastUtils.showError(context, "Profilni saqlashda xatolik");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConfig.fullUrl(widget.user.avatarUrl);
    final bannerUrl = ApiConfig.fullUrl(widget.user.bannerUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilni Tahrirlash"),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, color: AppTheme.primary),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner & Avatar Upload Stack
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Banner Box
                  GestureDetector(
                    onTap: _pickBanner,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedBannerFile != null
                            ? Image.file(_selectedBannerFile!, fit: BoxFit.cover)
                            : bannerUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: bannerUrl, fit: BoxFit.cover)
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, color: AppTheme.textMuted),
                                        SizedBox(height: 4),
                                        Text(
                                          "Bannerni o'zgartirish",
                                          style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                  ),

                  // Avatar Circle
                  Positioned(
                    bottom: -35,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppTheme.background,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.surface,
                              backgroundImage: _selectedAvatarFile != null
                                  ? FileImage(_selectedAvatarFile!) as ImageProvider
                                  : avatarUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : null,
                              child: avatarUrl.isEmpty && _selectedAvatarFile == null
                                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // Ism
              const Text("Ism", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                validator: (val) => val == null || val.trim().isEmpty ? "Ism kiritilishi shart" : null,
                decoration: const InputDecoration(hintText: "Ismingizni kiriting"),
              ),
              const SizedBox(height: 16),

              // Bio / Haqida
              const Text("Bio (Haqida)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "O'zingiz haqingizda bir oz ma'lumot..."),
              ),
              const SizedBox(height: 24),

              // Ijtimoiy tarmoqlar
              const Text(
                "Ijtimoiy Tarmoqlar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              // Telegram
              TextFormField(
                controller: _telegramController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Telegram",
                  hintText: "@username",
                  prefixIcon: Icon(Icons.send, color: Color(0xFF229ED9), size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // Instagram
              TextFormField(
                controller: _instagramController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Instagram",
                  hintText: "username",
                  prefixIcon: Icon(Icons.camera_alt, color: Color(0xFFE1306C), size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // TikTok
              TextFormField(
                controller: _tiktokController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "TikTok",
                  hintText: "@username",
                  prefixIcon: Icon(Icons.music_note, color: Colors.white70, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // YouTube
              TextFormField(
                controller: _youtubeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "YouTube",
                  hintText: "Kanal havolasi",
                  prefixIcon: Icon(Icons.play_circle_filled, color: Colors.red, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // Discord
              TextFormField(
                controller: _discordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Discord",
                  hintText: "username#1234",
                  prefixIcon: Icon(Icons.headset, color: Color(0xFF5865F2), size: 20),
                ),
              ),
              const SizedBox(height: 32),

              // Saqlash tugmasi
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Saqlash"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
