import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/logs.dart';
import 'package:flutter_application_1/screens/strategy_code_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../provider/coinbase_provider.dart';
import 'login_screen.dart';
import 'account_screen.dart';
import 'positions_screen.dart';
import 'orders_screen.dart';
import 'profit_loss_screen.dart';
import 'community_screen.dart';
import 'watchlist_screen.dart';
import 'backtest_screen.dart';
import 'strategy_screen.dart';
import '../services/auth_service.dart';

// class DashboardScreen extends StatefulWidget {
//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   int _currentIndex = 0;
//   final storage = FlutterSecureStorage();

//   final List<Widget> _tabs = [
//     StrategyScreen(),
//     BacktestScreen(),
//     PositionsScreen(),
//     OrdersScreen(),
//     ProfitLossScreen(),
//     CommunityScreen(),
//     WatchlistScreen(),
//     const StrategyCodeScreen(),
//     AccountScreen(),
//   ];

//   final List<String> _titles = [
//     'Strategy',
//     'Backtest',
//     'Positions',
//     'Orders',
//     'Profit & Loss',
//     'Community',
//     'Watchlist',
//     'Strategy Code',
//     'Account',
//   ];

//   void _onTabTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   void _logout() {
//     final authService = Provider.of<AuthService>(context, listen: false);
//     authService.signOut();
//     // Navigate back to Login Screen
//     Navigator.pushReplacement(
//         context, MaterialPageRoute(builder: (context) => LoginScreen()));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final coinbaseProvider = Provider.of<CoinbaseProvider>(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_titles[_currentIndex]),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               coinbaseProvider.resetCoinbaseConnection();
//               await storage.deleteAll();
//               _logout();
//             },
//           )
//         ],
//       ),
//       body: _tabs[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white,
//         selectedItemColor: Colors.green[500],
//         unselectedItemColor: Colors.white,
//         currentIndex: _currentIndex,
//         onTap: _onTabTapped,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Strategy'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.show_chart), label: 'Backtest'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.pie_chart), label: 'Positions'),
//           BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.attach_money), label: 'Profit & Loss'),
//           BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Community'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.favorite), label: 'Watchlist'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.code), label: 'Strategy Code'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.account_circle), label: 'Account'),
//         ],
//       ),
//     );
//   }
// }

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final storage = FlutterSecureStorage();

  final List<Widget> _tabs = [
    StrategyScreen(),
    BacktestScreen(),
    PositionsScreen(),
    OrdersScreen(),
    ProfitLossScreen(),
    CommunityScreen(),
    WatchlistScreen(),
    CloudWatchlog(),
    const StrategyCodeScreen(),
    AccountScreen(),
  ];

  final List<String> _titles = [
    'Strategy',
    'Backtest',
    'Positions',
    'Orders',
    'Profit & Loss',
    'Community',
    'Watchlist',
    'Logs',
    'Strategy Code',
    'Account',
  ];

  void _onDrawerItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selection
  }

  void _logout() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
    // Navigate back to Login Screen
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final coinbaseProvider = Provider.of<CoinbaseProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              coinbaseProvider.resetCoinbaseConnection();
              await storage.deleteAll();
              _logout();
            },
          )
        ],
      ),
      body: _tabs[_currentIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Trader GPT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            for (int index = 0; index < _titles.length; index++)
              ListTile(
                leading: Icon(_getIconForIndex(index)),
                title: Text(_titles[index]),
                onTap: () => _onDrawerItemTapped(index),
              ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                coinbaseProvider.resetCoinbaseConnection();
                await storage.deleteAll();
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.code;
      case 1:
        return Icons.show_chart;
      case 2:
        return Icons.pie_chart;
      case 3:
        return Icons.list_alt;
      case 4:
        return Icons.attach_money;
      case 5:
        return Icons.group;
      case 6:
        return Icons.favorite;
      case 7:
        return Icons.terminal;
      case 8:
        return Icons.code;
      case 9:
        return Icons.account_circle;

      default:
        return Icons.help; // Fallback icon
    }
  }
}
