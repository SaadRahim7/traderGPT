import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/provider/community_strategies_provider.dart';
import 'package:flutter_application_1/provider/order_provider.dart';
import 'package:flutter_application_1/provider/position_provider.dart';
import 'package:flutter_application_1/provider/profitloss_provider.dart';
import 'package:flutter_application_1/provider/stock_chart_provider.dart';
import 'package:flutter_application_1/provider/watchlist_provider.dart';

import 'package:provider/provider.dart';

// Import your screens and services
import 'provider/coinbase_provider.dart';
import 'provider/strategy_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/openai_service.dart';
import 'services/backtest_service.dart';
import 'services/brokerage_service.dart';
import 'firebase_options.dart';

// Constants for API keys
const String OPENAI_API_KEY =
    'sk-FEYtSBBL3ribPTxx1fngsASLcu_eBSAWV9IAfgsVbdT3BlbkFJnYIq86GEe4wnreHxwGoi6gY2UpiSkF8oBgbD1W9RwA';
const String FIREBASE_API_KEY = 'AIzaSyDzBdEiQI9461Tk4crenGSdDAjPU6BhPV4';
const String FIREBASE_AUTH_DOMAIN = 'tradergpt-396cc.firebaseapp.com';
const String FIREBASE_PROJECT_ID = 'tradergpt-396cc';
const String FIREBASE_STORAGE_BUCKET = 'tradergpt-396cc.appspot.com';
const String FIREBASE_MESSAGING_SENDER_ID = '103720545016305528532';
const String FIREBASE_APP_ID = '1:960616245650:web:aaba4bd8b7b4beaedb794b';
const String ALPACA_API_KEY = 'PK8AMWG1KBUUNIBCZCF9';
const String ALPACA_SECRET_KEY = 'acKHBHocgCNwNWUfXL7QI8JRzyXYAGRrDUvoLBbw';
const String COINBASE_CLIENT_ID = 'd68e4f5f-379e-4748-a975-f1f1d219c902';
const String COINBASE_CLIENT_SECRET = '   ';
const String PAYPAL_CLIENT_ID =
    'AbK-PsmCJ84qQFIPff4tiXLjjY7_o6YOeNGwLLCg9c97L2sLd8K6bxBLXkf1x_XuJZyRP6EpFdO0pnOf';
const String SECRET_KEY = 'your_secret_key';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // {{ edit_main_2 }} Initialize WebView for Android
  // WebView.platform = SurfaceAndroidWebView();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ensure to await this call

  // Run the app
  runApp(TraderGPTApp());
}

class TraderGPTApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<OpenAIService>(create: (_) => OpenAIService()),
        ChangeNotifierProvider<BacktestService>(
            create: (_) => BacktestService()),
        ChangeNotifierProvider<BrokerageService>(
            create: (_) => BrokerageService()),
        ChangeNotifierProvider<StockProvider>(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => CoinbaseProvider()),
        ChangeNotifierProvider(create: (_) => StrategyProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => ProfitlossProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PositionProvider()),
        ChangeNotifierProvider(create: (_) => CommunityStrategiesProvider()),
      ],
      child: MaterialApp(
        title: 'TraderGPT',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.green[700],
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green[900],
            elevation: 0,
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
            bodySmall: TextStyle(color: Colors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[500]!),
            ),
            fillColor: Colors.grey[900],
            filled: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
          dialogBackgroundColor: Colors.grey[900], // Add this line
          dialogTheme: DialogTheme(
            // Add this block
            titleTextStyle: TextStyle(color: Colors.white),
            contentTextStyle: TextStyle(color: Colors.white),
          ),
        ),
        // home: StockChartScreen(),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return DashboardScreen();
          } else {
            return LoginScreen();
          }
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
