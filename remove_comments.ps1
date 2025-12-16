$extensions = @('.dart', '.js', '.xml', '.yaml', '.yml', '.gradle.kts')

Get-ChildItem -Recurse -File | Where-Object { $extensions -contains $_.Extension } | ForEach-Object {
    $content = Get-Content $_.FullName -Raw

    if ($_.Extension -eq '.dart' -or $_.Extension -eq '.js' -or $_.Extension -eq '.gradle.kts') {
        # Remove // comments (inline and line-start)
        $content = $content -replace '//.*$', ''
        # Remove /* */ comments
        $content = $content -replace '/\*[\s\S]*?\*/', ''
    } elseif ($_.Extension -eq '.xml') {
        # Remove <!-- --> comments
        $content = $content -replace '<!--[\s\S]*?-->', ''
    } elseif ($_.Extension -eq '.yaml' -or $_.Extension -eq '.yml') {
        # Remove # comments (inline and line-start)
        $content = $content -replace '#.*$', ''
    }

    Set-Content $_.FullName $content
}
