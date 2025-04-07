param(
    # 첫 번째 위치 파라미터로 경로 (파일 또는 디렉토리)를 받음
    [Parameter(Position = 0)]
    [string]$Path,

    # 명시적으로 디렉토리를 지정하는 -Dir 옵션 유지
    [string]$Dir,

    [string]$Regex,

    # 새 파라미터: 출력 포맷 지정 (plain 또는 md)
    [ValidateSet('plain', 'md')]
    [string]$Format = 'plain',

    # 새 파라미터: 출력 방식 지정 (stdout 또는 copy)
    [ValidateSet('stdout', 'copy')]
    [string]$Output = 'stdout',

    # 새 파라미터: 중첩 디렉토리 탐색 여부 지정
    [switch]$Nested
)

# --- 유틸리티 함수들 ---
function Get-RelativePath {
    param([string]$Path)
    return Resolve-Path -Path $Path -Relative
}

function Get-FileExtension {
    param([string]$FilePath)
    return [System.IO.Path]::GetExtension($FilePath).TrimStart('.')
}

function Write-ToClipboard {
    param([string]$Content)
    Set-Clipboard -Value $Content
    Write-Host ""
    Write-Host "-- Content copied to clipboard --"
}

# --- 출력 포맷팅 함수들 ---
function Format-MarkdownCodeBlock {
    param(
        [string]$Extension,
        [string]$Content
    )
    $codeFence = if ($Extension) { "``````$Extension" } else { "``````" }
    return @(
        $codeFence,
        $Content,
        "``````"
    ) -join [System.Environment]::NewLine
}

function Format-PlainText {
    param(
        [string]$Path,
        [string]$Content
    )
    return @(
        "",
        "// $Path",
        $Content
    ) -join [System.Environment]::NewLine
}

# --- 파일 처리 함수들 ---
function Get-FileContent {
    param([string]$FilePath)
    try {
        return Get-Content -Path $FilePath -Raw -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not read file '$FilePath': $($_.Exception.Message)"
        return $null
    }
}

function Format-FileContent {
    param(
        [string]$FilePath,
        [bool]$addSeparator = $false,
        [string]$formatType = 'plain'
    )
    $relativePath = Get-RelativePath -Path $FilePath
    $content = Get-FileContent -FilePath $FilePath
    
    if (-not $content) { return "" }

    $formattedContent = if ($formatType -eq 'md') {
        $extension = Get-FileExtension -FilePath $FilePath
        $codeBlock = Format-MarkdownCodeBlock -Extension $extension -Content $content
        @(
            "# $relativePath",
            "",
            $codeBlock
        ) -join [System.Environment]::NewLine
    }
    else {
        Format-PlainText -Path $relativePath -Content $content
    }

    if ($addSeparator) {
        $formattedContent += [System.Environment]::NewLine + "---"
    }

    return $formattedContent
}

# --- 디렉토리 처리 함수들 ---
function Get-FilteredFiles {
    param(
        [string]$DirectoryPath,
        [string]$FilterRegex,
        [switch]$Recurse
    )
    $getChileItemParams = @{
        Path        = $DirectoryPath
        File        = $true
        ErrorAction = 'Stop'
        Recurse     = $Recurse.IsPresent
    }
    $files = Get-ChildItem @getChileItemParams

    if ($FilterRegex) {
        $files = $files | Where-Object { $_.Name -match $FilterRegex }
    }
    return $files
}

function Format-DirectoryContent {
    param(
        [string]$DirectoryPath,
        [string]$FilterRegex,
        [string]$FormatType,
        [switch]$Nested
    )
    if (-not (Test-Path $DirectoryPath -PathType Container)) {
        return "Error: Directory not found: $DirectoryPath"
    }

    try {
        $files = Get-FilteredFiles -DirectoryPath $DirectoryPath -FilterRegex $FilterRegex -Recurse:$Nested
        $count = $files.Count
        
        if ($count -eq 0) {
            $relativePath = Get-RelativePath -Path $DirectoryPath
            $message = "No files found in '$relativePath'"
            if ($FilterRegex) {
                $message += " (matching regex '$FilterRegex')"
            }
            
            if (-not $Nested.IsPresent) {
                $subDirs = Get-ChildItem -Path $DirectoryPath -Directory -ErrorAction SilentlyContinue
                if ($subDirs) {
                    $message += ". Try using the -Nested option to include files in subdirectories."
                }
            }

            return $message + [System.Environment]::NewLine
        }

        $allFileContents = @()
        for ($i = 0; $i -lt $count; $i++) {
            $file = $files[$i]
            $addSeparator = ($i -lt $count - 1)
            $fileContent = Format-FileContent -FilePath $file.FullName -addSeparator:$addSeparator -formatType $FormatType
            if ($fileContent) {
                $allFileContents += $fileContent
            }
        }
        return $allFileContents -join [System.Environment]::NewLine
    }
    catch {
        return "Error: Could not access directory '$DirectoryPath': $($_.Exception.Message)"
    }
}

# --- 도움말 출력 함수 ---
function Show-Help {
    Write-Host "Usage:"
    Write-Host "  flatcat <path> [-regex 'pattern'] [-format plain|md] [-output stdout|copy] [-nested]"
    Write-Host "  flatcat -dir <directory_path> [-regex 'pattern'] [-format plain|md] [-output stdout|copy] [-nested]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -format plain|md   Specify output format (default: plain)"
    Write-Host "  -output stdout|copy  Specify output destination (default: stdout)"
    Write-Host "  -nested            Include files in nested directories"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  flatcat ./myfile.txt"
    Write-Host "  flatcat ./mydir -format md"
    Write-Host "  flatcat ./mydir -regex '\.log$' -output copy"
    Write-Host "  flatcat -dir ./otherdir -regex '\.ps1$' -format md -output copy"
}

# --- 메인 로직 ---
$finalOutputString = ""
$errorOccurred = $false
$helpDisplayed = $false

try {
    if ($Path) {
        if (Test-Path $Path -PathType Container) {
            $finalOutputString = Format-DirectoryContent -DirectoryPath $Path -FilterRegex $Regex -FormatType $Format -Nested:$Nested
            if ($finalOutputString.StartsWith("Error:")) {
                Write-Error $finalOutputString.Substring(7)
                $errorOccurred = $true
                $finalOutputString = ""
            }
        }
        elseif (Test-Path $Path -PathType Leaf) {
            $finalOutputString = Format-FileContent -FilePath $Path -formatType $Format
        }
        else {
            Write-Error "Path not found or invalid: $Path"
            $errorOccurred = $true
        }
    }
    elseif ($Dir) {
        $finalOutputString = Format-DirectoryContent -DirectoryPath $Dir -FilterRegex $Regex -FormatType $Format -Nested:$Nested
        if ($finalOutputString.StartsWith("Error:")) {
            Write-Error $finalOutputString.Substring(7)
            $errorOccurred = $true
            $finalOutputString = ""
        }
    }
    else {
        Show-Help
        $helpDisplayed = $true
    }

    if (-not $errorOccurred -and -not $helpDisplayed -and $finalOutputString) {
        Write-Host $finalOutputString
        if ($Output -eq 'copy') {
            Write-ToClipboard -Content $finalOutputString
        }
    }
}
catch {
    Write-Error "An unexpected error occurred: $($_.Exception.Message)"
}

