import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'dart:async';

class BinanceWebSocketService {
  // 각 WebSocket 연결 관리
  final List<IOWebSocketChannel> _channels = [];
  bool _isConnected = false;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  // Binance WebSocket 연결당 최대 스트림 수
  static const int MAX_STREAMS_PER_CONNECTION = 200;

  // 콜백 보관
  Function(Map<String, dynamic>)? _onCoinUpdate;
  List<String>? _symbols;

  bool get isConnected => _isConnected;

  void connect(List<String> symbols, Function(Map<String, dynamic>) onCoinUpdate) {
    _symbols = symbols;
    _onCoinUpdate = onCoinUpdate;
    _connectWebSockets();
  }

  void _connectWebSockets() {
    if (_symbols == null || _symbols!.isEmpty || _onCoinUpdate == null) {
      print('[BinanceWS] 연결 실패: 심볼 또는 콜백이 설정되지 않음');
      return;
    }

    // 기존 연결 해제
    _closeAllConnections();

    // 심볼을 MAX_STREAMS_PER_CONNECTION 크기의 청크로 나누기
    final List<List<String>> symbolChunks = [];
    for (int i = 0; i < _symbols!.length; i += MAX_STREAMS_PER_CONNECTION) {
      final end = (i + MAX_STREAMS_PER_CONNECTION < _symbols!.length)
          ? i + MAX_STREAMS_PER_CONNECTION
          : _symbols!.length;
      symbolChunks.add(_symbols!.sublist(i, end));
    }

    print('[BinanceWS] ${symbolChunks.length}개의 WebSocket 연결로 ${_symbols!.length}개 심볼 구독');

    // 각 청크에 대해 별도의 WebSocket 연결 생성
    for (int i = 0; i < symbolChunks.length; i++) {
      final chunk = symbolChunks[i];
      _connectSingleWebSocket(chunk, i);
    }

    // 핑 타이머 시작
    _startPingTimer();
  }

  void _connectSingleWebSocket(List<String> symbols, int connectionIndex) {
    final streams = symbols.map((s) => '$s@ticker').join('/');
    final url = 'wss://fstream.binance.com/stream?streams=$streams';

    print('[BinanceWS] 연결 #$connectionIndex: ${symbols.length}개 심볼');

    try {
      final channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        pingInterval: const Duration(minutes: 2),
      );

      _channels.add(channel);

      channel.stream.listen(
            (message) {
          try {
            final parsed = jsonDecode(message);
            final data = parsed['data'];

            if (data != null) {
              final symbol = data['s']; // 예: BTCUSDT

              if (symbol != null && symbol.toString().endsWith('USDT')) {
                final baseSymbol = symbol.toString().replaceAll('USDT', '').toLowerCase();
                final priceChangePercent = double.tryParse(data['P'] ?? '0') ?? 0;

                _onCoinUpdate!({
                  'symbol': baseSymbol,
                  'name': baseSymbol.toUpperCase(),
                  'price': data['c'],
                  'change': priceChangePercent.toStringAsFixed(2),
                  'volume': data['v'],
                  'quoteVolume': data['q'], // USDT 거래대금
                  'high': data['h'],
                  'low': data['l'],
                  'fullSymbol': symbol,
                });
              }
            }
          } catch (e) {
            print('[BinanceWS] 데이터 파싱 오류: $e');
          }
        },
        onDone: () {
          print('[BinanceWS] 연결 #$connectionIndex 종료');
          _scheduleReconnect();
        },
        onError: (error) {
          print('[BinanceWS] 연결 #$connectionIndex 오류: $error');
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;

    } catch (e) {
      print('[BinanceWS] 연결 #$connectionIndex 시도 중 오류: $e');
      _scheduleReconnect();
    }
  }

  void _closeAllConnections() {
    for (var channel in _channels) {
      try {
        channel.sink.close();
      } catch (e) {
        print('[BinanceWS] 연결 해제 중 오류: $e');
      }
    }
    _channels.clear();
    _isConnected = false;
  }

  void _startPingTimer() {
    _cancelPingTimer();
    _pingTimer = Timer.periodic(const Duration(minutes: 4), (timer) {
      if (_isConnected && _channels.isNotEmpty) {
        try {
          // 모든 채널에 핑 메시지 전송
          for (var channel in _channels) {
            channel.sink.add(jsonEncode({'method': 'PING'}));
          }
          print('[BinanceWS] 전체 채널에 핑 메시지 전송');
        } catch (e) {
          print('[BinanceWS] 핑 전송 오류: $e');
        }
      }
    });
  }

  void _cancelPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[BinanceWS] 최대 재연결 시도 횟수 초과');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    print('[BinanceWS] ${delay.inSeconds}초 후 재연결 시도 (시도 ${_reconnectAttempts}/${_maxReconnectAttempts})');

    Future.delayed(delay, () {
      if (_channels.isEmpty) {
        _connectWebSockets();
      }
    });
  }

  void disconnect() {
    _cancelPingTimer();
    _closeAllConnections();
    print('[BinanceWS] 모든 연결 해제');
  }

  void reduceUpdateFrequency() {
    // 앱이 백그라운드로 갈 때 호출
    print('[BinanceWS] 백그라운드 모드: 업데이트 빈도 감소');
    // 여기서 웹소켓 메시지를 필터링하거나 처리 빈도를 줄이는 로직
  }

  void restoreUpdateFrequency() {
    // 앱이 포그라운드로 돌아올 때 호출
    print('[BinanceWS] 포그라운드 모드: 정상 업데이트 빈도 복원');
  }

}