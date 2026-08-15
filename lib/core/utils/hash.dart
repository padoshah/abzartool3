import 'dart:io';
import 'package:crypto/crypto.dart';
Future<String> sha256File(File file) => file.openRead().transform(sha256).first.then((digest) => digest.toString());
