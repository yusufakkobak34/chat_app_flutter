import 'package:flutter/material.dart';

class DisplayErrorMessage extends StatelessWidget {
  const DisplayErrorMessage({Key? key, this.error}) : super(key: key);

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Birşeyler yanlış gitti. '
        'Ayarlarınızı kontrol edin. $error',
      ),
    );
  }
}
