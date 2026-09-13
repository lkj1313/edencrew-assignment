# Naver API 응답 샘플

2026-09-13 KST에 과제에서 지정한 공개 endpoint로 받은 실제 응답입니다. 데이터 값은 취득 당시 기준이며 최신 시세가 아닙니다.

| 파일 | 요청 | 인코딩 |
| --- | --- | --- |
| `search_samsung.json` | 자동완성 `q=삼성`, `target=stock,ipo,index,marketindicator` | UTF-8 |
| `metadata_005930.json` | `fchart/domestic/stock/005930` | UTF-8 |
| `realtime_005930_000660.euc-kr.txt` | `query=SERVICE_ITEM:005930,000660` | EUC-KR 원본 바이트 |
| `daily_005930_page1.euc-kr.html` | `item/sise_day.naver?code=005930&page=1` | EUC-KR 원본 바이트 |

시세 endpoint의 실제 응답 헤더는 `Content-Type: text/plain;charset=EUC-KR`였습니다. JSON 내용을 담고 있지만 UTF-8 JSON 파일과 구분하기 위해 `.euc-kr.txt`로 저장했습니다.

일별 시세 응답 헤더는 `Content-Type: text/html;charset=EUC-KR`였습니다. 이 샘플에는 2026-08-31부터 2026-09-11까지 10거래일과 마지막 페이지 756이 포함되어 있습니다.

`test/data/naver_stock_repository_test.dart`와 `test/data/naver_daily_price_test.dart`에서 응답을 읽어 요청·파싱·모델 변환을 검증합니다. 앱은 이 파일들을 네트워크 오류의 대체 데이터로 사용하지 않습니다.
