param (
    [Alias("p")][string]$Path = ".",
    [Alias("x")][string[]]$Exclude = @(),
    [Alias("d")][switch]$DirsOnly,
    [Alias("h")][switch]$ShowHidden,
    [Alias("dp")][int]$Depth = [int]::MaxValue
)


function Collect-Tree {
    param (
        [string]$Path,
        [int]$Indent = 0,
        [string[]]$Exclude = @(),
        [switch]$DirsOnly,
        [switch]$ShowHidden,
        [int]$Depth
    )

    $result = @()

    if ($Indent -ge $Depth) {
        return $result
    }

    try {
        $items = Get-ChildItem -LiteralPath $Path -Force:$ShowHidden | Where-Object {
            $name = $_.Name

            foreach ($ex in $Exclude) {
                if ($name -like $ex) { return $false }
            }

            if ($DirsOnly -and -not $_.PSIsContainer) {
                return $false
            }

            return $true
        }

        foreach ($item in $items) {
            $prefix = ("│   " * $Indent) + "├── "
            $result += "$prefix$($item.Name)"

            if ($item.PSIsContainer) {
                $result += Collect-Tree -Path $item.FullName -Indent ($Indent + 1) -Exclude $Exclude -DirsOnly:$DirsOnly -ShowHidden:$ShowHidden -Depth:$Depth
            }
        }
    }
    catch {
        $result += "Error reading path '$Path': $_"
    }

    return $result
}

# 실행 진입점
$lines = Collect-Tree -Path $Path -Exclude $Exclude -DirsOnly:$DirsOnly -ShowHidden:$ShowHidden -Depth:$Depth

if ($lines.Count -ge 100) {
    Write-Host "출력 줄 수가 $($lines.Count)줄입니다. 계속하시겠습니까? [Y/N]" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -notin @("Y", "y")) {
        Write-Host "출력을 취소했습니다."
        exit
    }
}

$lines | ForEach-Object { Write-Host $_ }
