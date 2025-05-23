# pwsh-util

PowerShell 기반의 유틸리티 모음입니다.  
개발 생산성을 높이기 위한 커맨드라인 도구들을 제공합니다.

---

## ptree

디렉토리 트리 구조를 출력하는 유틸리티

### 기능 설명

`ptree`는 현재 디렉토리(또는 지정한 경로)의 파일/디렉토리 구조를 트리 형태로 출력합니다.
기본 `tree` 명령보다 확장된 기능을 제공하며, 다음과 같은 상황에 유용합니다:

-   특정 폴더나 파일을 제외하고 구조 확인할 때
-   숨김 파일 포함 여부를 선택하고 싶을 때
-   깊이 제한을 걸고 요약 트리를 보고 싶을 때
-   디렉토리만 보고 싶을 때

### 사용법

```powershell
ptree [옵션]
```

### 옵션

| 옵션          | 축약  | 설명                      |
| ------------- | ----- | ------------------------- |
| `-Path`       | `-p`  | 트리 출력을 경로          |
| `-Exclude`    | `-x`  | 제외할 파일/디렉토리 명   |
| `-DirsOnly`   | `-d`  | 디렉토리만 출력           |
| `-ShowHidden` | `-h`  | 숨겨진 파일/디렉토리 출력 |
| `-Depth`      | `-dp` | 출력 깊이 제한            |

> 출력 항목이 100줄 이상이면, 사용자에게 Y/N 입력을 요청합니다.

### 출력 예시

```powershell
# 현재 디렉토리 구조 출력
PS C:\Script> ptree
├── .git
│   ├── ... (생략)
├── Flatcat.ps1
├── README.md
└── PTree.ps1

# 디렉토리만 2단계 깊이까지 출력
PS C:\Script> ptree -d -dp 2
└── .git
```

---

## flatcat

파일 내용을 출력하거나 디렉토리 내의 파일 내용을 병합하여 출력하는 유틸리티

### 기능 설명

`flatcat`은 다음과 같은 기능을 제공합니다:

-   파일 내용을 포맷팅하여 출력
-   디렉토리 내 파일들을 평탄화하여 한번에 출력
    -   `-Nested` 옵션을 사용하여 하위 디렉토리의 파일까지 포함 가능
-   정규식으로 파일을 필터링하여 특정 파일만 출력
-   출력 포맷 지정 (일반 텍스트 또는 마크다운)
-   출력 결과를 화면에 표시하거나 클립보드에 복사

### 사용법

```powershell
flatcat <파일경로> [옵션]
flatcat <디렉토리경로> [-Nested] [옵션]
flatcat -dir <디렉토리경로> [-Nested] [옵션]
```

### 옵션

| 옵션      | 설명                                                    |
| --------- | ------------------------------------------------------- |
| `-Path`   | 출력할 파일 또는 디렉토리 경로 (첫 번째 위치 매개변수)  |
| `-Dir`    | 출력할 디렉토리 경로                                    |
| `-Nested` | 지정된 디렉토리의 하위 디렉토리까지 포함하여 탐색       |
| `-Regex`  | 파일 필터링을 위한 정규 표현식                          |
| `-Format` | 출력 형식 지정 (`plain` 또는 `md`, 기본값: `plain`)     |
| `-Output` | 출력 방식 지정 (`stdout` 또는 `copy`, 기본값: `stdout`) |

> `-Nested` 옵션 없이 디렉토리를 지정했을 때 해당 디렉토리에 파일이 없고 하위 디렉토리만 존재하면, `-Nested` 옵션을 사용하라는 안내 메시지가 출력됩니다.

### 출력 예시

가상 디렉토리 구조:

```
./example/
├── file1.txt
├── script.ps1
└── sub/
    └── file2.log
```

파일 내용:

-   `file1.txt`: `Hello`
-   `script.ps1`: `$var = "World"`
-   `file2.log`: `Log message`

#### 단일 파일 출력

```
PS C:\Script> flatcat ./example/file1.txt

// example\file1.txt
Hello
```

#### 디렉토리 출력

```
PS C:\Script> flatcat ./example

// example\file1.txt
Hello
---

// example\script.ps1
$var = "World"
```

#### 디렉토리 출력 (-Nested 사용)

```
PS C:\Script> flatcat ./example -Nested

// example\file1.txt
Hello
---

// example\script.ps1
$var = "World"
---

// example\sub\file2.log
Log message
```

#### Markdown 포맷 및 Regex 필터링

```
PS C:\Script> flatcat ./example -Nested -Format md -Regex '\.txt$'

# example\file1.txt

\`\`\`txt
Hello
\`\`\`
```

#### `.log` 파일만 클립보드로 복사

```
PS C:\Script> flatcat ./example -Regex '\.log$' -Output copy

// example\sub\file2.log
Log message

-- Content copied to clipboard --
```

### 출력 포맷

#### Plain 텍스트

파일 경로와 내용을 주석 형태로 표시합니다:

```
// ./myfile.txt
파일 내용...

```

#### Markdown 포맷

파일 경로를 헤더로, 내용을 코드 블록으로 포맷합니다:

```markdown
# ./myfile.txt

\`\`\`js
파일 내용...
\`\`\`
```

> 파일 확장자에 따라 적절한 언어 구문 강조 코드 블록을 자동으로 생성합니다.
