## 지도 데이터를 최신으로 업데이트 하는 방법
https://www.vworld.kr/v4po_main.do 
국가에서 운영하는 공간데이터 제공 페이지로 모디빅에서 사용하기에 적합한 데이터 제공(무료) 
시도, 시군구 검색해서 다운받고 mapShaper에


제작 방법

https://www.vworld.kr/v4po_main.do 시도, 시군구 검색해서 다운받기

https://mapshaper.org/ 이 페이지에서 geojson 형태로 변환
with advanced options 체크하고 select나 위에 네가지 파일 인풋하고 options 적는 칸에 encoding=euc-kr 입력해서 한국어로 인코딩시켜줌

원본으로 변환시키면 용량이 너무 크기 떄문에 우측 상단에 simplify 눌러서 3%로 조정

# 이 부분은 생략 만약 나중에 안되면 참고
console 눌러서 -proj wgs84 입력시켜 위치 정보 데이터를 WGS84(EPSH4326) 형식으로 바꿔줘야함
만약 에러가 난다면 https://helpcenter.flourish.studio/hc/en-us/articles/8827970607887-How-to-make-your-coordinates-WGS84-with-mapshaper-org#specify-original-coordinates  페이지 참고
본인은 -proj from=EPSG:25833 crs=EPSG:4326명령어로 해결하였음
*EPSG : 위도 경도 좌표를 표현하는 방식

마지막 우측 상단의 Export를 눌러서 GeoJson으로 선택 후 Export 하면 json 파일이 내려올텐데 그냥 확장자를 geojson으로 변경해서 사용해도 무관함, 둘다 같은 json인데 geojson은 그냥 지도 데이터를 가지고 있는 json이라고 확실히 전달 가능할 뿐임


이제 생성한 geojson 데이터를 assets/geojson/ 경로 안에 교체해주면 끝