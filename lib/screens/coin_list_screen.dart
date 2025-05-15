import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/coin_card.dart';
import '../utils/coin_korean_names.dart';

class CoinListScreen extends StatelessWidget {
  final String listType;

  const CoinListScreen({
    super.key,
    required this.listType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final coins = _getCoins(provider);

          return RefreshIndicator(
            onRefresh: () async {
              await provider.refreshAllData();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: coins.length,
              itemBuilder: (context, index) {
                return CoinCard(
                  coin: coins[index],
                  showVolume: listType == 'volume',
                  onFavoriteToggle: () {
                    provider.toggleFavorite(coins[index]['symbol']);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _getTitle() {
    switch (listType) {
      case 'favorites':
        return '관심 코인';
      case 'volume':
        return '거래대금 TOP';
      case 'gainers':
        return '상승률 TOP';
      case 'losers':
        return '하락률 TOP';
      default:
        return '코인 목록';
    }
  }

  List<Map<String, dynamic>> _getCoins(AppProvider provider) {
    switch (listType) {
      case 'favorites':
        return provider.getFavoriteCoins();
      case 'volume':
        return provider.getVolumeLeaders();
      case 'gainers':
        return provider.getTopGainers();
      case 'losers':
        return provider.getTopLosers();
      default:
        return provider.allCoins;
    }
  }
}