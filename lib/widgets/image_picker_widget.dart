import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'design_system.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(Uint8List bytes, String filename) onImageSelected;
  final VoidCallback? onImageRemoved;
  final Uint8List? selectedImage;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.onImageRemoved,
    this.selectedImage,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _error;

  Future<void> _pickImage() async {
    try {
      setState(() => _error = null);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        setState(() => _error = 'Could not read file');
        return;
      }
      if (file.bytes!.length > 5 * 1024 * 1024) {
        setState(() => _error = 'Image must be under 5MB');
        return;
      }
      widget.onImageSelected(file.bytes!, file.name);
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  void _removeImage() {
    setState(() => _error = null);
    widget.onImageRemoved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2, style: BorderStyle.solid),
          ),
          child: widget.selectedImage != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        widget.selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Click to upload image',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PNG or JPEG • Max 5MB',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                ],
              ),
            ),
          ),
        if (widget.selectedImage == null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: AccentButton(
              text: 'Choose Image',
              onPressed: _pickImage,
            ),
          ),
      ],
    );
  }
}