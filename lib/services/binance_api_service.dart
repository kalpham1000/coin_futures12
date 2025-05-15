import 'dart:convert';
import 'package:http/http.dart' as http;

class BinanceApiService {
  final String _baseUrl = 'https://fapi.binance.com';
  final String _exchangeInfoUrl = '/fapi/v1/exchangeInfo';
  final String _tickerPriceUrl = '/fapi/v1/ticker/price';
  final String _24hTickerUrl = '/fapi/v1/ticker/24hr';

  Future<List<String>> fetchUsdtSymbols() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_exchangeInfoUrl'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final symbols = data['symbols'] as List;

        // 필터링 완화: 거래 중인 모든 USDT 선물 포함 (계약 타입 제한 없음)
        final filteredSymbols = symbols
            .where((item) =>
        item['symbol'].toString().endsWith('USDT') &&
            item['status'] == 'TRADING'
          // contractType 조건 제거하여 모든 계약 타입 포함
        )
            .map<String>((item) => item['symbol'].toString().toLowerCase())
            .toList();

        print('[BinanceAPI] ${filteredSymbols.length}개 USDT 선물 심볼 로드됨');
        return filteredSymbols;
      } else {
        throw Exception('Binance API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('[BinanceAPI] 선물 심볼 로드 실패: $e');
      throw Exception('Binance API 호출 중 오류: $e');
    }
  }

  // 가격 정보 일괄 가져오기 (WebSocket 백업용)
  Future<List<Map<String, dynamic>>> fetchAllPrices() async {
    try {
      // 24시간 티커 정보 가져오기 (더 많은 정보 포함)
      final response = await http.get(Uri.parse('$_baseUrl$_24hTickerUrl'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data
            .where((item) => item['symbol'].toString().endsWith('USDT'))
            .map<Map<String, dynamic>>((item) {
          final symbol = item['symbol'].toString();
          final baseSymbol = symbol.replaceAll('USDT', '').toLowerCase();
          final priceChangePercent = double.tryParse(item['priceChangePercent'] ?? '0') ?? 0;

          return {
            'symbol': baseSymbol,
            'name': baseSymbol.toUpperCase(),
            'price': item['lastPrice'],
            'change': priceChangePercent.toStringAsFixed(2),
            'volume': item['volume'],
            'quoteVolume': item['quoteVolume'],
            'high': item['highPrice'],
            'low': item['lowPrice'],
            'fullSymbol': symbol,
          };
        })
            .toList();
      } else {
        throw Exception('가격 정보 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('[BinanceAPI] 가격 정보 로드 실패: $e');
      throw Exception('가격 API 호출 중 오류: $e');
    }
  }
}