import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:drift/web/worker.dart';

/// Obtains a database connection for running drift on the web.
QueryExecutor connect() {
  return DatabaseConnection.delayed(
    connectToDriftWorker(
      kReleaseMode ? 'worker.dart.min.js' : 'worker.dart.js',
      mode: DriftWorkerMode.shared,
    ),
  );
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {}
