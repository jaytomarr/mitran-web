import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../widgets/design_system.dart';
import 'dart:typed_data';
import '../models/prediction.dart';
import '../services/disease_api.dart';
import '../services/firebase_service.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/result_card.dart';

class AiDiseaseScanPage extends StatefulWidget {
  const AiDiseaseScanPage({super.key});

  @override
  State<AiDiseaseScanPage> createState() => _AiDiseaseScanPageState();
}

class _AiDiseaseScanPageState extends State<AiDiseaseScanPage> {
  final _diseaseApi = DiseaseApi();
  final _firebaseService = FirebaseService();

  Uint8List? _selectedImageBytes;
  String? _selectedFilename;
  Prediction? _currentResult;

  bool _isAnalyzing = false;
  bool _isApiReady = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
  }

  Future<void> _checkApiHealth() async {
    final isReady = await _diseaseApi.checkHealth();
    setState(() => _isApiReady = isReady);
    if (!isReady) {
      Future.delayed(const Duration(seconds: 10), _checkApiHealth);
    }
  }

  void _onImageSelected(Uint8List bytes, String filename) {
    setState(() {
      _selectedImageBytes = bytes;
      _selectedFilename = filename;
      _currentResult = null;
      _error = null;
    });
  }

  void _onImageRemoved() {
    setState(() {
      _selectedImageBytes = null;
      _selectedFilename = null;
      _currentResult = null;
      _error = null;
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageBytes == null || _selectedFilename == null) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _currentResult = null;
    });
    try {
      final apiResult = await _diseaseApi.predict(
        imageBytes: _selectedImageBytes!,
        filename: _selectedFilename!,
      );
      String imageUrl = '';
      try {
        imageUrl = await _firebaseService.uploadImage(
          imageBytes: _selectedImageBytes!,
          filename: _selectedFilename!,
        );
      } catch (_) {}
      final prediction = Prediction.fromApi(
        imageUrl: imageUrl,
        apiData: apiResult,
      );
      try {
        await _firebaseService.savePrediction(prediction);
      } catch (_) {}
      setState(() {
        _currentResult = prediction;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  _BackButton(
                    label: 'Back to AI Care',
                    onTap: () => context.go('/ai-care'),
                  ),
                  const SizedBox(height: 16),
                  
                  // API Warning
                  if (!_isApiReady)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'AI system is initializing. Please wait...',
                              style: TextStyle(color: AppColors.warning),
                            ),
                          ),
                          TextButton(
                            onPressed: _checkApiHealth, 
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  
                  // Error Message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ),
                  
                  // Image Picker Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ImagePickerWidget(
                          onImageSelected: _onImageSelected,
                          onImageRemoved: _onImageRemoved,
                          selectedImage: _selectedImageBytes,
                        ),
                        if (_selectedImageBytes != null) ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: (_isAnalyzing || !_isApiReady) ? null : _analyzeImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                              child: _isAnalyzing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search, size: 18),
                                        SizedBox(width: 8),
                                        Text('Analyze Image'),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Result Card
                  if (_currentResult != null) ...[
                    const SizedBox(height: 20),
                    ResultCard(prediction: _currentResult!),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BackButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}