import 'package:flutter/material.dart';
import 'package:logger/logger.dart' as log;
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

const streamKey = 'mdvuwr8yfznc'; 

var logger = log.Logger();


extension StreamChatContext on BuildContext {
  /// Kullanıcı resmini tespit eder.
  String? get currentUserImage => currentUser!.image;

  /// Kullanıcıyı tespit eder.
  User? get currentUser => StreamChatCore.of(this).currentUser;
}
