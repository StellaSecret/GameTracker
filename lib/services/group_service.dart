import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_data.dart';
 
class GroupInfo {
  final String id;
  final String name;
  final String createdBy;
  final List<String> memberEmails;
  final DateTime createdAt;
 
  const GroupInfo({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.memberEmails,
    required this.createdAt,
  });
 
  factory GroupInfo.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GroupInfo(
      id: doc.id,
      name: d['name'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      memberEmails: List<String>.from(d['memberEmails'] as List? ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
 
class GroupService {
  // Lazy getters so Firestore/Auth are never accessed on web at construction time.
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
 
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
 
  User? get currentUser => kIsWeb ? null : _auth.currentUser;
  bool get isSignedIn => !kIsWeb && currentUser != null;
  String? get userEmail => currentUser?.email;
  String? get displayName => currentUser?.displayName;
 
  // ── Auth ──────────────────────────────────────────────────────────────────
 
  Future<bool> signIn() async {
    if (kIsWeb) return false;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }
 
  Future<bool> signInSilently() async {
    if (kIsWeb) return false;
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return _auth.currentUser != null;
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }
 
  Future<void> signOut() async {
    if (kIsWeb) return;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
 
  // ── Groups ────────────────────────────────────────────────────────────────
 
  Future<String?> createGroup(String name, AppData initialData) async {
    if (kIsWeb) return null;
    final uid = currentUser?.uid;
    final email = currentUser?.email;
    if (uid == null) return null;
    try {
      final ref = await _db.collection('groups').add({
        'name': name,
        'createdBy': uid,
        'members': [uid],
        'memberEmails': [email ?? ''],
        'createdAt': FieldValue.serverTimestamp(),
        'data': initialData.toJson(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }
 
  Future<bool> inviteMember(String groupId, String email) async {
    if (kIsWeb) return false;
    try {
      await _db.collection('groups').doc(groupId).update({
        'memberEmails': FieldValue.arrayUnion([email.trim().toLowerCase()]),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
 
  Stream<List<GroupInfo>> watchMyGroups() {
    if (kIsWeb) return const Stream.empty();
    final email = currentUser?.email?.toLowerCase();
    if (email == null) return const Stream.empty();
    return _db
        .collection('groups')
        .where('memberEmails', arrayContains: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(GroupInfo.fromDoc).toList());
  }
 
  Stream<AppData?> watchGroupData(String groupId) {
    if (kIsWeb) return const Stream.empty();
    return _db.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final raw = (doc.data() as Map<String, dynamic>)['data'];
      if (raw == null) return null;
      try {
        final json = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        return AppData.fromJson(json);
      } catch (_) {
        return null;
      }
    });
  }
 
  Future<bool> pushGroupData(String groupId, AppData data) async {
    if (kIsWeb) return false;
    try {
      await _db.collection('groups').doc(groupId).update({
        'data': data.toJson(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
 
  Future<void> leaveGroup(String groupId) async {
    if (kIsWeb) return;
    final uid = currentUser?.uid;
    final email = currentUser?.email?.toLowerCase();
    if (uid == null) return;
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
      'memberEmails': FieldValue.arrayRemove([email ?? '']),
    });
  }
}
