import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/dog_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.userId).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).set(updates, SetOptions(merge: true));
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
    return query.docs.isEmpty;
  }

  Future<String> createPost(PostModel post, String userId) async {
    final postRef = await _db.collection('posts').add(post.toMap());
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayUnion([postRef.id]),
    });
    return postRef.id;
  }

  Future<void> deletePost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).delete();
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayRemove([postId]),
    });
  }

  Future<String> createDogRecord(DogModel dog, String userId) async {
    final dogRef = await _db.collection('dogs').add(dog.toMap());
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayUnion([dogRef.id]),
    });
    return dogRef.id;
  }

  Future<void> updateDogRecord(String dogId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('dogs').doc(dogId).update(updates);
  }

  Future<void> deleteDogRecord(String dogId, String userId) async {
    final dogDoc = await _db.collection('dogs').doc(dogId).get();
    final dog = DogModel.fromFirestore(dogDoc);
    for (final url in dog.photos) {
      await _deleteImageFromUrl(url);
    }
    await _db.collection('dogs').doc(dogId).delete();
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayRemove([dogId]),
    });
  }

  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('profile_pictures/$userId/profile_$ts.jpg');
    await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<String> uploadProfilePictureBytes(Uint8List bytes, String userId) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('profile_pictures/$userId/profile_$ts.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<String> uploadDogPhoto(File imageFile, String dogId, int index) async {
    final ref = _storage.ref().child('dog_photos/$dogId/photo_$index.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<String> uploadDogPhotoBytes(Uint8List bytes, String dogId, int index) async {
    final ref = _storage.ref().child('dog_photos/$dogId/photo_$index.jpg');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<void> _deleteImageFromUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }

  Future<void> deleteImageFromUrl(String url) async {
    await _deleteImageFromUrl(url);
  }

  Future<void> updateUserDataInPosts(String userId, String newUsername, String newProfilePictureUrl) async {
    final batch = _db.batch();
    final postsQuery = await _db.collection('posts').where('author.userId', isEqualTo: userId).get();
    for (final doc in postsQuery.docs) {
      batch.update(doc.reference, {
        'author.username': newUsername,
        'author.profilePictureUrl': newProfilePictureUrl,
      });
    }
    await batch.commit();
  }
}