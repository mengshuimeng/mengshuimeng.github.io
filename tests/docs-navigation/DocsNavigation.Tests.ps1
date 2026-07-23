$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Read-RepositoryFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    Get-Content -LiteralPath (Join-Path $repositoryRoot $RelativePath) -Raw
}

Describe 'documentation hub content contract' {
    It 'invokes the hub once from each localized root index' {
        @(
            'content\docs\_index.zh-cn.md',
            'content\docs\_index.en.md'
        ) | ForEach-Object {
            $content = Read-RepositoryFile $_
            ([regex]::Matches($content, '\{\{<\s*docs-hub\s*>\}\}').Count) | Should Be 1
        }
    }

    It 'invokes one hierarchy overview from every top-level category index' {
        $domains = @('ai', 'environment', 'robotics', 'cv', 'fundamentals', 'rl-sim', 'training')
        $languages = @('zh-cn', 'en')

        foreach ($domain in $domains) {
            foreach ($language in $languages) {
                $content = Read-RepositoryFile "content\docs\$domain\_index.$language.md"
                ([regex]::Matches($content, '\{\{<\s*docs-section-overview\s*>\}\}').Count) | Should Be 1
            }
        }
    }
}

Describe 'documentation hub template contract' {
    It 'defines all three intent routes with three destinations per language' {
        $template = Read-RepositoryFile 'layouts\shortcodes\docs-hub.html'
        $routeBlock = $template.Substring(
            $template.IndexOf('{{- $routes :='),
            $template.IndexOf('{{- $domains :=') - $template.IndexOf('{{- $routes :=')
        )

        $template | Should Match 'class="docs-hub not-prose"'
        $template | Should Match 'docs-hub__route--\{\{ \.key \}\}'
        $template | Should Match 'range \.destinations'
        @('quick', 'solve', 'study') | ForEach-Object {
            $template | Should Match ([regex]::Escape(('"key" "{0}"' -f $_)))
        }
        ([regex]::Matches($routeBlock, '"link"\s+"docs/').Count) | Should Be 18
    }

    It 'maps every existing top-level documentation domain' {
        $template = Read-RepositoryFile 'layouts\shortcodes\docs-hub.html'

        @('ai', 'environment', 'robotics', 'cv', 'fundamentals', 'rl-sim', 'training') |
            ForEach-Object {
                $template | Should Match ([regex]::Escape(('"slug" "{0}"' -f $_)))
            }
    }

    It 'derives counts and recent pages from Hugo page collections' {
        $template = Read-RepositoryFile 'layouts\shortcodes\docs-hub.html'

        $template | Should Match '\.RegularPagesRecursive'
        $template | Should Match '\.Sections'
        $template | Should Match 'ByLastmod\.Reverse'
        $template | Should Match 'relLangURL'
        $template | Should Match '"articleSingular"'
        $template | Should Match 'eq \$domainCount 1'
    }
}

Describe 'documentation section hierarchy contract' {
    It 'renders immediate sections before direct regular pages' {
        $template = Read-RepositoryFile 'layouts\shortcodes\docs-section-overview.html'

        $template | Should Match 'class="docs-section-overview not-prose"'
        $template | Should Match '\.Page\.Sections\.ByTitle'
        $template | Should Match '\.Page\.RegularPages\.ByTitle'
        $template.IndexOf('range $sections') | Should BeLessThan $template.IndexOf('range $articles')
    }

    It 'exposes section counts, child previews, article summaries, and an empty state' {
        $template = Read-RepositoryFile 'layouts\shortcodes\docs-section-overview.html'

        $template | Should Match '\.RegularPagesRecursive'
        $template | Should Match 'docs-section-card__children'
        $template | Should Match '\.Summary'
        $template | Should Match '\.Lastmod'
        $template | Should Match 'docs-section-overview__empty'
        $template | Should Match '"articleSingular"'
        $template | Should Match 'eq \$articleCount 1'
    }
}

Describe 'documentation navigation visual contract' {
    BeforeEach {
        $styles = Read-RepositoryFile 'assets\css\custom.css'
    }

    It 'scopes styles to the two documentation components' {
        $styles | Should Match '\.docs-hub'
        $styles | Should Match '\.docs-section-overview'
        $styles | Should Match '\.docs-hub__routes'
        $styles | Should Match '\.docs-hub__domains'
        $styles | Should Not Match '(?m)^\.(docs-section-card|docs-article-card)'
    }

    It 'supports keyboard focus and Hextra dark mode' {
        $styles | Should Match ':focus-visible'
        $styles | Should Match 'html\.dark\s+\.docs-hub'
        $styles | Should Match 'html\.dark\s+\.docs-section-overview'
    }

    It 'defines mobile and reduced-motion behavior' {
        $styles | Should Match '@media\s*\(max-width:\s*640px\)'
        $styles | Should Match '@media\s*\(prefers-reduced-motion:\s*reduce\)'
    }
}
