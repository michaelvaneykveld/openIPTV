import 'slow_query_log_writer_stub.dart'
    if (dart.library.io) 'slow_query_log_writer_io.dart'
    as impl;

Future<void> writeSlowQueryLine(String line) => impl.writeSlowQueryLine(line);
