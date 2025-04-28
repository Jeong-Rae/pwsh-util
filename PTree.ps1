param (
    [Alias("p")][string]$Path = ".",
    [Alias("x")][string[]]$Exclude = @(),
    [Alias("d")][switch]$DirsOnly,
    [Alias("h")][switch]$ShowHidden,
    [Alias("dp")][int]$Depth = [int]::MaxValue
)

function Test-IncludeItem {
    param (
        [System.IO.FileSystemInfo]$Item,
        [switch]$DirsOnly
    )

    if ($DirsOnly -and -not $Item.PSIsContainer) {
        return $false
    }

    return $true
}

function Format-TreeLine {
    param (
        [System.IO.FileSystemInfo]$Item,
        [int]$Indent
    )

    $prefix = ("│   " * $Indent) + "├── "
    return "$prefix$($Item.Name)"
}

function Get-Tree {
    param (
        [string]$Path,
        [int]$Indent = 0,
        [string[]]$Exclude = @(),
        [switch]$DirsOnly,
        [switch]$ShowHidden,
        [int]$Depth
    )

    $resultLines = @()
    $itemCount = 0

    if ($Indent -ge $Depth) {
        return @{ Lines = $resultLines; ItemCount = $itemCount }
    }

    try {
        $items = Get-ChildItem -LiteralPath $Path -Force:$ShowHidden -Exclude $Exclude
    }
    catch {
        Write-Warning "Error reading path '$Path': $_"
        return @{ Lines = $resultLines; ItemCount = $itemCount }
    }

    $filteredItems = $items | Where-Object {
        Test-IncludeItem -Item $_ -DirsOnly:$DirsOnly
    }

    foreach ($item in $filteredItems) {
        $resultLines += Format-TreeLine -Item $item -Indent $Indent
        $itemCount++

        if ($item.PSIsContainer) {
            $recursiveResult = Get-Tree -Path $item.FullName -Indent ($Indent + 1) -Exclude $Exclude -DirsOnly:$DirsOnly -ShowHidden:$ShowHidden -Depth:$Depth
            $resultLines += $recursiveResult.Lines
            $itemCount += $recursiveResult.ItemCount
        }
    }

    return @{ Lines = $resultLines; ItemCount = $itemCount }
}

# 실행 진입점
try {
    $resolvedPath = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $resolvedPath) {
        throw "Path not found or inaccessible: $Path"
    }
}
catch {
    Write-Warning "The specified path '$Path' does not exist or could not be accessed."
    exit 1
}

$treeOutput = Get-Tree -Path $resolvedPath.ProviderPath -Exclude $Exclude -DirsOnly:$DirsOnly -ShowHidden:$ShowHidden -Depth:$Depth

if ($treeOutput.ItemCount -ge 200) {
    Write-Host "The number of items to display is $($treeOutput.ItemCount). Continue? [Y/N]" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -notin @("Y", "y")) {
        Write-Host "Output cancelled."
        exit
    }
}

$treeOutput.Lines