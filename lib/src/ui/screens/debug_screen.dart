
import 'package:go_router/go_router.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/debug/response_logger.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug Info'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'DB Tables'),
              Tab(text: 'JSON Responses'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DbTablesView(),
            JsonResponsesView(),
          ],
        ),
      ),
    );
  }
}

class DbTablesView extends StatefulWidget {
  const DbTablesView({super.key});

  @override
  State<DbTablesView> createState() => _DbTablesViewState();
}

class _DbTablesViewState extends State<DbTablesView> {
  List<String> _tables = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
    });
    final tables = await DatabaseHelper.instance.getTables();
    setState(() {
      _tables = tables;
      _isLoading = false;
    });
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _isLoading = true;
    });
    final data = await DatabaseHelper.instance.getTableData(tableName);
    setState(() {
      _tableData = data;
      _selectedTable = tableName;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          hint: const Text('Select a table'),
          value: _selectedTable,
          onChanged: (String? newValue) {
            if (newValue != null) {
              _loadTableData(newValue);
            }
          },
          items: _tables.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_tableData.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No data in this table.'),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: _tableData.first.keys
                      .map((k) => DataColumn(label: Text(k)))
                      .toList(),
                  rows: _tableData
                      .map((row) => DataRow(
                            cells: row.values
                                .map((v) => DataCell(Text(v.toString())))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class JsonResponsesView extends ConsumerWidget {
  const JsonResponsesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(responseLoggerProvider);
    const jsonEncoder = JsonEncoder.withIndent('  ');

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ExpansionTile(
          title: Text('${log.method} ${log.url} (${log.statusCode})'),
          subtitle: Text(log.timestamp.toIso8601String()),
          children: [
            Container(
              color: Colors.black26,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(
                jsonEncoder.convert(log.data),
              ),
            ),
          ],
        );
      },
    );
  }
}
