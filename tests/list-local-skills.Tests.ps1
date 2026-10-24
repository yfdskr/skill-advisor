param(
    [string]$ScriptPath = (Join-Path $PSScriptRoot '../scripts/list-local-skills.ps1')
)

$ErrorActionPreference = 'Stop'
# Load the real functions without scanning the user's installed skills.
. $ScriptPath -Roots @()

$cases = @(
    @('image design', '', 'Visual and Media'),
    @('visual media design', '', 'Visual and Media'),
    @('neutral', 'image design', 'Visual and Media'),
    @('neutral', 'visual media design', 'Visual and Media'),
    @('imagegen', 'Generate raster assets', 'Visual and Media'),
    @('travel-photography', 'Magazine style design', 'Visual and Media'),
    @('photo-editor', 'Edit travel photos', 'Visual and Media'),
    @('photographic-design', '', 'Visual and Media'),
    @('illustration-design', '', 'Visual and Media'),
    @('video-design', '', 'Visual and Media'),
    @('audio', '', 'Visual and Media'),
    @('canvas', 'Visualize charts and graphs', 'Visual and Media'),
    @('visualization', '', 'Visual and Media'),
    @('diagram-design', '', 'Visual and Media'),
    @('IMAGE-DESIGN', 'VISUAL MEDIA', 'Visual and Media'),
    @('frontend-design', 'Visual media and image layouts', 'Web and Frontend'),
    @('ui-design', 'Visual design with images', 'Web and Frontend'),
    @('ux-design', 'Visual media', 'Web and Frontend'),
    @('web-design', 'Photography layouts', 'Web and Frontend'),
    @('neutral', 'Build a user interface with visual assets', 'Web and Frontend'),
    @('neutral', 'Improve user experience with images', 'Web and Frontend'),
    @('neutral', 'Design landing pages with photographs', 'Web and Frontend'),
    @('high-end-visual-design', 'Design websites', 'Web and Frontend'),
    @('react', 'Charts and graphs', 'Web and Frontend'),
    @('nextjs', '', 'Web and Frontend'),
    @('next.js', '', 'Web and Frontend'),
    @('tailwindcss', '', 'Web and Frontend'),
    @('front-end', 'Visual design', 'Web and Frontend'),
    @('front end', 'Visual design', 'Web and Frontend'),
    @('css', '', 'Web and Frontend'),
    @('sites', '', 'Web and Frontend'),
    @('sites:sites', '', 'Web and Frontend'),
    @('neutral', 'Build with the Sites plugin', 'Web and Frontend'),
    @('design', '', 'Web and Frontend'),
    @('neutral', 'Design a product roadmap', 'Planning and PM'),
    @('neutral', 'Design research papers', 'Research and Writing'),
    @('neutral', 'Design a security review', 'Review and Quality'),
    @('api-design', '', 'Automation and Integrations'),
    @('rapid', 'Write documentation', 'Research and Writing'),
    @('inspection', 'Review code', 'Review and Quality'),
    @('climate', 'Research papers', 'Research and Writing'),
    @('biography', 'Writing', 'Research and Writing'),
    @('webhook', 'Automation', 'Automation and Integrations'),
    @('graphql', 'API integration', 'Automation and Integrations'),
    @('neutral', 'Photographs from archaeological sites', 'Visual and Media'),
    @('neutral', 'Plan the next trip', 'Planning and PM'),
    @('neutral', 'Next image design', 'Visual and Media'),
    @('neutral', 'Immediate response', 'General'),
    @('neutral', 'Reactive behavior', 'General'),
    @('neutral', 'Debugging notes', 'Review and Quality'),
    @('neutral', 'Automated tasks', 'Automation and Integrations'),
    @('neutral', 'Automating tasks', 'Automation and Integrations'),
    @('neutral', 'Author AgentSkills', 'Automation and Integrations'),
    @('neutral', 'Plugin SDK hooks and agents', 'Automation and Integrations'),
    @('neutral', 'Project requirements and specifications', 'Planning and PM'),
    @('neutral', 'Tests audits bugs and pull requests', 'Review and Quality'),
    @('neutral', 'Configuration settings installer migration', 'System and Configuration'),
    @('neutral', 'Documentation and citations', 'Research and Writing'),
    @('neutral', 'Arbitrary helper', 'General'),
    @('', '', 'General')
)

$failures = @()
$checks = 0
foreach ($case in $cases) {
    $actual = Get-SkillCategory -Name $case[0] -Description $case[1]
    $checks++
    if ($actual -ne $case[2]) {
        $failures += "'$($case[0])' / '$($case[1])': expected '$($case[2])', got '$actual'"
    }
}

# Exercise enumeration, frontmatter, duplicate roots, and the public output shape.
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('skill-advisor-tests-' + [guid]::NewGuid())
$fixtureDirectories = @()
try {
    $null = New-Item -ItemType Directory -Path $fixtureRoot
    foreach ($fixture in @(
        @('asset', 'image-design', "description: >-`n  Travel photography and`n  magazine style design", 'Visual and Media'),
        @('interface', 'frontend-design', 'description: Visual UI design with images', 'Web and Frontend')
    )) {
        $directory = Join-Path $fixtureRoot $fixture[0]
        $fixtureDirectories += $directory
        $null = New-Item -ItemType Directory -Path $directory
        Set-Content -LiteralPath (Join-Path $directory 'SKILL.md') -Value "---`nname: $($fixture[1])`n$($fixture[2])`n---" -Encoding UTF8
    }
    $inventory = @(& $ScriptPath -Roots @($fixtureRoot, $fixtureRoot, (Join-Path $fixtureRoot 'missing')))
    $checks++
    if ($inventory.Count -ne 2) { $failures += "Inventory: expected 2 unique skills, got $($inventory.Count)" }
    foreach ($expected in @(@('image-design', 'Visual and Media'), @('frontend-design', 'Web and Frontend'))) {
        $item = @($inventory | Where-Object Name -eq $expected[0])
        $checks++
        if ($item.Count -ne 1 -or $item[0].Category -ne $expected[1]) {
            $failures += "Inventory: incorrect category for $($expected[0])"
        }
    }
    $checks++
    $properties = @($inventory[0].PSObject.Properties.Name) -join ','
    if ($properties -ne 'Name,Category,Phase,Description,Path') { $failures += "Inventory: changed output shape $properties" }
    $checks++
    $asset = $inventory | Where-Object Name -eq 'image-design'
    if ($asset.Description -ne 'Travel photography and magazine style design' -or $asset.Phase -ne 'Planning') {
        $failures += 'Inventory: frontmatter description or existing phase behavior changed'
    }
}
finally {
    # Remove only the exact files and empty directories created by this test.
    foreach ($directory in $fixtureDirectories) {
        Remove-Item -LiteralPath (Join-Path $directory 'SKILL.md') -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $directory -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $fixtureRoot -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    throw "$($failures.Count) of $checks checks failed:`n$($failures -join "`n")"
}
Write-Output "PASS: $checks checks (PowerShell $($PSVersionTable.PSVersion))"
