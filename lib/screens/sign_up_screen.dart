import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

import '../app.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  static Route get route => MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final auth = firebase.FirebaseAuth.instance;
  final functions = FirebaseFunctions.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _profilePictureController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  bool _loading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });
      try {
        // Firebase yetkilendirmesi
        final creds =
            await firebase.FirebaseAuth.instance.createUserWithEmailAndPassword(
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

        // ,Firebase isim ve fotoğraf ayarları tanımı
        List<Future<void>> futures = [
          creds.user!.updateDisplayName(_nameController.text),
          if (_profilePictureController.text.isNotEmpty)
            creds.user!.updatePhotoURL(_profilePictureController.text)
        ];

        await Future.wait(futures);

        // API kullanıcı oluşturma ve token değerini alma
        final callable = functions.httpsCallable('createStreamUserAndGetToken');
        final results = await callable();

        // Kullanıcıyı API'ye bağlama ve verisini çekme
        final client = StreamChatCore.of(context).client;
        await client.connectUser(
          User(
            id: creds.user!.uid,
            name: _nameController.text,
            image: _profilePictureController.text,
          ),
          results.data,
        );

        // Ana ekrana dönüş
        await Navigator.of(context).pushReplacement(HomeScreen.route);
      } on firebase.FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Yetki hatası')),
        );
      } catch (e, st) {
        logger.e('Giriş hatası', e, st);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hata oluştu')),
        );
      }
      setState(() {
        _loading = false;
      });
    }
  }

  String? _nameInputValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Boş kalamaz';
    }
    return null;
  }

  String? _emailInputValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Boş kalamaz';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Geçerli bir e posta girin';
    }
    return null;
  }

  String? _passwordInputValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Boş kalamaz';
    }
    if (value.length <= 6) {
      return 'Şifreniz 6 karakterden büyük olmak zorundadır';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _profilePictureController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHATTER'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: (_loading)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 24),
                        child: Text(
                          'Kayıt ol',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _nameController,
                          validator: _nameInputValidator,
                          decoration: const InputDecoration(hintText: 'İsim'),
                          keyboardType: TextInputType.name,
                          autofillHints: const [
                            AutofillHints.name,
                            AutofillHints.username
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _profilePictureController,
                          decoration:
                              const InputDecoration(hintText: 'Resim URL'),
                          keyboardType: TextInputType.url,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _emailController,
                          validator: _emailInputValidator,
                          decoration: const InputDecoration(hintText: 'E-Mail'),
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
                          onPressed: _signUp,
                          child: const Text('Kayıt ol'),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Hesabınız var mı?',
                              style: Theme.of(context).textTheme.subtitle2),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Giriş yap'),
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