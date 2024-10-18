import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/position_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class PositionsScreen extends StatefulWidget {
  @override
  _PositionsScreenState createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  bool isLoading = true;
  String? selectedValue;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _getPosition() async {
    String? email = await _secureStorage.read(key: 'email');
    await Provider.of<PositionProvider>(context, listen: false)
        .fetchPositions(email!, 'coinbase');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedValue,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: "Select Mode"),
              items: const [
                DropdownMenuItem(value: 'live', child: Text('Live')),
                DropdownMenuItem(value: 'paper', child: Text('Paper')),
                DropdownMenuItem(value: 'coinbase', child: Text('Coinbase')),
              ],
              onChanged: (newValue) async {
                setState(() {
                  selectedValue = newValue;
                });
                if (newValue != null) {
                  String? email = await _secureStorage.read(key: 'email');
                  await Provider.of<PositionProvider>(context, listen: false)
                      .fetchPositions(email!, newValue);
                }
              },
            ),
            Expanded(
              child: Consumer<PositionProvider>(
                builder: (context, positionProvider, child) {
                  if (positionProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (positionProvider.error.isNotEmpty) {
                    return Center(child: Text(positionProvider.error));
                  }

                  if (positionProvider.positionResponse?.Positionss.isEmpty ??
                      true) {
                    return Center(child: Text('No positions found'));
                  }

                  // Create DataTable
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Symbol')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Average Price')),
                        DataColumn(label: Text('Market Value')),
                      ],
                      rows: positionProvider.positionResponse!.Positionss.values
                          .map((asset) {
                        return DataRow(cells: [
                          DataCell(Text(asset.symbol)),
                          DataCell(Text('${asset.qty}')),
                          DataCell(Text('${asset.avgPrice}')),
                          DataCell(Text('${asset.marketValue}')),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
