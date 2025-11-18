import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Prediction {
  final String id;
  final String imageUrl;
  final String label;
  final double confidence;
  final String title;
  final String description;
  final List<String> symptoms;
  final List<String> treatments;
  final List<String> homecare;
  final String note;
  final DateTime timestamp;

  const Prediction({
    required this.id,
    required this.imageUrl,
    required this.label,
    required this.confidence,
    required this.title,
    required this.description,
    required this.symptoms,
    required this.treatments,
    required this.homecare,
    required this.note,
    required this.timestamp,
  });

  factory Prediction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prediction(
      id: doc.id,
      imageUrl: data['imageUrl'] as String,
      label: data['label'] as String,
      confidence: (data['confidence'] as num).toDouble(),
      title: data['title'] as String,
      description: data['description'] as String,
      symptoms: (data['symptoms'] as List).cast<String>(),
      treatments: (data['treatments'] as List).cast<String>(),
      homecare: (data['homecare'] as List).cast<String>(),
      note: data['note'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'label': label,
      'confidence': confidence,
      'title': title,
      'description': description,
      'symptoms': symptoms,
      'treatments': treatments,
      'homecare': homecare,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Prediction.fromApi({
    required String imageUrl,
    required Map<String, dynamic> apiData,
  }) {
    return Prediction(
      id: '',
      imageUrl: imageUrl,
      label: apiData['label'] as String,
      confidence: (apiData['confidence'] as num).toDouble(),
      title: apiData['title'] as String,
      description: apiData['description'] as String,
      symptoms: (apiData['symptoms'] as List).cast<String>(),
      treatments: (apiData['treatments'] as List).cast<String>(),
      homecare: (apiData['homecare'] as List).cast<String>(),
      note: apiData['note'] as String,
      timestamp: DateTime.now(),
    );
  }

  Color get confidenceColor {
    if (confidence >= 80) return const Color(0xFF4CAF50);
    if (confidence >= 60) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}