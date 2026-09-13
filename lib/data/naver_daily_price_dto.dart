import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../models/daily_price.dart';

class DailyPricePageDto {
  const DailyPricePageDto({required this.rows, required this.lastPage});

  final List<DailyPriceDto> rows;
  final int lastPage;

  factory DailyPricePageDto.fromHtml(String source, {required int page}) {
    final Document document = html.parse(source);
    final Element? table = document.querySelector('table.type2');
    if (table == null) throw const FormatException('일별 시세 표가 없습니다.');
    final List<DailyPriceDto> rows = <DailyPriceDto>[];
    for (final Element row in table.querySelectorAll('tr')) {
      final List<Element> cells = row.querySelectorAll('td');
      // 제목 및 행 사이의 장식용 공백을 제외합니다.
      if (cells.length != 7 || cells.first.text.trim().isEmpty) continue;
      rows.add(DailyPriceDto.fromCells(cells));
    }

    int lastPage = page;
    final Element? lastLink = document.querySelector('.pgRR a');
    final Iterable<Element> links = lastLink == null
        ? document.querySelectorAll('table.Nnavi a')
        : <Element>[lastLink];
    for (final Element link in links) {
      final Uri? uri = Uri.tryParse(link.attributes['href'] ?? '');
      final int? linkedPage = int.tryParse(uri?.queryParameters['page'] ?? '');
      if (linkedPage != null && linkedPage > lastPage) lastPage = linkedPage;
    }
    return DailyPricePageDto(rows: List.unmodifiable(rows), lastPage: lastPage);
  }
}

class DailyPriceDto {
  const DailyPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
    required this.changeAmount,
  });

  final String localDate;
  final int closePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
  final int? changeAmount;

  factory DailyPriceDto.fromCells(List<Element> cells) {
    final RegExpMatch? date = RegExp(
      r'^(\d{4})\.(\d{2})\.(\d{2})$',
    ).firstMatch(cells[0].text.trim());
    if (date == null) throw const FormatException('일별 시세 날짜가 잘못되었습니다.');
    final int year = int.parse(date[1]!);
    final int month = int.parse(date[2]!);
    final int day = int.parse(date[3]!);
    final DateTime checked = DateTime.utc(year, month, day);
    if (checked.year != year || checked.month != month || checked.day != day) {
      throw const FormatException('존재하지 않는 일별 시세 날짜입니다.');
    }

    final Element changeCell = cells[2];
    final String changeText =
        changeCell.querySelector('span.tah')?.text ??
        changeCell.text.replaceAll(RegExp(r'상승|하락|상한가|하한가|보합'), '');
    final int magnitude = _integer(changeText);
    final String direction = '${changeCell.innerHtml} ${changeCell.text}';
    final int? changeAmount;
    if (magnitude == 0) {
      changeAmount = 0;
    } else if (direction.contains('bu_pdn') ||
        direction.contains('하락') ||
        direction.contains('하한가')) {
      changeAmount = -magnitude;
    } else if (direction.contains('bu_pup') ||
        direction.contains('상승') ||
        direction.contains('상한가')) {
      changeAmount = magnitude;
    } else {
      // 방향을 알 수 없는 수치는 임의로 상승이라고 판단하지 않습니다.
      changeAmount = null;
    }
    final int close = _integer(cells[1].text);
    final int open = _integer(cells[3].text);
    final int high = _integer(cells[4].text);
    final int low = _integer(cells[5].text);
    if (low > high ||
        (open > 0 && (open < low || open > high)) ||
        (low > 0 && (close < low || close > high))) {
      throw const FormatException('일별 시세의 고가·저가 범위가 잘못되었습니다.');
    }
    return DailyPriceDto(
      localDate: '${date[1]}${date[2]}${date[3]}',
      closePrice: close,
      openPrice: open,
      highPrice: high,
      lowPrice: low,
      accumulatedTradingVolume: _integer(cells[6].text),
      changeAmount: changeAmount,
    );
  }

  static int _integer(String text) {
    final String normalized = text.replaceAll(RegExp(r'[\s,]'), '');
    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      throw const FormatException('일별 시세 숫자가 잘못되었습니다.');
    }
    return int.parse(normalized);
  }

  DailyPrice toModel() => DailyPrice(
    localDate: localDate,
    closePrice: closePrice,
    openPrice: openPrice,
    highPrice: highPrice,
    lowPrice: lowPrice,
    accumulatedTradingVolume: accumulatedTradingVolume,
    changeAmount: changeAmount,
  );
}
