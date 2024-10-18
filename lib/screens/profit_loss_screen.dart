import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/profitloss_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfitLossScreenState createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  bool isLoading = true;
  String? selectedValue;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
                if (newValue != null) {
                  String? email = await _secureStorage.read(key: 'email');
                  await Provider.of<ProfitlossProvider>(context, listen: false)
                      .fetchProfitLoss(email!, selectedValue!);
                }
              },
            ),
            Expanded(
              child: Consumer<ProfitlossProvider>(
                builder: (context, profitlossProvider, child) {
                  if (profitlossProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (profitlossProvider.errorMessage!.isNotEmpty) {
                    return Center(
                        child: Text(profitlossProvider.errorMessage!));
                  }

                  if (selectedValue == "live" || selectedValue == "paper") {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Strategy ID')),
                          DataColumn(label: Text('Profit/Loss')),
                        ],
                        rows: profitlossProvider
                            .profitloss!.profitLossByStrategy!.entries
                            .map(
                              (entry) => DataRow(
                                cells: [
                                  DataCell(Text(entry.key)),
                                  DataCell(Text(entry.value.toString())),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }

                  if (selectedValue == 'coinbase') {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product ID')),
                          DataColumn(label: Text('Realized Profit/Loss')),
                          DataColumn(label: Text('Unrealized Profit/Loss')),
                          DataColumn(label: Text('Total Profit/Loss')),
                        ],
                        rows: profitlossProvider.profitloss!.productWisePl!
                            .map((order) {
                          return DataRow(cells: [
                            DataCell(Text(order.productId)),
                            DataCell(Text("${order.realizedPl}")),
                            DataCell(Text("${order.unrealizedPl}")),
                            DataCell(Text("${order.totalPl}")),
                          ]);
                        }).toList(),
                      ),
                    );
                  }

                  return Center(child: Text("Select Mode"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
