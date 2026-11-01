# whchoi Claude Code 플러그인 마켓플레이스

| 플러그인 | 포함 skill |
|---|---|
| `aws-deck` | `aws-ppt-skills`, `consulting-ppt-white-ppt`, `pptx-template-fill` |

`aws-ppt-skills`의 템플릿은 세미나 발표용 자료입니다.

## 설치

```bash
claude plugin marketplace add whchoi98/aws-deck
claude plugin install aws-deck@whchoi
```

설치 후 skill은 `/aws-deck:aws-ppt-skills`처럼 플러그인 이름을 붙여 호출합니다.

## 실행 환경 요구사항

| 도구 | 쓰는 skill | 용도 |
|---|---|---|
| Node.js, `pptxgenjs` v4 이상 | aws-ppt-skills, consulting-ppt-white-ppt | 덱 생성 |
| Python 3, `python-pptx`, `lxml`, `Pillow` | 세 skill 모두 | 템플릿 적용, 후처리, 로고 색 추출, 템플릿 채우기 |
| LibreOffice(`soffice`), Poppler(`pdftoppm`, `pdftotext`) | 세 skill 모두 | 렌더링 QA |
| `cairosvg` 또는 `rsvg-convert` 중 하나 | aws-ppt-skills | 다이어그램 SVG의 PNG 미리보기 |

`aws-ppt-skills`의 다이어그램 단계는 `aws-diagram` skill과 `aws-diagram-design` 플러그인을 호출하므로 둘 다 설치되어 있어야 합니다.

## 갱신

skill을 고친 뒤 `plugins/aws-deck/.claude-plugin/plugin.json`의 `version`을 올리고 push합니다. 설치된 쪽은 `claude plugin marketplace update whchoi` 후 `/reload-plugins`로 반영합니다.
