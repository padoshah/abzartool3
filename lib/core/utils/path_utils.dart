import 'package:path/path.dart' as p;
String normalizedExtension(String path) => p.extension(path).replaceFirst('.', '').toLowerCase();
