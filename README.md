# OdysseyApp

## 1. OdysseyApp 프로젝트 

- 여행 일지를 기록하고 공유하는 Applicatioin.
- NaverMap을 이용하여 위치기반 서비스 제공.
- 메인화면에서 무한스크롤을 이용한 api 호출
- 이미지 로딩 최적화를 위해 image 파일을 원본, 압축 2가지 형태로 저장(AWS Lambda)
- Provider를 통해 Model 상태 관리


## 2. 개발 환경

- Language: Kotlin, Dart
- Framework: Flutter, Spring Boot(https://github.com/gominnam/OdysseyLog)
- AWS S3 Storage, AWS LAMBDA


## 3. 화면 구성

### 1. 메인페이지

 <img src="screenshots/odyssey_main_screen.jpeg" alt="structure" width="200" height="300"/></br>

- 앱 실행 시 사용자들이 작성한 경로들을 GET 요청으로 가져옵니다. (15개씩 스크롤 API 요청)

### 2. 메뉴 탭(메인페이지에서 1번)

<img src="screenshots/odyssey_main_menu_screen.jpeg" alt="structure" width="200" height="300"/></br>

- 여정버튼 클릭 시 3번 여정 페이지로 이동합니다.

### 3. 여정 페이지

 <img src="screenshots/odyssey_route_create_screen.jpeg" alt="structure" width="200" height="300"/></br>

 - **메인**: 메인화면으로 이동합니다.
 - **경로 추가**: 현재 위치 기반으로 마커 생성
 - **초기화**: 모든 마커 초기화
 - **저장하기**: 현재 기록한 이미지, 텍스트들을 서버로 POST API를 호출하여 저장합니다.

### 4. 여정 상세화면(메인페이지에서 2번 클릭 시)

 <img src="screenshots/odyssey_route_detail_screen.jpeg" alt="structure" width="200" height="300"/></br>

- 사용자가 저장한 기록들을 위치기반 데이터 기반으로 마크다운 시각화
- 마크다운마다 작성한 메모들을 표시합니다.


### 5. 마크다운 상세(여정 상세화면에서 마크다운 터치)

  <img src="screenshots/odyssey_mark_detail_screen.jpeg" alt="structure" width="200" height="300"/></br>

  - 작성한 메모와 업로드한 이미지를 볼 수 있는 팝업창 호출합니다.

 
 ## 4. Reference


- [Flutter Naver Map](https://note11.dev/flutter_naver_map/)
- [AWS S3 Presigned URL](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)
- [AWS LABMDA](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)