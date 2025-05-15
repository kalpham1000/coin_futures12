// coin_logo_util.dart 개선
import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinLogoUtil {
  static final Map<String, String> _cache = {};
  static List<dynamic>? _coingeckoList;
  static final Map<String, String> _symbolMapping = {
    // Binance 심볼 -> CoinGecko 심볼 매핑
    'jst': 'just',
    'ont': 'ontology',
    'vet': 'vechain',
    'vtho': 'vethor-token',
    'hot': 'holo',
    'yfi': 'yearn-finance',
    'ftt': 'ftx-token',
    'bnx': 'binaryx',
    'mask': 'mask-network',
    // 더 많은 매핑 추가 가능
  };

  static String getDefaultLogo(String symbol) {
    return 'https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@bea1a9722a8c63169dcc06e86182bf2c55a76bbc/128/color/${symbol.toLowerCase()}.png';
  }

  static Future<String> getLogoUrl(String symbol) async {
    final lower = symbol.toLowerCase();

    // 캐시 확인
    if (_cache.containsKey(lower)) {
      return _cache[lower]!;
    }

    // 기본 로고 URL 즉시 캐싱 (UI 빠른 표시용)
    _cache[lower] = getDefaultLogo(lower);

    try {
      // 1. 가장 신뢰성 높은 이미지 소스 시도
      final binanceLogoUrl = 'https://bin.bnbstatic.com/image/admin_mgs_image_upload/20201110/87496d50-6941-43b4-90c3-3e3896654468.png';
      final coinbaseLogoUrl = 'https://dynamic-assets.coinbase.com/dbb4b4983bde81309ddab83eb598358eb44375b930b94687ebe38bc22e52c3b2125258ffb8477a5ef22e33d6bd72e32a506c391caa13af64c00e46613c3e5806/icon_${lower}.png';

      // 2. CoinGecko API 시도 (심볼 매핑 사용)
      final adjustedSymbol = _symbolMapping[lower] ?? lower;

      if (_coingeckoList == null) {
        try {
          final listUrl = 'https://api.coingecko.com/api/v3/coins/list';
          final res = await http.get(Uri.parse(listUrl));
          if (res.statusCode == 200) {
            _coingeckoList = jsonDecode(res.body);
            print('[CoinLogoUtil] CoinGecko 코인 목록 로드 완료 (${_coingeckoList!.length}개)');
          }
        } catch (e) {
          print('[CoinLogoUtil] CoinGecko 목록 로드 실패: $e');
        }
      }

      if (_coingeckoList != null) {
        // 정확한 매칭과 유사 매칭 모두 시도
        final exactMatches = _coingeckoList!.where(
                (item) => item['symbol'].toString().toLowerCase() == adjustedSymbol
        ).toList();

        final similarMatches = _coingeckoList!.where(
                (item) => item['symbol'].toString().toLowerCase().contains(adjustedSymbol) ||
                item['id'].toString().toLowerCase().contains(adjustedSymbol)
        ).toList();

        final matches = exactMatches.isNotEmpty ? exactMatches : similarMatches;

        if (matches.isNotEmpty) {
          try {
            final id = matches.first['id'];
            final detailUrl = 'https://api.coingecko.com/api/v3/coins/$id';
            final detailRes = await http.get(Uri.parse(detailUrl));

            if (detailRes.statusCode == 200) {
              final data = jsonDecode(detailRes.body);
              if (data['image'] != null && data['image']['small'] != null) {
                final imageUrl = data['image']['small'];
                _cache[lower] = imageUrl;
                return imageUrl;
              }
            }
          } catch (e) {
            print('[CoinLogoUtil] $lower 코인 상세정보 로드 실패: $e');
          }
        }
      }

      // 3. 대체 이미지 소스들 시도
      final alternateUrls = [
        'https://cryptoicons.org/api/icon/$lower/200',
        'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/$lower.png',
        'https://s2.coinmarketcap.com/static/img/coins/64x64/${_getNumericId(lower)}.png',
      ];

      for (final url in alternateUrls) {
        try {
          final response = await http.head(Uri.parse(url));
          if (response.statusCode == 200) {
            _cache[lower] = url;
            return url;
          }
        } catch (e) {
          // 자동으로 다음 URL 시도
        }
      }

      // 모든 방법 실패 시 기본 로고 사용
      return _cache[lower]!;

    } catch (e) {
      print('[CoinLogoUtil] $lower 로고 로딩 중 오류: $e');
      return _cache[lower]!;
    }
  }

  // CoinMarketCap 스타일 ID 추정 (실제 정확한 ID를 알 수 없음)
  static int _getNumericId(String symbol) {
    // 인기 코인들의 ID는 직접 매핑
    final Map<String, int> popularIds = {
      'btc': 1, 'eth': 1027, 'bnb': 1839, 'sol': 5426,
      'xrp': 52, 'ada': 2010, 'doge': 74, 'dot': 6636
    };

    if (popularIds.containsKey(symbol)) {
      return popularIds[symbol]!;
    }

    // 심볼을 해시하여 1000-9999 사이의 숫자 생성
    int hash = 0;
    for (int i = 0; i < symbol.length; i++) {
      hash = (hash * 31 + symbol.codeUnitAt(i)) % 9000;
    }
    return hash + 1000; // 1000-9999 범위
  }
}