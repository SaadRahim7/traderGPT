import 'package:flutter/material.dart';

import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../provider/strategie_code_provider.dart';
import '../provider/strategy_provider.dart';

class StrategyCodeScreen extends StatefulWidget {
  const StrategyCodeScreen({super.key});

  @override
  State<StrategyCodeScreen> createState() => _StrategyCodeScreenState();
}

class _StrategyCodeScreenState extends State<StrategyCodeScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? selectedStrategy;
  String? email;

  Future<void> _getEmailAndFetchStrategies() async {
    email = await _secureStorage.read(key: 'email');

    await Provider.of<StrategyProvider>(context, listen: false)
        .fetchStrategies(email!);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getEmailAndFetchStrategies();
      // data();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        await Provider.of<StrategiesCodeProvider>(context,
                                listen: false)
                            .fetchStratrgieCode(email!, selectedStrategy!);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              if (selectedStrategy != null)
                Consumer<StrategiesCodeProvider>(
                  builder: (BuildContext context, StrategiesCodeProvider value,
                      Widget? child) {
                    if (value.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return HighlightView(
                      value.refector!,
                      language: 'python',
                      theme: darculaTheme,
                      padding: EdgeInsets.all(12),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
