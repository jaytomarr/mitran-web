import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/dog_model.dart';
import '../models/dog_filters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authReadyProvider = FutureProvider<void>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    await user.getIdToken(true);
  } catch (_) {}
});

final userProfileProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => UserModel.fromFirestore(doc));
});

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => PostModel.fromFirestore(d)).toList());
});

final userPostsProvider = StreamProvider.family<List<PostModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('author.userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => PostModel.fromFirestore(d)).toList());
});

final dogsProvider = StreamProvider<List<DogModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('dogs')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => DogModel.fromFirestore(d)).toList());
});

final dogFiltersProvider = StateProvider<DogFilters>((ref) {
  return const DogFilters(vaccinated: false, sterilized: false, readyForAdoption: false);
});

final searchTermProvider = StateProvider<String>((ref) => '');

final filteredDogsProvider = Provider<List<DogModel>>((ref) {
  final dogs = ref.watch(dogsProvider).value ?? [];
  final filters = ref.watch(dogFiltersProvider);
  final searchTerm = ref.watch(searchTermProvider);
  return dogs.where((dog) {
    if (searchTerm.isNotEmpty) {
      final t = searchTerm.toLowerCase();
      final matchesName = dog.name.toLowerCase().contains(t);
      final matchesArea = dog.area.toLowerCase().contains(t);
      if (!matchesName && !matchesArea) return false;
    }
    if (filters.vaccinated && !dog.vaccinationStatus) return false;
    if (filters.sterilized && !dog.sterilizationStatus) return false;
    if (filters.readyForAdoption && !dog.readyForAdoption) return false;
    return true;
  }).toList();
});

final dogProvider = StreamProvider.family<DogModel, String>((ref, dogId) {
  return FirebaseFirestore.instance
      .collection('dogs')
      .doc(dogId)
      .snapshots()
      .map((doc) => DogModel.fromFirestore(doc));
});

final userDogsProvider = StreamProvider.family<List<DogModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('dogs')
      .where('addedBy.userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((d) => DogModel.fromFirestore(d)).toList());
});