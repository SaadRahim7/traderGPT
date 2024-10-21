import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/logs_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../provider/strategy_provider.dart';

class CloudWatchlog extends StatefulWidget {
  const CloudWatchlog({super.key});

  @override
  State<CloudWatchlog> createState() => _CloudWatchlogState();
}

class _CloudWatchlogState extends State<CloudWatchlog> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? selectedStrategy;
  String? email;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Consumer<StrategyProvider>(
              builder: (context, strategyProvider, child) {
                if (strategyProvider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (strategyProvider.strategies.isEmpty) {
                  return const Text("No strategies available");
                }

                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  hint: const Text('Select a strategy'),
                  value: selectedStrategy,
                  items: strategyProvider.strategies.map((strategy) {
                    return DropdownMenuItem<String>(
                      value: strategy.id,
                      child: Text(
                        strategy.displayName.toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) async {
                    setState(() {
                      selectedStrategy = newValue;
                    });
                    if (newValue != null) {
                      String? email = await _secureStorage.read(key: 'email');
                      await Provider.of<LogProvider>(context, listen: false)
                          .fetchLogs(email!, selectedStrategy!);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (selectedStrategy != null)
              Expanded(
                child: Consumer<LogProvider>(
                  builder: (context, logProvider, child) {
                    if (logProvider.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (logProvider.errorMessage != null) {
                      return Center(child: Text(logProvider.errorMessage!));
                    }
                    return ListView.builder(
                      itemCount: logProvider.logs.length,
                      itemBuilder: (context, index) {
                        final log = logProvider.logs[index];
                        return ListTile(
                          title: Text(log.message),
                        );
                      },
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
