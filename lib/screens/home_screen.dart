import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/coin_card.dart';
import 'coin_list_screen.dart';
import '../utils/coin_korean_names.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('코인 시세',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppProvider>().refreshAllData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AppProvider>().refreshAllData();
        },
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 관심 코인 섹션
                  _buildSectionHeader(
                      '관심 코인',
                      onViewMore: () => _navigateToCoinList(context, 'favorites')
                  ),
                  _buildFavoriteCoinsSection(provider),

                  const SizedBox(height: 24),

                  // 거래대금 TOP 섹션
                  _buildSectionHeader(
                      '거래대금 TOP',
                      onViewMore: () => _navigateToCoinList(context, 'volume')
                  ),
                  _buildVolumeLeadersSection(provider),

                  const SizedBox(height: 24),

                  // 상승률 TOP 섹션
                  _buildSectionHeader(
                    '상승률 TOP',
                    subtitle: '24시간 기준',
                    onViewMore: () => _navigateToCoinList(context, 'gainers'),
                    coinStatusText: '지금 ${provider.getGainersCount()}개 코인이 상승하고 있어요',
                    isGainers: true,
                  ),
                  _buildTopGainersSection(provider),

                  const SizedBox(height: 24),

                  // 하락률 TOP 섹션
                  _buildSectionHeader(
                    '하락률 TOP',
                    onViewMore: () => _navigateToCoinList(context, 'losers'),
                    coinStatusText: '지금 ${provider.getLosersCount()}개 코인이 하락하고 있어요',
                    isGainers: false,
                  ),
                  _buildTopLosersSection(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(
      String title,
      {
        String? subtitle,
        required VoidCallback onViewMore,
        String? coinStatusText,
        bool isGainers = false,
      }
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              TextButton(
                onPressed: onViewMore,
                child: Row(
                  children: const [
                    Text('더보기'),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ],
          ),
          if (coinStatusText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: coinStatusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextSpan(
                      text: isGainers ? ' 😊' : ' 😢',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 관심 코인 섹션
  Widget _buildFavoriteCoinsSection(AppProvider provider) {
    final favoriteCoins = provider.getFavoriteCoins();

    if (favoriteCoins.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '관심 코인이 없습니다. 별표 아이콘을 클릭하여 코인을 추가해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildCoinCardList(favoriteCoins.take(3).toList());
  }

  // 거래대금 TOP 섹션
  Widget _buildVolumeLeadersSection(AppProvider provider) {
    final volumeLeaders = provider.getVolumeLeaders();
    return _buildCoinCardList(volumeLeaders.take(3).toList(), showVolume: true);
  }

  // 상승률 TOP 섹션
  Widget _buildTopGainersSection(AppProvider provider) {
    final topGainers = provider.getTopGainers();
    return _buildCoinCardList(topGainers.take(3).toList());
  }

  // 하락률 TOP 섹션
  Widget _buildTopLosersSection(AppProvider provider) {
    final topLosers = provider.getTopLosers();
    return _buildCoinCardList(topLosers.take(3).toList());
  }

  // 코인 카드 목록 위젯
  Widget _buildCoinCardList(List<Map<String, dynamic>> coins, {bool showVolume = false}) {
    if (coins.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '데이터가 없습니다',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: coins.map((coin) => CoinCard(
        coin: coin,
        showVolume: showVolume,
        onFavoriteToggle: () {
          context.read<AppProvider>().toggleFavorite(coin['symbol']);
        },
      )).toList(),
    );
  }

  // 더보기 클릭 시 코인 목록 화면으로 이동
  void _navigateToCoinList(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoinListScreen(listType: type),
      ),
    );
  }

  // 코인 검색 다이얼로그
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const CoinSearchDialog();
      },
    );
  }
}

// 코인 검색 다이얼로그 위젯
class CoinSearchDialog extends StatefulWidget {
  const CoinSearchDialog({super.key});

  @override
  State<CoinSearchDialog> createState() => _CoinSearchDialogState();
}

class _CoinSearchDialogState extends State<CoinSearchDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final filteredCoins = appProvider.searchCoins(_searchQuery);

    return AlertDialog(
      title: const Text('코인 검색'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '코인 이름 또는 심볼',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredCoins.length,
                itemBuilder: (context, index) {
                  final coin = filteredCoins[index];
                  final isFavorite = appProvider.isFavorite(coin['symbol']);

                  // 검색 다이얼로그 코인 목록 아이템
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(coin['image'] ?? ''),
                      backgroundColor: Colors.grey[850],
                      child: coin['image'] == null ? Text(
                          coin['symbol'].substring(0, 1).toUpperCase()
                      ) : null,
                    ),
                    title: Text(coin['symbol'].toString().toUpperCase()),
                    subtitle: Text(CoinKoreanNames.getKoreanName(coin['symbol'])), // 한글 이름 추가
                    trailing: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        appProvider.toggleFavorite(coin['symbol']);
                        setState(() {}); // 상태 갱신
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: 코인 상세 페이지로 이동
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}