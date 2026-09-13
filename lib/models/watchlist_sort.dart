enum WatchlistSort {
  currentPrice('현재가순'),
  changePercent('등락률순'),
  name('가나다순');

  const WatchlistSort(this.label);

  final String label;
}
