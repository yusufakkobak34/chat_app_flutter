import 'dart:async';

import 'package:chatter/screens/screens.dart';
import 'package:chatter/screens/sign_in_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  static Route get route => MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      );
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StreamSubscription<firebase.User?> listener;

  @override
  void initState() {
    super.initState();
    _handleAuthenticatedState();
  }

  Future<void> _handleAuthenticatedState() async {
    final auth = firebase.FirebaseAuth.instance;
    if (!mounted) {
      return;
    }
    listener = auth.authStateChanges().listen((user) async {
      if (user != null) {
        // API kullanıcı token ayarı
        final callable =
            FirebaseFunctions.instance.httpsCallable('getStreamUserToken');

        final results = await Future.wait([
          callable(),
          // Bekleme animasyonu zaman tanımı.
          Future.delayed(const Duration(milliseconds: 700)),
        ]);

        // API kullanıcı bağlantısı
        final client = StreamChatCore.of(context).client;
        await client.connectUser(
          User(id: user.uid),
          results[0]!.data,
        );

        // izin verildi
        Navigator.of(context).pushReplacement(HomeScreen.route);
      } else {
        // Yükleme animasyonu zaman tanımı
        await Future.delayed(const Duration(milliseconds: 700));
        // izin verilmedi
        Navigator.of(context).pushReplacement(SignInScreen.route);
      }
    });
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}