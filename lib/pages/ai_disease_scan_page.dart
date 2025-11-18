import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            if (!_isApiReady)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI system is initializing. Please wait...',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextButton(onPressed: _checkApiHealth, child: const Text('Retry')),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Disease Scan', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text('Worried about a skin condition? Upload a photo to get a preliminary analysis.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('This is not a substitute for a vet.', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.25),
                surfaceTintColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ImagePickerWidget(
                    onImageSelected: _onImageSelected,
                    onImageRemoved: _onImageRemoved,
                    selectedImage: _selectedImageBytes,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_selectedImageBytes != null)
                    ElevatedButton(
                      onPressed: (_isAnalyzing || !_isApiReady) ? null : _analyzeImage,
                      child: Text(_isAnalyzing ? 'Analyzing…' : 'Analyze Image'),
                    ),
                ],
              ),
            ),
            if (_currentResult != null) ResultCard(prediction: _currentResult!),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  ),
 ),
);
  }
}