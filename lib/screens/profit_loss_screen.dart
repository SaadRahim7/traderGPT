import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/provider/profitloss_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class ProfitLossScreen extends StatefulWidget {
  @override
  _ProfitLossScreenState createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  bool isLoading = true;
  List<FlSpot> profitLossData = [];

  String? selectedValue;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> _getEmailAndFetchStrategies() async {
    String? email = await _secureStorage.read(key: 'email');
    await Provider.of<ProfitlossProvider>(context, listen: false)
        .fetchProfitLoss(email!, "coinbase");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getEmailAndFetchStrategies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: selectedValue,
              hint: const Text("Select Mode"),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'live', child: Text('Live')),
                DropdownMenuItem(value: 'paper', child: Text('Paper')),
                DropdownMenuItem(value: 'coinbase', child: Text('Coinbase')),
              ],
              onChanged: (newValue) async {
                setState(() {
                  selectedValue = newValue;
                });
                // if (newValue != null) {
                //   String? email = await _secureStorage.read(key: 'email');
                //   await Provider.of<PositionProvider>(context, listen: false)
                //       .fetchPositions(email!, newValue);
                // }
              },
            ),
          ],
        ),
      ),
    );
  }
}
