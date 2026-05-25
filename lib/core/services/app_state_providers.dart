import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<Locale>((_) => const Locale('ru'));
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);
