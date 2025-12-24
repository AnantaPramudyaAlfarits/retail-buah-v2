import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../widgets/theme_toggle_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final dio = Dio();
  List logs = [];
  String get url => kIsWeb ? 'http://localhost:3000/api/transactions' : 'http://10.0.2.2:3000/api/transactions';

  @override
  void initState() { super.initState(); fetch(); }

  Future<void> fetch() async {
    final res = await dio.get(url);
    setState(() => logs = res.data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Penjualan"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(logs[i]['product_name'] ?? 'Unknown'),
          subtitle: Text("Terjual: ${logs[i]['quantity'] ?? 0} | Total: Rp ${logs[i]['total_price'] ?? 0}"),
          trailing: Text(logs[i]['tanggal'].toString().substring(0, 10)),
        ),
      ),
    );
  }
}