import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/coin_logo_util.dart';
import '../utils/coin_korean_names.dart'; // 새로 추가
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CoinCard extends StatelessWidget {
  final Map<String, dynamic> coin;
  final VoidCallback? onFavoriteToggle;
  final bool showVolume;

  const CoinCard({
    super.key,
    required this.coin,
    this.onFavoriteToggle,
    this.showVolume = false,
  });

  @override
  Widget build(BuildContext context) {
    final double change = double.tryParse(coin['change'] ?? '0') ?? 0;
    final String symbol = coin['symbol'] ?? '';
    final upperSymbol = symbol.toUpperCase();
    final String price = coin['price'] ?? '0';

    // 한글 이름 가져오기
    final String koreanName = CoinKoreanNames.getKoreanName(symbol);

    // 거래대금(USDT) 또는 24시간 변동률
    final quoteVolume = double.tryParse(coin['quoteVolume'] ?? '0') ?? 0;
    final quoteVolumeFormatted = _formatVolume(quoteVolume);

    final appProvider = context.watch<AppProvider>();
    final isFavorite = appProvider.isFavorite(symbol);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 코인 로고
            CircleAvatar(
              backgroundColor: Colors.grey[850],
              radius: 20,
              child: ClipOval(
                child: Image.network(
                  coin['image'] ?? CoinLogoUtil.getDefaultLogo(symbol),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        upperSymbol.substring(0, min(2, upperSymbol.length)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 코인 정보 (심볼, 한글 이름)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upperSymbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    koreanName, // 한글 이름 표시
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 가격 및 거래대금/변동률
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$price USDT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 거래대금 또는 변동률
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: showVolume
                          ? Colors.blue.withOpacity(0.1)
                          : (change >= 0
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      showVolume
                          ? '$quoteVolumeFormatted \$'
                          : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: showVolume
                            ? Colors.blue
                            : (change >= 0 ? Colors.green : Colors.red),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 즐겨찾기 아이콘
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : Colors.grey,
                size: 24,
              ),
              onPressed: onFavoriteToggle,
            ),
          ],
        ),
      ),
    );
  }

  // 거래대금 포맷 변환 (B, M 단위로)
  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    } else {
      return volume.toStringAsFixed(2);
    }
  }
}