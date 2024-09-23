import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lahuu_chat_app/models/chat.dart';
import 'package:lahuu_chat_app/models/message.dart';
import 'package:lahuu_chat_app/models/user_profile.dart';
import 'package:lahuu_chat_app/services/auth_service.dart';
import 'package:get_it/get_it.dart';

class DatabaseService {
  final GetIt _getIt = GetIt.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  late AuthService _authService;

  CollectionReference<Map<String, dynamic>>? _userCollection;
  CollectionReference<Map<String, dynamic>>? _chatCollection;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _setupCollectionReferences();
  }

  void _setupCollectionReferences() {
    _userCollection = _firebaseFirestore.collection('users');
    _chatCollection = _firebaseFirestore.collection('chats');
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    await _userCollection?.doc(userProfile.uid).set(userProfile.toJson());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserProfiles() {
    return _userCollection!
        .where("uid", isNotEqualTo: _authService.user!.uid)
        .snapshots();
  }

  Future<bool> checkChatExists(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final result = await _chatCollection?.doc(chatID).get();
    return result?.exists ?? false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatCollection!.doc(chatID);
    final chat = Chat(id: chatID, participants: [uid1, uid2], messages: []);
    await docRef.set(chat.toJson());
  }

  Future<void> sendChatMessage(String uid1, String uid2, Message message) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatCollection!.doc(chatID);
    await docRef.update({
      "messages": FieldValue.arrayUnion([message.toJson()]),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getChatData(String uid1, String uid2) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    return _chatCollection!.doc(chatID).snapshots();
  }

  // This is the helper function to generate the chat ID
  String generateChatID({required String uid1, required String uid2}) {
    if (uid1.compareTo(uid2) > 0) {
      return '$uid1-$uid2';
    } else {
      return '$uid2-$uid1';
    }
  }
}
