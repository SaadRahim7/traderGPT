import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/order_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../provider/strategy_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool isLoading = true;
  String? selectedValue;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? selectedStrategy;

  Future<void> _getEmailAndFetchStrategies() async {
    String? email = await _secureStorage.read(key: 'email');
    await Provider.of<StrategyProvider>(context, listen: false)
        .fetchStrategies(email!);
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
            DropdownButtonFormField<String>(
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
                  await Provider.of<OrderProvider>(context, listen: false)
                      .fetchOrders(email!, newValue);
                }
              },
            ),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, child) {
                  if (orderProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (orderProvider.errorMessage.isNotEmpty) {
                    return Center(child: Text(orderProvider.errorMessage));
                  }

                  if (orderProvider.orders.isEmpty) {
                    return Center(child: Text('No orders found'));
                  }

                  if (selectedValue == "live" || selectedValue == "paper") {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Symbol')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Side')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Filed Quantity')),
                          DataColumn(label: Text('Submitted At')),
                          DataColumn(label: Text('Filled At'))
                        ],
                        rows: orderProvider.orders.map((order) {
                          return DataRow(cells: [
                            DataCell(Text(order.symbol ?? 'N/A')),
                            DataCell(Text("${order.qty ?? 'N/A'}")),
                            DataCell(Text(order.side ?? 'N/A')),
                            DataCell(Text(order.type ?? 'N/A')),
                            DataCell(Text(order.status ?? 'N/A')),
                            DataCell(Text("${order.filledQty ?? 'N/A'}")),
                            DataCell(Text(order.submittedAt ?? 'N/A')),
                            DataCell(Text(order.filledAt ?? 'N/A')),
                          ]);
                        }).toList(),
                      ),
                    );
                  }

                  if (selectedValue == "coinbase") {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product ID')),
                          DataColumn(label: Text('Side')),
                          DataColumn(label: Text('Size')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Value')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created TIme')),
                          DataColumn(label: Text('Client Order Id'))
                        ],
                        rows: orderProvider.orders.map((order) {
                          return DataRow(cells: [
                            DataCell(Text(order.productId ?? 'N/A')),
                            DataCell(Text(order.side ?? 'N/A')),
                            DataCell(Text(order.filledSize ?? 'N/A')),
                            DataCell(Text(order.averageFilledPrice ?? 'N/A')),
                            DataCell(Text(order.filledValue ?? 'N/A')),
                            DataCell(Text("${order.status ?? 'N/A'}")),
                            DataCell(Text(order.createdTime ?? 'N/A')),
                            DataCell(Text(order.clientOrderId ?? 'N/A')),
                          ]);
                        }).toList(),
                      ),
                    );
                  }

                  return Text("Select Mode");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
