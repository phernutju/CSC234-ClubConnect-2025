import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/step_progress_bar.dart';

class SetProfileScreen extends StatefulWidget {
  final String? googleDisplayName;

  const SetProfileScreen({super.key, this.googleDisplayName});

  @override
  State<SetProfileScreen> createState() => _SetProfileScreenState();
}

class _SetProfileScreenState extends State<SetProfileScreen> {
  final _displayNameController = TextEditingController();
  final _aboutMeController     = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _pickedBytes;
  String? _displayNameError;

  static const InputDecoration _fieldDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSizes.paddingM,
      vertical: AppSizes.paddingM,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      borderSide: BorderSide(color: Color(0xFFFF6B4A), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      borderSide: BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      borderSide: BorderSide(color: Colors.red),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.googleDisplayName != null) {
      _displayNameController.text = widget.googleDisplayName!;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedBytes = bytes);
    }
  }

  bool _validate() {
    final name = _displayNameController.text.trim();
    String? error;
    if (name.isEmpty) {
      error = 'Display name is required';
    } else if (name.length < 3) {
      error = 'Minimum 3 characters';
    } else if (name.length > 30) {
      error = 'Must be 30 characters or less';
    } else if (!RegExp(r'^[\w ]+$').hasMatch(name)) {
      error = 'Only letters, numbers, underscore and space allowed';
    }
    setState(() => _displayNameError = error);
    return error == null;
  }

  void _onNext() {
    if (!_validate()) return;
    final displayName = _displayNameController.text.trim();
    final bio = _aboutMeController.text.trim();
    context.read<AppAuthProvider>().setExtraInfo('', displayName, bio, imageBytes: _pickedBytes);
    context.push('/category', extra: {'displayName': displayName});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const StepProgressBar(currentStep: 3),
              const SizedBox(height: AppSizes.paddingL),

              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: AppColors.textDark),
              ),
              const SizedBox(height: AppSizes.paddingM),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: AppStrings.setProfileHeading,
                      style: AppTextStyles.title(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    TextSpan(
                      text: AppStrings.setProfileHeadingAccent,
                      style: AppTextStyles.title(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              Center(
                child: _AvatarPicker(
                  imageBytes: _pickedBytes,
                  onTap: _pickImage,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              Text(
                AppStrings.setProfileDisplayName,
                style: AppTextStyles.body(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              SizedBox(
                height: AppSizes.inputHeight,
                child: TextFormField(
                  controller: _displayNameController,
                  style: AppTextStyles.body(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDark,
                  ),
                  decoration: _fieldDecoration,
                ),
              ),
              if (_displayNameError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _displayNameError!,
                  style: AppTextStyles.body(
                    fontSize: AppSizes.fontXS,
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.paddingM),

              Text(
                AppStrings.setProfileAboutMe,
                style: AppTextStyles.body(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              TextFormField(
                controller: _aboutMeController,
                minLines: 1,
                maxLines: 3,
                style: AppTextStyles.body(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDark,
                ),
                decoration: _fieldDecoration,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.10),

              SizedBox(
                height: AppSizes.buttonHeight,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.cardWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                  child: Text(
                    AppStrings.setProfileNext,
                    style: AppTextStyles.button(color: AppColors.cardWhite),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const _AvatarPicker({
    this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          children: [
            ClipOval(
              child: SizedBox(
                width: 160,
                height: 160,
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : Container(color: AppColors.avatarSalmon),
              ),
            ),

            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textDark,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: AppColors.cardWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}