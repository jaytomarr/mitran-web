import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/prediction.dart';

class FirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = filename.split('.').last;
      final storagePath = 'images/predictions/${timestamp}_$filename';
      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<String> savePrediction(Prediction prediction) async {
    try {
      final docRef = await _firestore.collection('predictions').add(
            prediction.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save prediction: $e');
    }
  }

  Stream<List<Prediction>> getHistory() {
    return _firestore
        .collection('predictions')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Prediction.fromFirestore(doc)).toList();
    });
  }

  Future<void> deletePrediction(String predictionId, String imageUrl) async {
    try {
      await _firestore.collection('predictions').doc(predictionId).delete();
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to delete prediction: $e');
    }
  }
}