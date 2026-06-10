import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/app_data.dart';
import 'google_sign_in_singleton.dart';

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
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  final _googleSignIn = GoogleSignInSingleton.instance;

  User? get currentUser => kIsWeb ? null : _auth.currentUser;
  bool get isSignedIn => !kIsWeb && currentUser != null;
  String? get userEmail => currentUser?.email;
  String? get displayName => currentUser?.displayName;

  Future<bool> signIn() async {
    if (kIsWeb) {
      return false;
    }
    try {
      var account = await _googleSignIn.attemptLightweightAuthentication();
      debugPrint('=== GroupService.signIn: currentUser=$account ===');
      account ??= await _googleSignIn.authenticate();

      debugPrint('=== GroupService.signIn: account=${account.email} ===');
      final auth = account.authentication;
      final authStatus = await account.authorizationClient.authorizeScopes([]);
      debugPrint('=== GroupService.signIn: idToken=${auth.idToken != null} accessToken=true ===');
      final credential = GoogleAuthProvider.credential(
        accessToken: authStatus.accessToken,
        idToken: auth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      debugPrint('=== GroupService.signIn: Firebase user=${result.user?.email} ===');
      return result.user != null;
    } catch (e) {
      debugPrint('=== GroupService.signIn ERROR: $e ===');
      return false;
    }
  }

  Future<bool> signInSilently() async {
    if (kIsWeb) {
      return false;
    }
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account == null) {
        return _auth.currentUser != null;
      }
      final auth = account.authentication;
      final authStatus = await account.authorizationClient.authorizeScopes([]);
      final credential = GoogleAuthProvider.credential(
        accessToken: authStatus.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      return;
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> createGroup(String name, AppData initialData) async {
    if (kIsWeb) {
      return null;
    }
    final uid = currentUser?.uid;
    final email = currentUser?.email;
    if (uid == null) {
      return null;
    }
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
    if (kIsWeb) {
      return false;
    }
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
    if (kIsWeb) {
      return const Stream.empty();
    }
    final email = currentUser?.email?.toLowerCase();
    if (email == null) {
      return const Stream.empty();
    }
    return _db
        .collection('groups')
        .where('memberEmails', arrayContains: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(GroupInfo.fromDoc).toList());
  }

  Stream<AppData?> watchGroupData(String groupId) {
    if (kIsWeb) {
      return const Stream.empty();
    }
    return _db.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      final raw = (doc.data() as Map<String, dynamic>)['data'];
      if (raw == null) {
        return null;
      }
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
    if (kIsWeb) {
      return false;
    }
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
    if (kIsWeb) {
      return;
    }
    final uid = currentUser?.uid;
    final email = currentUser?.email?.toLowerCase();
    if (uid == null) {
      return;
    }
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
      'memberEmails': FieldValue.arrayRemove([email ?? '']),
    });
  }
}
