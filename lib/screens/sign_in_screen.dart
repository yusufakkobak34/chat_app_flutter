import 'package:chatter/screens/screens.dart';
import 'package:chatter/screens/sign_up_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

import '../app.dart';

class SignInScreen extends StatefulWidget {
  static Route get route => MaterialPageRoute(
        builder: (context) => const SignInScreen(),
      );
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final auth = firebase.FirebaseAuth.instance;
  final functions = FirebaseFunctions.instance;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  bool _loading = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });
      try {
        // Firebase ile yetkilendirme
        final creds =
            await firebase.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        final user = creds.user;

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı bulunamadı')),
          );
          return;
        }

        
        final callable = functions.httpsCallable('getStreamUserToken');
        final results = await callable();

        final client = StreamChatCore.of(context).client;
        await client.connectUser(
          User(id: creds.user!.uid),
          results.data,
        );

        
        await Navigator.of(context).pushReplacement(HomeScreen.route);
      } on firebase.FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Yetki hatası')),
        );
      } catch (e, st) {
        logger.e('Giriş hatası, ', e, st);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('hata oluştu')),
        );
      }
      setState(() {
        _loading = false;
      });
    }
  }

  String? _emailInputValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Boş kalamaz';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Geçerli bir e posta değil';
    }
    return null;
  }

  String? _passwordInputValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Boş kalamaz';
    }
    if (value.length <= 6) {
      return 'Şifreniz 6 karakterden uzun olmak zorundadır.';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHATTER'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 24),
                        child: Text(
                          'Hoş geldiniz',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _emailController,
                          validator: _emailInputValidator,
                          decoration: const InputDecoration(hintText: 'E-mail'),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _passwordController,
                          validator: _passwordInputValidator,
                          decoration: const InputDecoration(
                            hintText: 'Şifre',
                          ),
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: _signIn,
                          child: const Text(
                            'Giriş yap',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Hesabınız yok mu?',
                              style: Theme.of(context).textTheme.subtitle2),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(SignUpScreen.route);
                            },
                            child: const Text('Hesap oluşturun'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}