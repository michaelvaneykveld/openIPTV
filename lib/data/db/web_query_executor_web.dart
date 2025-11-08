// ignore_for_file: deprecated_member_use

import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor createWebQueryExecutor() {
  return WebDatabase(
    'openiptv_web.db',
    logStatements: false,
  );
}
