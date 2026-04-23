param(
    [string]$Output = "english-grammar-sigil.epub"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputPath = Join-Path $projectRoot $Output
$tempRoot = Join-Path $projectRoot ".epub-build"
$epubRoot = Join-Path $tempRoot "EPUB"
$textRoot = Join-Path $epubRoot "Text"
$styleRoot = Join-Path $epubRoot "Styles"
$metaInfRoot = Join-Path $tempRoot "META-INF"
$epubCssPath = Join-Path $styleRoot "epub.css"
$contentCssPath = Join-Path $styleRoot "content.css"

function Escape-Xml {
    param([string]$Text)

    return [System.Security.SecurityElement]::Escape($Text)
}

function Convert-ToXhtml {
    param(
        [string]$Content,
        [string]$CssHref
    )

    $converted = $Content
    $converted = $converted -replace '<!DOCTYPE html>', ('<?xml version="1.0" encoding="UTF-8"?>' + "`r`n" + '<!DOCTYPE html>')
    $converted = $converted -replace '<html lang="zh-Hant">', '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-Hant" lang="zh-Hant">'
    $converted = $converted -replace '<meta([^>]*?)(?<!/)>', '<meta$1 />'
    $converted = $converted -replace '<link([^>]*?)(?<!/)>', '<link$1 />'
    $converted = $converted -replace 'href="styles\.css"', ('href="' + $CssHref + '"')
    $converted = $converted -replace 'href="index\.html"', 'href="title.xhtml"'
    $converted = $converted -replace 'href="chapter-([0-9]{2})\.html"', 'href="chapter-$1.xhtml"'

    return $converted
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $textRoot -Force | Out-Null
New-Item -ItemType Directory -Path $styleRoot -Force | Out-Null
New-Item -ItemType Directory -Path $metaInfRoot -Force | Out-Null

$chapterFiles = Get-ChildItem -LiteralPath $projectRoot -Filter "chapter-*.html" |
    Sort-Object Name

if (-not $chapterFiles) {
    throw "No chapter HTML files were found."
}

$bookTitle = ([string][char]0x82F1) + ([string][char]0x6587) + ([string][char]0x6587) + ([string][char]0x6CD5) + ([string][char]0x5F9E) + ([string][char]0x96F6) + ([string][char]0x958B) + ([string][char]0x59CB) + ([string][char]0xFF1A) + ([string][char]0x6700) + ([string][char]0x7C21) + ([string][char]0x55AE) + ([string][char]0x7684) + ([string][char]0x5B78) + ([string][char]0x7FD2) + ([string][char]0x6CD5)
$bookSubtitle = "42 " + ([string][char]0x7AE0) + ([string][char]0x6559) + ([string][char]0x6750)
$tocLabel = ([string][char]0x76EE) + ([string][char]0x9304)
$readTocLabel = ([string][char]0x95B1) + ([string][char]0x8B80) + $tocLabel
$startReadLabel = ([string][char]0x958B) + ([string][char]0x59CB) + ([string][char]0x95B1) + ([string][char]0x8B80)
$bookLanguage = "zh-Hant"
$bookId = "urn:uuid:$([guid]::NewGuid())"
$modified = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$chapterItems = @()

foreach ($chapterFile in $chapterFiles) {
    $raw = Get-Content -LiteralPath $chapterFile.FullName -Encoding UTF8 -Raw
    $titleMatch = [regex]::Match($raw, '<title>(.*?)</title>')

    if (-not $titleMatch.Success) {
        throw "Missing title in $($chapterFile.Name)"
    }

    $chapterTitle = $titleMatch.Groups[1].Value.Trim()
    $chapterXhtmlName = [System.IO.Path]::GetFileNameWithoutExtension($chapterFile.Name) + ".xhtml"
    $chapterXhtmlPath = Join-Path $textRoot $chapterXhtmlName
    $chapterBody = Convert-ToXhtml -Content $raw -CssHref "../Styles/content.css"

    Write-Utf8File -Path $chapterXhtmlPath -Content $chapterBody

    $chapterItems += [pscustomobject]@{
        Id = [System.IO.Path]::GetFileNameWithoutExtension($chapterFile.Name)
        XhtmlName = $chapterXhtmlName
        Title = $chapterTitle
    }
}

$tocList = ($chapterItems | ForEach-Object {
    '        <li><a href="' + $_.XhtmlName + '">' + (Escape-Xml $_.Title) + '</a></li>'
}) -join "`r`n"

$navList = ($chapterItems | ForEach-Object {
    '      <li><a href="Text/' + $_.XhtmlName + '">' + (Escape-Xml $_.Title) + '</a></li>'
}) -join "`r`n"

$epubCss = @"
body {
  margin: 0;
  padding: 0;
  font-family: "SF Pro Display", "SF Pro Text", -apple-system, BlinkMacSystemFont, "Helvetica Neue", "PingFang TC", "Microsoft JhengHei", sans-serif;
  color: #1d1d1f;
  background: #f5f5f7;
  line-height: 1.6;
}

.epub-title-page {
  padding: 11% 7% 9%;
  min-height: 100vh;
  background:
    radial-gradient(circle at 20% 18%, rgba(255, 255, 255, 0.98) 0, rgba(255, 255, 255, 0) 34%),
    radial-gradient(circle at 80% 82%, rgba(232, 232, 237, 0.78) 0, rgba(232, 232, 237, 0) 24%),
    linear-gradient(180deg, #fbfbfd 0%, #f2f2f5 58%, #ececf0 100%);
}

.epub-title-page section {
  max-width: 34rem;
  padding: 2.5rem 2.2rem 2.2rem;
  border: 1px solid rgba(255, 255, 255, 0.72);
  border-radius: 2rem;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.92) 0%, rgba(248, 248, 250, 0.96) 100%);
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.09);
}

.epub-title-tag {
  display: inline-block;
  padding: 0.28rem 0.82rem;
  border-radius: 999px;
  font-size: 0.82rem;
  letter-spacing: 0.02em;
  font-weight: 600;
  margin: 0 0 1.1rem;
  color: #6e6e73;
  background: rgba(255, 255, 255, 0.88);
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.epub-title-page h1 {
  font-size: 2.55rem;
  line-height: 1.12;
  letter-spacing: -0.03em;
  margin: 0 0 0.65rem;
  color: #1d1d1f;
}

.epub-accent-line {
  width: 4.5rem;
  height: 0.18rem;
  margin: 0 0 1.55rem;
  border-radius: 999px;
  background: linear-gradient(90deg, #0071e3 0%, #63a7ff 100%);
}

.epub-title-links {
  margin-top: 1.4rem;
}

.epub-title-links a {
  display: inline-block;
  min-width: 9.6rem;
  margin: 0 0.65rem 0.65rem 0;
  padding: 0.72rem 1.08rem;
  border-radius: 999px;
  border: 1px solid rgba(0, 113, 227, 0.16);
  color: #0066cc;
  background: rgba(255, 255, 255, 0.88);
  text-decoration: none;
  font-weight: 600;
}

.epub-toc-page {
  padding: 7% 7% 8%;
  min-height: 100vh;
  background:
    radial-gradient(circle at 85% 15%, rgba(255, 255, 255, 0.96) 0, rgba(255, 255, 255, 0) 22%),
    linear-gradient(180deg, #fbfbfd 0%, #f2f2f5 100%);
}

.epub-toc-page section {
  padding: 2rem 2rem 1.7rem;
  border: 1px solid rgba(255, 255, 255, 0.75);
  border-radius: 1.8rem;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 20px 48px rgba(0, 0, 0, 0.08);
}

.epub-toc-page h1 {
  margin: 0 0 1.1rem;
  font-size: 1.9rem;
  letter-spacing: -0.02em;
  color: #1d1d1f;
}

.epub-toc-page ol {
  margin: 0;
  padding-left: 1.3rem;
}

.epub-toc-page li {
  margin: 0.45rem 0;
}

.epub-toc-page a {
  color: #1d1d1f;
  text-decoration: none;
}
"@

$contentCss = @"
body {
  margin: 0;
  padding: 0;
  font-family: "SF Pro Text", "SF Pro Display", -apple-system, BlinkMacSystemFont, "Helvetica Neue", "PingFang TC", "Microsoft JhengHei", sans-serif;
  color: #1d1d1f;
  background:
    radial-gradient(circle at 18% 10%, rgba(255, 255, 255, 0.95) 0, rgba(255, 255, 255, 0) 26%),
    linear-gradient(180deg, #fbfbfd 0%, #f2f2f5 58%, #ececf0 100%);
  line-height: 1.72;
}

a {
  color: #0066cc;
  text-decoration: none;
}

main,
.wrap {
  display: block;
}

.wrap {
  width: auto;
  margin: 0;
  padding: 2.2rem 1.25rem 3rem;
}

.hero,
.panel,
.pill,
.nav-card {
  display: block;
  border-radius: 1.75rem;
  background: rgba(255, 255, 255, 0.92);
  border: 1px solid rgba(255, 255, 255, 0.78);
  box-shadow: 0 18px 46px rgba(0, 0, 0, 0.08);
}

.hero {
  padding: 2.3rem 1.5rem 1.8rem;
  margin-bottom: 1.1rem;
  background:
    radial-gradient(circle at top right, rgba(255, 255, 255, 0.92) 0, rgba(255, 255, 255, 0) 34%),
    linear-gradient(180deg, rgba(255, 255, 255, 0.96) 0%, rgba(245, 245, 247, 0.96) 100%);
}

.tag {
  display: inline-block;
  padding: 0.28rem 0.82rem;
  border-radius: 999px;
  font-size: 0.82rem;
  font-weight: 600;
  color: #6e6e73;
  background: rgba(255, 255, 255, 0.88);
  border: 1px solid rgba(0, 0, 0, 0.06);
}

h1,
h2,
h3,
h4,
p {
  margin-top: 0;
}

h1 {
  margin: 0.9rem 0 0.7rem;
  font-size: 2rem;
  line-height: 1.14;
  letter-spacing: -0.03em;
  color: #1d1d1f;
}

h2 {
  margin: 0;
  font-size: 1.34rem;
  line-height: 1.24;
  letter-spacing: -0.02em;
  color: #1d1d1f;
}

h3 {
  margin: 0 0 0.45rem;
  font-size: 1.02rem;
  color: #1d1d1f;
}

p,
li {
  font-size: 1rem;
}

.lead,
.chapter-unit,
.chapter-summary,
.cover-note,
.muted,
.explain {
  color: #6e6e73;
}

.btn-row {
  margin-top: 1.35rem;
}

.btn {
  display: inline-block;
  margin: 0 0.6rem 0.55rem 0;
  padding: 0.72rem 1.08rem;
  border-radius: 999px;
  font-weight: 600;
}

.btn-primary {
  color: #ffffff;
  background: linear-gradient(180deg, #0a84ff 0%, #0071e3 100%);
}

.btn-secondary {
  color: #0066cc;
  background: rgba(255, 255, 255, 0.92);
  border: 1px solid rgba(0, 113, 227, 0.16);
}

.panel {
  margin-top: 1rem;
  padding: 1.45rem 1.35rem 1.3rem;
}

.panel-title {
  margin-bottom: 1rem;
}

.badge-round {
  display: inline-block;
  min-width: 2rem;
  padding: 0.22rem 0.62rem;
  margin-bottom: 0.6rem;
  border-radius: 999px;
  background: rgba(0, 113, 227, 0.1);
  color: #0066cc;
  font-weight: 700;
  text-align: center;
}

.lesson-grid,
.quick-grid,
.chapter-grid,
.nav-grid,
.hero-stats {
  display: block;
}

.pill,
.nav-card,
.stat,
.chapter-card {
  margin-top: 0.75rem;
  padding: 1rem 1rem 0.92rem;
}

.note {
  background: rgba(255, 255, 255, 0.94);
}

.example {
  background: rgba(242, 247, 255, 0.96);
  border: 1px solid rgba(0, 102, 204, 0.08);
}

.mistake {
  background: rgba(255, 245, 245, 0.96);
  border: 1px solid rgba(255, 59, 48, 0.08);
}

.practice {
  background: rgba(247, 247, 250, 0.96);
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.formula {
  margin: 0.8rem 0;
  padding: 0.85rem 1rem;
  border-radius: 1rem;
  color: #1d1d1f;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.96) 0%, rgba(240, 244, 250, 0.96) 100%);
  border: 1px solid rgba(0, 113, 227, 0.08);
  border-left: 0.28rem solid #0071e3;
  font-weight: 600;
}

.label {
  display: inline-block;
  margin-bottom: 0.45rem;
  font-size: 0.88rem;
  font-weight: 700;
  color: #6e6e73;
}

.bad {
  color: #c9342f;
  font-weight: 700;
}

.good {
  color: #0a7f42;
  font-weight: 700;
}

ul,
ol {
  margin: 0.75rem 0 0;
  padding-left: 1.35rem;
}

li + li {
  margin-top: 0.45rem;
}

.nav-card {
  margin-top: 0.8rem;
}

.chapter-number {
  margin-bottom: 0.35rem;
  font-size: 0.9rem;
  font-weight: 700;
  color: #0066cc;
}
"@

$titlePage = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$bookLanguage" lang="$bookLanguage">
<head>
  <meta charset="UTF-8" />
  <title>$(Escape-Xml $bookTitle)</title>
  <link rel="stylesheet" href="../Styles/epub.css" />
</head>
<body>
  <main class="epub-title-page">
    <section>
      <p class="epub-title-tag">$(Escape-Xml $bookSubtitle)</p>
      <h1>$(Escape-Xml $bookTitle)</h1>
      <div class="epub-accent-line"></div>
      <div class="epub-title-links">
        <a href="toc.xhtml">$(Escape-Xml $readTocLabel)</a>
        <a href="$($chapterItems[0].XhtmlName)">$(Escape-Xml $startReadLabel)</a>
      </div>
    </section>
  </main>
</body>
</html>
"@

$tocPage = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$bookLanguage" lang="$bookLanguage">
<head>
  <meta charset="UTF-8" />
  <title>Contents</title>
  <link rel="stylesheet" href="../Styles/epub.css" />
</head>
<body>
  <main class="epub-toc-page">
    <section>
      <h1>$(Escape-Xml $tocLabel)</h1>
      <ol>
$tocList
      </ol>
    </section>
  </main>
</body>
</html>
"@

$navPage = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="$bookLanguage" lang="$bookLanguage">
<head>
  <meta charset="UTF-8" />
  <title>Contents</title>
</head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>Contents</h1>
    <ol>
      <li><a href="Text/title.xhtml">Cover</a></li>
      <li><a href="Text/toc.xhtml">Contents</a></li>
$navList
    </ol>
  </nav>
</body>
</html>
"@

$navPoints = @()
$playOrder = 1

$navPoints += @"
    <navPoint id="nav-title" playOrder="$playOrder">
      <navLabel><text>Cover</text></navLabel>
      <content src="Text/title.xhtml" />
    </navPoint>
"@
$playOrder++

$navPoints += @"
    <navPoint id="nav-toc" playOrder="$playOrder">
      <navLabel><text>Contents</text></navLabel>
      <content src="Text/toc.xhtml" />
    </navPoint>
"@
$playOrder++

foreach ($chapter in $chapterItems) {
    $escapedTitle = Escape-Xml $chapter.Title
    $navPoints += @"
    <navPoint id="nav-$($chapter.Id)" playOrder="$playOrder">
      <navLabel><text>$escapedTitle</text></navLabel>
      <content src="Text/$($chapter.XhtmlName)" />
    </navPoint>
"@
    $playOrder++
}

$ncx = @"
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="$bookLanguage">
  <head>
    <meta name="dtb:uid" content="$bookId" />
    <meta name="dtb:depth" content="1" />
    <meta name="dtb:totalPageCount" content="0" />
    <meta name="dtb:maxPageNumber" content="0" />
  </head>
  <docTitle>
    <text>$(Escape-Xml $bookTitle)</text>
  </docTitle>
  <navMap>
$($navPoints -join "`r`n")
  </navMap>
</ncx>
"@

$manifestItems = @(
    '    <item id="css" href="Styles/styles.css" media-type="text/css" />',
    '    <item id="epubcss" href="Styles/epub.css" media-type="text/css" />',
    '    <item id="contentcss" href="Styles/content.css" media-type="text/css" />',
    '    <item id="title" href="Text/title.xhtml" media-type="application/xhtml+xml" />',
    '    <item id="tocpage" href="Text/toc.xhtml" media-type="application/xhtml+xml" />',
    '    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav" />',
    '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />'
)

foreach ($chapter in $chapterItems) {
    $manifestItems += '    <item id="' + $chapter.Id + '" href="Text/' + $chapter.XhtmlName + '" media-type="application/xhtml+xml" />'
}

$spineItems = @(
    '    <itemref idref="title" />',
    '    <itemref idref="tocpage" />'
)

foreach ($chapter in $chapterItems) {
    $spineItems += '    <itemref idref="' + $chapter.Id + '" />'
}

$opf = @"
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="$bookLanguage">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="pub-id">$bookId</dc:identifier>
    <dc:title>$(Escape-Xml $bookTitle)</dc:title>
    <dc:language>$bookLanguage</dc:language>
    <dc:creator>OpenAI Codex</dc:creator>
    <dc:description>English grammar ebook for beginner, elementary, and intermediate learners.</dc:description>
    <meta property="dcterms:modified">$modified</meta>
  </metadata>
  <manifest>
$($manifestItems -join "`r`n")
  </manifest>
  <spine toc="ncx">
$($spineItems -join "`r`n")
  </spine>
</package>
"@

$containerXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="EPUB/content.opf" media-type="application/oebps-package+xml" />
  </rootfiles>
</container>
"@

Copy-Item -LiteralPath (Join-Path $projectRoot "styles.css") -Destination (Join-Path $styleRoot "styles.css") -Force
Write-Utf8File -Path $epubCssPath -Content $epubCss
Write-Utf8File -Path $contentCssPath -Content $contentCss
Write-Utf8File -Path (Join-Path $textRoot "title.xhtml") -Content $titlePage
Write-Utf8File -Path (Join-Path $textRoot "toc.xhtml") -Content $tocPage
Write-Utf8File -Path (Join-Path $epubRoot "nav.xhtml") -Content $navPage
Write-Utf8File -Path (Join-Path $epubRoot "toc.ncx") -Content $ncx
Write-Utf8File -Path (Join-Path $epubRoot "content.opf") -Content $opf
Write-Utf8File -Path (Join-Path $metaInfRoot "container.xml") -Content $containerXml
Write-Utf8File -Path (Join-Path $tempRoot "mimetype") -Content "application/epub+zip"

if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Force
}

$zipStream = [System.IO.File]::Open($outputPath, [System.IO.FileMode]::Create)

try {
    $archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)

    try {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            (Join-Path $tempRoot "mimetype"),
            "mimetype",
            [System.IO.Compression.CompressionLevel]::NoCompression
        ) | Out-Null

        $filesToAdd = Get-ChildItem -LiteralPath $tempRoot -Recurse -File |
            Where-Object { $_.FullName -ne (Join-Path $tempRoot "mimetype") } |
            Sort-Object FullName

        foreach ($file in $filesToAdd) {
            $relativePath = $file.FullName.Substring($tempRoot.Length).TrimStart('\')
            $entryPath = $relativePath -replace '\\', '/'

            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $file.FullName,
                $entryPath,
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally {
        $archive.Dispose()
    }
}
finally {
    $zipStream.Dispose()
}

Write-Host "EPUB created: $outputPath"
Write-Host "Temp build folder: $tempRoot"
