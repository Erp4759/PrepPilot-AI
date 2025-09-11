import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/app.dart';
import 'src/bootstrap/bootstrap.dart';

void main() => bootstrap(() => const ProviderScope(child: PrepPilotApp()));
