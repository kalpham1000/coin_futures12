import 'package:flutter/material.dart';
import '../services/binance_api_service.dart';
import '../services/binance_websocket_service.dart';
import '../utils/coin_logo_util.dart';

class AppProvider with ChangeNotifier {
  final _api = BinanceApiService();
  final _ws = BinanceWebSocketService();

  final List<Map<String, dynamic>> _coins = [];
  final Set<String> _favoriteSymbols = {}; // 메모리에만 저장

  bool _isInitialized = false;
  bool _isLoading = true;

  // 로고 로딩 상태 추적
  final Set<String> _loadingLogos = {};

  // 게터
  List<Map<String, dynamic>> get allCoins => _coins;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Set<String> get favoriteSymbols => _favoriteSymbols;

  // 초기화 함수
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      print('[AppProvider] Binance 선물 심볼 가져오는 중...');
      final symbols = await _api.fetchUsdtSymbols();

      print('[AppProvider] 총 ${symbols.length}개 선물 코인 로드 완료');
      print('[AppProvider] WebSocket 연결 시작 (전체 코인 구독)');

      _ws.connect(symbols, _updateCoin);
      _isInitialized = true;

    } catch (e) {
      print('[AppProvider] 초기화 중 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 데이터 새로고침
  Future<void> refreshAllData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // WebSocket이 연결되어 있지 않은 경우 REST API로 데이터 가져오기
      if (!_ws.isConnected) {
        final prices = await _api.fetchAllPrices();
        for (var price in prices) {
          _updateCoin(price);
        }
      }

    } catch (e) {
      print('[AppProvider] 데이터 새로고침 중 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateCoin(Map<String, dynamic> coin) {
    final symbol = coin['symbol'] as String;
    final index = _coins.indexWhere((c) => c['symbol'] == symbol);

    // 로고 로드
    _loadLogoIfNeeded(coin);

    if (index == -1) {
      _coins.add(coin);
    } else {
      // 기존 코인 데이터 업데이트 (기존 이미지 URL 유지)
      if (_coins[index]['image'] != null && _coins[index]['image'].toString().isNotEmpty) {
        coin['image'] = _coins[index]['image'];
      }
      _coins[index] = coin;
    }

    notifyListeners();
  }

  void _loadLogoIfNeeded(Map<String, dynamic> coin) async {
    final symbol = coin['symbol'] as String;

    // 이미 로딩 중이거나 로고가 있는 경우 스킵
    if (_loadingLogos.contains(symbol) ||
        (coin['image'] != null && coin['image'].toString().isNotEmpty)) {
      return;
    }

    _loadingLogos.add(symbol);

    // 기본 로고 즉시 설정 (UI가 빠르게 표시되도록)
    coin['image'] = CoinLogoUtil.getDefaultLogo(symbol);
    notifyListeners();

    try {
      // 실제 로고 비동기 로드
      final logoUrl = await CoinLogoUtil.getLogoUrl(symbol);

      // 코인 찾기
      final index = _coins.indexWhere((c) => c['symbol'] == symbol);
      if (index != -1) {
        _coins[index]['image'] = logoUrl;
        notifyListeners();
      }
    } catch (e) {
      print('[AppProvider] ${coin['symbol']} 로고 로딩 중 오류: $e');
    } finally {
      _loadingLogos.remove(symbol);
    }
  }

  // 관심 코인 관리 함수 (메모리에만 저장)
  bool isFavorite(String symbol) {
    return _favoriteSymbols.contains(symbol.toLowerCase());
  }

  void toggleFavorite(String symbol) {
    final lowerSymbol = symbol.toLowerCase();

    if (_favoriteSymbols.contains(lowerSymbol)) {
      _favoriteSymbols.remove(lowerSymbol);
    } else {
      _favoriteSymbols.add(lowerSymbol);
    }

    notifyListeners();
  }

  // 탭별 정렬 및 필터링 함수
  List<Map<String, dynamic>> getFavoriteCoins() {
    return _coins
        .where((coin) => _favoriteSymbols.contains(coin['symbol']))
        .toList();
  }

  List<Map<String, dynamic>> getVolumeLeaders() {
    final sortedCoins = List<Map<String, dynamic>>.from(_coins);
    // 거래대금(quoteVolume) 기준으로 정렬
    sortedCoins.sort((a, b) {
      final quoteVolumeA = double.tryParse(a['quoteVolume'] ?? '0') ?? 0;
      final quoteVolumeB = double.tryParse(b['quoteVolume'] ?? '0') ?? 0;
      return quoteVolumeB.compareTo(quoteVolumeA); // 내림차순
    });
    return sortedCoins.take(50).toList(); // 상위 50개만 반환
  }

  List<Map<String, dynamic>> getTopGainers() {
    final sortedCoins = List<Map<String, dynamic>>.from(_coins);
    // 변동률(change) 기준으로 정렬
    sortedCoins.sort((a, b) {
      final changeA = double.tryParse(a['change'] ?? '0') ?? 0;
      final changeB = double.tryParse(b['change'] ?? '0') ?? 0;
      return changeB.compareTo(changeA); // 내림차순 (상승률 높은 순)
    });
    return sortedCoins.take(50).toList(); // 상위 50개만 반환
  }

  List<Map<String, dynamic>> getTopLosers() {
    final sortedCoins = List<Map<String, dynamic>>.from(_coins);
    // 변동률(change) 기준으로 정렬
    sortedCoins.sort((a, b) {
      final changeA = double.tryParse(a['change'] ?? '0') ?? 0;
      final changeB = double.tryParse(b['change'] ?? '0') ?? 0;
      return changeA.compareTo(changeB); // 오름차순 (하락률 높은 순)
    });
    return sortedCoins.take(50).toList(); // 상위 50개만 반환
  }

  // 코인 검색 함수
  List<Map<String, dynamic>> searchCoins(String query) {
    if (query.isEmpty) {
      return _coins;
    }

    final lowercaseQuery = query.toLowerCase();
    return _coins.where((coin) {
      final symbol = coin['symbol'].toString().toLowerCase();
      final name = coin['name'].toString().toLowerCase();
      return symbol.contains(lowercaseQuery) || name.contains(lowercaseQuery);
    }).toList();
  }

  // 상승 중인 코인 개수 반환
  int getGainersCount() {
    return _coins.where((coin) {
      final double change = double.tryParse(coin['change'] ?? '0') ?? 0;
      return change > 0;
    }).length;
  }

  // 하락 중인 코인 개수 반환
  int getLosersCount() {
    return _coins.where((coin) {
      final double change = double.tryParse(coin['change'] ?? '0') ?? 0;
      return change < 0;
    }).length;
  }

  // 백그라운드 모드 최적화
  void optimizeForBackground() {
    print('[AppProvider] 앱 백그라운드 모드: 데이터 업데이트 최적화');
    _ws.reduceUpdateFrequency();
  }

  // 포그라운드 모드 최적화
  void optimizeForForeground() {
    print('[AppProvider] 앱 포그라운드 모드: 데이터 업데이트 복원');
    _ws.restoreUpdateFrequency();
    refreshAllData(); // 최신 데이터로 새로고침
  }

  @override
  void dispose() {
    _ws.disconnect();
    super.dispose();
  }
}