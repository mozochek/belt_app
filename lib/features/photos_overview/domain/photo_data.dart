import 'dart:io' as io;

import 'package:flutter/foundation.dart';

@immutable
class PhotoData {
  final io.File file;

  const PhotoData(this.file);
}
