import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase + register all services/repositories via get_it.
  await setupDependencies();

  runApp(const PostSAApp());
}
