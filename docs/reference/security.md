# Security / 보안 구현 상세

<a href="#english"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
<a href="#korean"><img src="https://img.shields.io/badge/lang-한국어-red.svg" alt="Korean"></a>

---

<a id="english"></a>

# English

### 1. Overview
<!-- TODO: 1-3 sentences on what the security layer does and why it exists. -->

### 2. Components
| Component | Path | Purpose |
|---|---|---|
| Secret gate | `.claude/hooks/secret-scan.sh` | Blocks a `git commit` whose files match a secret pattern (exit 2) |
| Deny rules | `.claude/settings.json` | Denies destructive shell commands and reads of `.env` files |
| Ignored secrets | `.gitignore` | Keeps `.env` and `.claude/settings.local.json` out of git |
| Pattern tests | `tests/hooks/test-secret-patterns.sh` | True- and false-positive samples for every secret pattern |

### 3. Key Decisions
<!-- TODO: list 3-5 decisions or link to docs/decisions/ADR-*.md -->

### 4. Code Pointers
<!-- TODO: 3-7 entries; paths must be valid (checked by /sync-docs) -->
- `.claude/hooks/secret-scan.sh` -- the `PATTERNS` and `SKIP_PATTERNS` arrays, and how the commit's file set is worked out
- `.claude/settings.json` -- `permissions.deny` and the hook registrations
- `tests/hooks/test-secret-patterns.sh` -- true- and false-positive samples per pattern

### 5. Cross-references
<!-- TODO -->
- Related modules:
- Related ADRs:
- Related runbooks:

---

<a id="korean"></a>

# 한국어

### 1. 개요
<!-- TODO: 보안 계층이 무엇을 하는지, 왜 존재하는지 1-3 문장으로. -->

### 2. 구성요소
| 구성요소 | 경로 | 목적 |
|---|---|---|
| 비밀값 게이트 | `.claude/hooks/secret-scan.sh` | 비밀값 패턴과 일치하는 파일이 들어간 `git commit`을 차단(exit 2) |
| 거부 규칙 | `.claude/settings.json` | 파괴적인 셸 명령과 `.env` 파일 읽기를 거부 |
| 비밀값 제외 | `.gitignore` | `.env`와 `.claude/settings.local.json`을 git에서 제외 |
| 패턴 테스트 | `tests/hooks/test-secret-patterns.sh` | 각 비밀값 패턴의 탐지 및 오탐 샘플 |

### 3. 주요 결정
<!-- TODO: 3-5개 결정 나열 또는 docs/decisions/ADR-*.md 링크 -->

### 4. 코드 포인터
<!-- TODO: 3-7개 항목; 경로는 실재해야 함 (/sync-docs가 점검) -->
- `.claude/hooks/secret-scan.sh` -- `PATTERNS`, `SKIP_PATTERNS` 배열과 커밋에 들어갈 파일을 판별하는 로직
- `.claude/settings.json` -- `permissions.deny`와 hook 등록
- `tests/hooks/test-secret-patterns.sh` -- 패턴별 탐지 및 오탐 샘플

### 5. 상호 참조
<!-- TODO -->
- 관련 모듈:
- 관련 ADR:
- 관련 런북:
