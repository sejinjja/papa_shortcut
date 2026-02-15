# papa_shortcut

Windows 11에서 **더블클릭 탐색기 방식 없이**, 시작 메뉴/북마크바처럼 빠르게 실행할 수 있는
**오프라인 드롭다운 런처**입니다.

## 목표
- 마우스 + 키보드 환경에서 빠르게 실행
- 인터넷 없이 100% 동작
- 단독 사용자(아버님 계정) 기준으로 간단한 개인화

## 구성 파일
- `windows/dropdown-launcher.ps1`: 검색 + 목록 기반으로 즉시 실행되는 런처
- `windows/shortcuts.json`: 실행 항목 목록(이름 + 대상 경로)

## 사용 방법 (Windows 11)
1. 이 저장소를 원하는 위치에 둡니다. 예: `C:\Tools\papa_shortcut`
2. `windows/shortcuts.json`에서 항목을 실제 경로로 수정합니다.
3. PowerShell에서 최초 1회 실행 테스트:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\windows\dropdown-launcher.ps1
   ```
4. 자주 쓰려면 바탕화면에 바로가기를 만들고 대상(Target)을 아래처럼 설정:
   ```text
   powershell.exe -ExecutionPolicy Bypass -File "C:\Tools\papa_shortcut\windows\dropdown-launcher.ps1"
   ```
5. 로그인 시 자동 실행하려면 `Win + R` → `shell:startup` 폴더에 위 바로가기를 넣습니다.

## 항목 추가/수정
`windows/shortcuts.json` 형식:

```json
[
  {
    "name": "가계부 엑셀",
    "target": "C:/Users/USER/Documents/가계부.xlsx"
  },
  {
    "name": "사진 폴더",
    "target": "C:/Users/USER/Pictures"
  },
  {
    "name": "국민신문고",
    "target": "https://www.epeople.go.kr"
  }
]
```

- `target`은 파일, 폴더, 프로그램 경로, URL 모두 가능합니다.
- 항목 선택 후 즉시 실행됩니다.

## UX 포인트
- 창은 항상 위(TopMost)로 표시되어 빠르게 접근 가능
- **검색창 + 목록 UI**로 항목이 많아도 쉽게 찾을 수 있음
- `Enter` 또는 더블클릭으로 바로 실행
- 하단 상태줄에서 실행/검색 결과를 즉시 확인
- `Esc`로 빠른 종료

## 문제 해결
- 실행 정책 오류가 뜨면 바로가기 대상에 `-ExecutionPolicy Bypass`가 포함되어 있는지 확인하세요.
- 경로에 한글/공백이 있어도 JSON 문자열로 정상 입력하면 실행됩니다.
- 항목이 안 열리면 경로 오타 또는 접근 권한을 확인하세요.
