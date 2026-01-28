import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

/// A utility to get an [ImageProvider] that works on both Web and Mobile
/// without causing compilation or runtime errors related to dart:io.
ImageProvider getImageProvider(String path) {
  if (kIsWeb) {
    return NetworkImage(path);
  } else {
    // On mobile, we can safely use FileImage because this code
    // is only executed on platforms where dart:io is available.
    return FileImage(io.File(path));
  }
}
