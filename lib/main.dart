import 'package:flutter/material.dart';
import 'package:coin_futures/screens/home_screen.dart';
import 'package:coin_futures/screens/news_screen.dart';
import 'package:coin_futures/screens/trading_screen.dart';
import 'package:coin_futures/screens/community_screen.dart';
import 'package:coin_futures/screens/mypage_screen.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final app = AppProvider();
          app.initialize(); // ← WebSocket 동적 구독 시작
          return app;
        }),
      ],
      child: const CoinFuturesApp(),
    ),
  );
}

class CoinFuturesApp extends StatelessWidget {
  const CoinFuturesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coin Futures',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
        ),
      ),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    NewsScreen(),
    TradingScreen(),
    CommunityScreen(),
    MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 앱 라이프사이클 이벤트 구독
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 앱 라이프사이클 이벤트 구독 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱의 상태가 변경될 때 호출되는 메서드
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // 앱이 백그라운드로 갈 때
      appProvider.optimizeForBackground();
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때
      appProvider.optimizeForForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: '뉴스'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: '트레이딩'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: '커뮤니티'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}