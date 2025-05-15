import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/coin_logo_util.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CoinTile extends StatelessWidget {
  final Map<String, dynamic> coin;
  final VoidCallback? onFavoriteToggle;

  const CoinTile({
    super.key,
    required this.coin,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final double change = double.tryParse(coin['change'] ?? '0') ?? 0;
    final String symbol = coin['symbol'] ?? '';
    final upperSymbol = symbol.toUpperCase();
    final String price = coin['price'] ?? '0';

    final appProvider = context.watch<AppProvider>();
    final isFavorite = appProvider.isFavorite(symbol);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[850],
        radius: 22,
        child: ClipOval(
          child: Image.network(
            coin['image'] ?? CoinLogoUtil.getDefaultLogo(symbol),
            width: 44,
            height: 44,
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
      title: Row(
        children: [
          Text(
            '${upperSymbol}/USDT',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onFavoriteToggle ?? () {
              appProvider.toggleFavorite(symbol);
            },
            child: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : Colors.grey,
              size: 20,
            ),
          ),
        ],
      ),
      subtitle: Text(
        '가격: $price',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: change >= 0
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
          style: TextStyle(
            color: change >= 0 ? Colors.green[400] : Colors.red[400],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        // 상세 화면으로 이동 (미구현)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('$upperSymbol 상세정보')),
              body: const Center(child: Text('코인 상세 화면 (준비 중)')),
            ),
          ),
        );
      },
    );
  }
}