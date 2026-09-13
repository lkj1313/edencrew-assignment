import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock.dart';
import '../state/watchlist_controller.dart';
import '../theme/theme.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/favorite_toast.dart';
import '../widgets/search_result_row.dart';
import 'stock_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.searchStocks});

  final Future<List<Stock>> Function(String query) searchStocks;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _input = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  String _query = '';
  bool _loading = false;
  bool _failed = false;
  List<Stock> _results = const <Stock>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value, {bool immediately = false}) {
    _debounce?.cancel();
    final int requestId = ++_requestId;
    final String query = value.trim();
    setState(() {
      _query = value;
      _results = const <Stock>[];
      _failed = false;
      _loading = query.isNotEmpty;
    });
    if (query.isEmpty) return;
    if (immediately) {
      unawaited(_search(query, requestId));
    } else {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        unawaited(_search(query, requestId));
      });
    }
  }

  Future<void> _search(String query, int requestId) async {
    try {
      final List<Stock> results = await widget.searchStocks(query);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final AppColors colors = context.colors;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(dimens.radiusMd),
      borderSide: BorderSide(
        color: colors.borderStrong,
        width: dimens.borderHairline,
      ),
    );
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            dimens.space4,
            dimens.space2,
            dimens.space4,
            dimens.space3,
          ),
          child: SizedBox(
            height: dimens.iconMd * 2,
            child: TextField(
              key: const ValueKey<String>('stock-search-input'),
              controller: _input,
              onChanged: _onChanged,
              onSubmitted: (value) => _onChanged(value, immediately: true),
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
              cursorColor: colors.accentDefault,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                height: 20 / 15,
                letterSpacing: -0.1,
                fontWeight: AppTypography.medium,
              ),
              decoration: InputDecoration(
                hintText: '종목명 또는 종목코드',
                hintStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.surfaceSunken,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: dimens.space3,
                  vertical: dimens.space2,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(
                    color: colors.accentDefault,
                    width: dimens.borderHairline,
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: dimens.space3 + dimens.iconSm + dimens.space2,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: dimens.iconSm,
                  color: colors.textTertiary,
                ),
                suffixIcon: IconButton(
                  tooltip: '검색어 지우기',
                  onPressed: () {
                    _input.clear();
                    _onChanged('');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: dimens.iconSm,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (_query.trim().isEmpty) {
      return const EmptyStateMessage(
        icon: Icons.search_rounded,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colors.accentDefault,
          semanticsLabel: '종목 검색 중',
        ),
      );
    }
    if (_failed) {
      return EmptyStateMessage(
        icon: Icons.wifi_off_rounded,
        title: '검색 결과를 불러오지 못했습니다',
        description: '네트워크 연결을 확인한 후 다시 시도해 주세요.',
        action: TextButton(
          onPressed: () => _onChanged(_input.text, immediately: true),
          child: const Text('다시 시도'),
        ),
      );
    }
    if (_results.isEmpty) {
      return EmptyStateMessage(
        icon: Icons.search_off_rounded,
        title: '검색 결과가 없습니다',
        description: "'$_query'와 일치하는 검색 결과를 찾지 못했습니다.",
      );
    }
    return Consumer<WatchlistController>(
      builder: (context, watchlist, child) {
        return ListView.builder(
          key: const PageStorageKey<String>('search-results'),
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final Stock result = _results[index];
            final Stock stock = watchlist.stockFor(result.symbol) ?? result;
            return SearchResultRow(
              key: ValueKey<String>(stock.id),
              stock: stock,
              query: _query,
              isFavorite: watchlist.isFavorite(stock.symbol),
              onTap: () => openStockDetail(context, stock),
              onToggleFavorite: () {
                final bool registered = watchlist.toggle(stock);
                showFavoriteToast(context, registered: registered);
              },
            );
          },
        );
      },
    );
  }
}
