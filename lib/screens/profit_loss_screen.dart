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

  // Initial selected value
  String _selectedOption = 'Live';

  // List of options in the dropdown
  final List<String> _options = ['Live', 'Paper', 'Coinbase'];

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> _getEmailAndFetchStrategies() async {
    String? email = await _secureStorage.read(key: 'email');
    await Provider.of<ProfitlossProvider>(context, listen: false)
        .fetchStrategies(email!, _selectedOption);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              hint: const Text('Select Mode'),
              value: _selectedOption,
              items: _options.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedOption = newValue!;
                });
              },
              onTap: () {
                _getEmailAndFetchStrategies();
              },
            )
          ],
        ),
      ),
    );
  }
}
