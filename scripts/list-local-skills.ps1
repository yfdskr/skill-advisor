param(
    [string[]]$Roots = @(
        "$env:USERPROFILE\.agents\skills",
        "$env:USERPROFILE\.codex\skills",
        (Join-Path (Get-Location) ".agents\skills"),
        (Join-Path (Get-Location) ".codex\skills")
    )
)

function Get-SkillCategory {
    param(
        [string]$Name,
        [string]$Description
    )

    $text = "$Name $Description".ToLowerInvariant()

    # Explicit frontend context wins over incidental visual/media terms.
    # Bare 'next' and 'sites' are ordinary words; match their framework/tool forms.
    if ($text -match '\b(web|websites?|frontend|front[ -]end|react(?:js)?|next(?:js|\.js)|ui|ux|tailwind(?:css)?|css)\b|\b(?:user interface|user experience|landing pages?|sites? plugin)\b' -or $Name -match '^sites(?::sites)?$') {
        return "Web and Frontend"
    }
    if ($text -match '\b(image(?:s|gen)?|visual(?:s|ize|ization|izations)?|canvas|diagrams?|charts?|graphs?|media|photo(?:s|graphy|graphic|graphs)?|illustrat(?:ion|ions|e)|video(?:s)?|audio)\b') {
        return "Visual and Media"
    }
    if ($text -match '\b(automat(?:ion|e|ed|ing)|hooks?|loop|plugins?|sdks?|apis?|gmail|calendar|slack|github|agents?|agentskills)\b') {
        return "Automation and Integrations"
    }
    if ($text -match '\b(prd|roadmaps?|projects?|planning|plans?|products?|requirements?|specs?|specifications?)\b') {
        return "Planning and PM"
    }
    if ($text -match '\b(reviews?|tests?|testing|quality|audits?|security|lint|pr|pull requests?|bugs?|debug(?:ging|ger)?)\b') {
        return "Review and Quality"
    }
    if ($text -match '\b(clear|cleanup|clean|config(?:uration)?|settings|statusline|cli|install(?:er|ation)?|migrat(?:e|ion)|shell|computer|browser|chrome)\b') {
        return "System and Configuration"
    }
    if ($text -match '\b(research|papers?|literature|scholar|docs|documents?|documentation|writing|write|readme|citations?)\b') {
        return "Research and Writing"
    }

    # Preserve the legacy design-only fallback without masking a specific domain.
    if ($text -match '\bdesign\b') {
        return "Web and Frontend"
    }

    return "General"
}

function Get-SkillPhase {
    param(
        [string]$Name,
        [string]$Description
    )

    $text = "$Name $Description".ToLowerInvariant()

    if ($text -match "prd|roadmap|planning|plan|requirement|spec|architecture|design") {
        return "Planning"
    }
    if ($text -match "build|create|implement|develop|web|frontend|react|next|ui|api|sdk|automation|hook") {
        return "Build"
    }
    if ($text -match "review|test|testing|audit|quality|security|lint|bug|accessibility|a11y") {
        return "Review"
    }
    if ($text -match "find|search|research|discover|docs|document|paper|literature|scholar") {
        return "Discovery"
    }
    if ($text -match "deploy|hosting|monitor|cleanup|clear|config|settings|install|update|migrate|statusline") {
        return "Operate"
    }

    return "General"
}

$seen = @{}

foreach ($root in $Roots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (-not (Test-Path -LiteralPath $skillFile)) {
            return
        }

        $lines = Get-Content -LiteralPath $skillFile -TotalCount 80 -ErrorAction SilentlyContinue
        $name = $_.Name
        $description = ""
        $inFrontmatter = $false
        $frontmatterStarted = $false

        for ($index = 0; $index -lt $lines.Count; $index++) {
            $line = $lines[$index]
            if ($line -eq "---") {
                if (-not $frontmatterStarted) {
                    $frontmatterStarted = $true
                    $inFrontmatter = $true
                    continue
                }
                break
            }

            if (-not $inFrontmatter) {
                continue
            }

            if ($line -match "^\s*name:\s*['""]?(.+?)['""]?\s*$") {
                $name = $Matches[1]
            }

            if ($line -match "^\s*description:\s*['""]?(.+?)['""]?\s*$") {
                $description = $Matches[1]
                if ($description -in @(">-", "|-", ">", "|")) {
                    $descriptionLines = @()
                    for ($next = $index + 1; $next -lt $lines.Count; $next++) {
                        $nextLine = $lines[$next]
                        if ($nextLine -eq "---" -or $nextLine -match "^\S") {
                            break
                        }
                        if ($nextLine.Trim().Length -gt 0) {
                            $descriptionLines += $nextLine.Trim()
                        }
                    }
                    $description = ($descriptionLines -join " ")
                }
            }
        }

        $key = "$name|$($_.FullName)"
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            [pscustomobject]@{
                Name = $name
                Category = (Get-SkillCategory -Name $name -Description $description)
                Phase = (Get-SkillPhase -Name $name -Description $description)
                Description = $description
                Path = $_.FullName
            }
        }
    }
}
