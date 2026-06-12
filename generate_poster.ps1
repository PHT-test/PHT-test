$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function New-Color {
    param(
        [int]$R,
        [int]$G,
        [int]$B,
        [int]$A = 255
    )
    return [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-RoundedRectPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-RoundedPanel {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius,
        [System.Drawing.Brush]$FillBrush,
        [System.Drawing.Pen]$BorderPen
    )

    $path = New-RoundedRectPath -X $X -Y $Y -Width $Width -Height $Height -Radius $Radius
    try {
        $Graphics.FillPath($FillBrush, $path)
        if ($BorderPen) {
            $Graphics.DrawPath($BorderPen, $path)
        }
    } finally {
        $path.Dispose()
    }
}

function Draw-StringBlock {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [System.Drawing.Font]$Font,
        [System.Drawing.Brush]$Brush,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [string]$Align = 'Near'
    )

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::$Align
    $format.LineAlignment = [System.Drawing.StringAlignment]::Near
    $format.Trimming = [System.Drawing.StringTrimming]::Word
    $Graphics.DrawString($Text, $Font, $Brush, [System.Drawing.RectangleF]::new($X, $Y, $Width, $Height), $format)
    $format.Dispose()
}

function Draw-SectionHeader {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Title,
        [float]$X,
        [float]$Y,
        [float]$Width
    )

    $headerBrush = New-Object System.Drawing.SolidBrush (New-Color 17 77 82)
    $textBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $font = New-Object System.Drawing.Font('Segoe UI Semibold', 24, [System.Drawing.FontStyle]::Bold)
    try {
        Draw-RoundedPanel -Graphics $Graphics -X $X -Y $Y -Width $Width -Height 54 -Radius 20 -FillBrush $headerBrush -BorderPen $null
        Draw-StringBlock -Graphics $Graphics -Text $Title -Font $font -Brush $textBrush -X ($X + 18) -Y ($Y + 7) -Width ($Width - 36) -Height 40
    } finally {
        $headerBrush.Dispose()
        $textBrush.Dispose()
        $font.Dispose()
    }
}

function Draw-BulletList {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string[]]$Items,
        [System.Drawing.Font]$Font,
        [System.Drawing.Brush]$Brush,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$LineGap = 10
    )

    $cursorY = $Y
    foreach ($item in $Items) {
        $text = [char]0x2022 + ' ' + $item
        $size = $Graphics.MeasureString($text, $Font, [int]$Width)
        Draw-StringBlock -Graphics $Graphics -Text $text -Font $Font -Brush $Brush -X $X -Y $cursorY -Width $Width -Height ($size.Height + 6)
        $cursorY += $size.Height + $LineGap
    }
    return $cursorY
}

$width = 2400
$height = 3400
$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $bgRect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $bgRect,
        (New-Color 240 247 246),
        (New-Color 225 236 232),
        90
    )
    $graphics.FillRectangle($bgBrush, $bgRect)
    $bgBrush.Dispose()

    $gridPen = New-Object System.Drawing.Pen((New-Color 210 222 220), 1)
    for ($x = 60; $x -lt $width; $x += 120) {
        $graphics.DrawLine($gridPen, $x, 0, $x, $height)
    }
    for ($y = 60; $y -lt $height; $y += 120) {
        $graphics.DrawLine($gridPen, 0, $y, $width, $y)
    }
    $gridPen.Dispose()

    $headerBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.Rectangle]::new(70, 50, 2260, 420),
        (New-Color 19 79 84),
        (New-Color 26 121 109),
        0
    )
    $headerPen = New-Object System.Drawing.Pen((New-Color 236 199 91), 4)
    Draw-RoundedPanel -Graphics $graphics -X 70 -Y 50 -Width 2260 -Height 420 -Radius 36 -FillBrush $headerBrush -BorderPen $headerPen
    $headerBrush.Dispose()
    $headerPen.Dispose()

    $accentBrush = New-Object System.Drawing.SolidBrush (New-Color 236 199 91)
    $whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $mutedLightBrush = New-Object System.Drawing.SolidBrush (New-Color 218 238 232)
    $titleFont = New-Object System.Drawing.Font('Georgia', 40, [System.Drawing.FontStyle]::Bold)
    $subtitleFont = New-Object System.Drawing.Font('Georgia', 30, [System.Drawing.FontStyle]::Regular)
    $metaFont = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Regular)
    $smallCapsFont = New-Object System.Drawing.Font('Segoe UI Semibold', 16, [System.Drawing.FontStyle]::Bold)
    $graphics.FillRectangle($accentBrush, 110, 88, 160, 8)
    Draw-StringBlock -Graphics $graphics -Text 'RESEARCH POSTER' -Font $smallCapsFont -Brush $accentBrush -X 110 -Y 102 -Width 320 -Height 28
    Draw-StringBlock -Graphics $graphics -Text 'How does Foreign Language Proficiency Shape International Copyright Trade?' -Font $titleFont -Brush $whiteBrush -X 110 -Y 145 -Width 2080 -Height 120
    Draw-StringBlock -Graphics $graphics -Text 'A Cross-National Comparative Analysis of the Copyright Manager''s Role' -Font $subtitleFont -Brush $mutedLightBrush -X 110 -Y 255 -Width 2080 -Height 60
    Draw-StringBlock -Graphics $graphics -Text 'Author: Fengshun Wang    |    Keywords: International Copyright Trade, Copyright Manager, Foreign Language Proficiency, Cross-Cultural Communication' -Font $metaFont -Brush $whiteBrush -X 110 -Y 332 -Width 2100 -Height 44
    Draw-StringBlock -Graphics $graphics -Text 'Core argument: language skills do not just enable communication; they lower transaction costs, build trust, and improve cultural translation in global rights trading.' -Font $metaFont -Brush $mutedLightBrush -X 110 -Y 378 -Width 2040 -Height 42
    $accentBrush.Dispose()
    $whiteBrush.Dispose()
    $mutedLightBrush.Dispose()
    $titleFont.Dispose()
    $subtitleFont.Dispose()
    $metaFont.Dispose()
    $smallCapsFont.Dispose()

    $panelFill = New-Object System.Drawing.SolidBrush (New-Color 250 252 251)
    $panelPen = New-Object System.Drawing.Pen((New-Color 186 204 199), 2)
    $bodyBrush = New-Object System.Drawing.SolidBrush (New-Color 36 52 57)
    $bodyFont = New-Object System.Drawing.Font('Segoe UI', 20, [System.Drawing.FontStyle]::Regular)
    $bodyBoldFont = New-Object System.Drawing.Font('Segoe UI Semibold', 20, [System.Drawing.FontStyle]::Bold)
    $captionFont = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Italic)
    $miniFont = New-Object System.Drawing.Font('Segoe UI', 17, [System.Drawing.FontStyle]::Regular)
    $miniBoldFont = New-Object System.Drawing.Font('Segoe UI Semibold', 17, [System.Drawing.FontStyle]::Bold)
    $metricFont = New-Object System.Drawing.Font('Segoe UI Semibold', 28, [System.Drawing.FontStyle]::Bold)
    $metricLabelFont = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Regular)

    $leftX = 90
    $midX = 815
    $rightX = 1540
    $colW = 670

    Draw-RoundedPanel -Graphics $graphics -X $leftX -Y 520 -Width $colW -Height 560 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Research Focus' -X ($leftX + 18) -Y 538 -Width ($colW - 36)
    $focusText = "This study examines how the foreign language proficiency of copyright managers affects international copyright trade. It moves beyond legal and market factors to explain the trade process through a human-capital lens.`n`nThree questions drive the paper:`n1. How do language skills improve transaction efficiency?`n2. How do national education systems shape negotiation behavior?`n3. How can institutions convert language ability into trade advantage?"
    Draw-StringBlock -Graphics $graphics -Text $focusText -Font $bodyFont -Brush $bodyBrush -X ($leftX + 34) -Y 620 -Width ($colW - 68) -Height 420

    Draw-RoundedPanel -Graphics $graphics -X $leftX -Y 1110 -Width $colW -Height 560 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Theory Base' -X ($leftX + 18) -Y 1128 -Width ($colW - 36)
    $theoryItems = @(
        'Human Capital Theory: foreign language proficiency acts as a specialized productivity asset.',
        'Transaction Cost Theory: better language skills reduce search, bargaining, and enforcement costs.',
        'Cross-Cultural Communication Theory: meaning transfer depends on pragmatics and context, not vocabulary alone.'
    )
    [void](Draw-BulletList -Graphics $graphics -Items $theoryItems -Font $bodyFont -Brush $bodyBrush -X ($leftX + 34) -Y 1210 -Width ($colW - 68) -LineGap 18)

    Draw-RoundedPanel -Graphics $graphics -X $leftX -Y 1700 -Width $colW -Height 910 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Comparative Design' -X ($leftX + 18) -Y 1718 -Width ($colW - 36)
    $designText = "Method: a most-different-cases comparison across the United States, Germany, Japan, and China.`n`nComparison dimensions:`n- Foreign language education policy`n- Competency structure of copyright managers`n- Negotiation and information-processing behavior`n- Trade scale, growth, and market diversification`n`nEvidence base: policy texts, industry reports, WIPO and publisher-association data, plus observation from international book-fair interactions."
    Draw-StringBlock -Graphics $graphics -Text $designText -Font $miniFont -Brush $bodyBrush -X ($leftX + 34) -Y 1805 -Width ($colW - 68) -Height 420

    if (Test-Path 'paper_embedded_image1.png') {
        $tableImg = [System.Drawing.Image]::FromFile((Join-Path (Get-Location) 'paper_embedded_image1.png'))
        try {
            $targetRect = [System.Drawing.RectangleF]::new($leftX + 34, 2248, $colW - 68, 200)
            $graphics.FillRectangle((New-Object System.Drawing.SolidBrush (New-Color 245 247 246)), $targetRect)
            $graphics.DrawImage($tableImg, $targetRect)
        } finally {
            $tableImg.Dispose()
        }
        Draw-StringBlock -Graphics $graphics -Text 'Original comparative data snapshot extracted from the paper.' -Font $captionFont -Brush $bodyBrush -X ($leftX + 36) -Y 2456 -Width ($colW - 72) -Height 28
    }

    Draw-RoundedPanel -Graphics $graphics -X $midX -Y 520 -Width $colW -Height 790 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Three Core Mechanisms' -X ($midX + 18) -Y 538 -Width ($colW - 36)
    $circleBrush1 = New-Object System.Drawing.SolidBrush (New-Color 34 121 146)
    $circleBrush2 = New-Object System.Drawing.SolidBrush (New-Color 39 156 136)
    $circleBrush3 = New-Object System.Drawing.SolidBrush (New-Color 235 180 73)
    $circleNumberFont = New-Object System.Drawing.Font('Segoe UI Semibold', 30, [System.Drawing.FontStyle]::Bold)
    $circleTitleFont = New-Object System.Drawing.Font('Segoe UI Semibold', 18, [System.Drawing.FontStyle]::Bold)
    $circleBodyFont = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Regular)
    Draw-StringBlock -Graphics $graphics -Text 'Foreign language proficiency shapes trade through three linked functions:' -Font $miniBoldFont -Brush $bodyBrush -X ($midX + 34) -Y 618 -Width ($colW - 68) -Height 34

    $circles = @(
        @{ X = $midX + 72; Y = 690; Brush = $circleBrush1; Number = '1'; Title = 'Decode Information'; Body = 'Read market reports, contracts, reviews, and reader signals without translation delay.' },
        @{ X = $midX + 72; Y = 850; Brush = $circleBrush2; Number = '2'; Title = 'Build Trust'; Body = 'Use culturally appropriate communication to lower uncertainty and strengthen rapport.' },
        @{ X = $midX + 72; Y = 1010; Brush = $circleBrush3; Number = '3'; Title = 'Translate Culture'; Body = 'Explain values and local context so rights can travel across markets.' }
    )
    foreach ($circle in $circles) {
        $graphics.FillEllipse($circle.Brush, $circle.X, $circle.Y, 122, 122)
        Draw-StringBlock -Graphics $graphics -Text $circle.Number -Font $circleNumberFont -Brush ([System.Drawing.Brushes]::White) -X ($circle.X + 20) -Y ($circle.Y + 28) -Width 82 -Height 50 -Align 'Center'
        Draw-StringBlock -Graphics $graphics -Text $circle.Title -Font $circleTitleFont -Brush $bodyBrush -X ($circle.X + 148) -Y ($circle.Y + 12) -Width 340 -Height 28
        Draw-StringBlock -Graphics $graphics -Text $circle.Body -Font $circleBodyFont -Brush $bodyBrush -X ($circle.X + 148) -Y ($circle.Y + 46) -Width 360 -Height 78
    }
    $circleBrush1.Dispose()
    $circleBrush2.Dispose()
    $circleBrush3.Dispose()
    $circleNumberFont.Dispose()
    $circleTitleFont.Dispose()
    $circleBodyFont.Dispose()

    Draw-RoundedPanel -Graphics $graphics -X $midX -Y 1340 -Width $colW -Height 1230 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Four-Country Trade Profile' -X ($midX + 18) -Y 1358 -Width ($colW - 36)
    Draw-StringBlock -Graphics $graphics -Text 'Average performance indicators (2018-2022) show a strong hierarchy in scale and clear differences in growth trajectories.' -Font $miniBoldFont -Brush $bodyBrush -X ($midX + 34) -Y 1433 -Width ($colW - 68) -Height 56

    $countries = @(
        @{ Name = 'United States'; Export = 420; ExportLabel = '42 bn'; Growth = 4.2; Market = 'Core market: Commonwealth 65%'; Share = 'Non-literary share: 71%'; Fill = (New-Color 26 121 109) },
        @{ Name = 'Germany'; Export = 186; ExportLabel = '18.6 bn'; Growth = 5.8; Market = 'Core market: Europe 58%'; Share = 'Non-literary share: 64%'; Fill = (New-Color 48 146 126) },
        @{ Name = 'Japan'; Export = 92; ExportLabel = '9.2 bn'; Growth = 3.1; Market = 'Core market: Asia 73%'; Share = 'Non-literary share: 28% (manga-led)'; Fill = (New-Color 54 108 172) },
        @{ Name = 'China'; Export = 41; ExportLabel = '4.1 bn'; Growth = 12.6; Market = 'Core market: Asia 61%'; Share = 'Non-literary share: 39%'; Fill = (New-Color 230 166 59) }
    )

    $cardY = 1538
    foreach ($country in $countries) {
        $cardBrush = New-Object System.Drawing.SolidBrush (New-Color 243 248 246)
        $cardPen = New-Object System.Drawing.Pen((New-Color 208 219 214), 1.5)
        Draw-RoundedPanel -Graphics $graphics -X ($midX + 28) -Y $cardY -Width ($colW - 56) -Height 222 -Radius 22 -FillBrush $cardBrush -BorderPen $cardPen
        $cardBrush.Dispose()
        $cardPen.Dispose()

        $fillBrush = New-Object System.Drawing.SolidBrush $country.Fill
        $graphics.FillRectangle($fillBrush, $midX + 52, $cardY + 118, [Math]::Round(($country.Export / 420.0) * 360), 18)
        $fillBrush.Dispose()

        Draw-StringBlock -Graphics $graphics -Text $country.Name -Font $bodyBoldFont -Brush $bodyBrush -X ($midX + 52) -Y ($cardY + 20) -Width 260 -Height 32
        Draw-StringBlock -Graphics $graphics -Text ($country.ExportLabel + ' export value') -Font $metricFont -Brush $bodyBrush -X ($midX + 52) -Y ($cardY + 48) -Width 360 -Height 44
        Draw-StringBlock -Graphics $graphics -Text ('Growth: ' + $country.Growth + '%') -Font $metricLabelFont -Brush $bodyBrush -X ($midX + 52) -Y ($cardY + 88) -Width 190 -Height 24
        Draw-StringBlock -Graphics $graphics -Text $country.Market -Font $metricLabelFont -Brush $bodyBrush -X ($midX + 52) -Y ($cardY + 150) -Width 520 -Height 24
        Draw-StringBlock -Graphics $graphics -Text $country.Share -Font $metricLabelFont -Brush $bodyBrush -X ($midX + 52) -Y ($cardY + 178) -Width 520 -Height 24
        $cardY += 245
    }

    Draw-RoundedPanel -Graphics $graphics -X $rightX -Y 520 -Width $colW -Height 780 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Key Findings' -X ($rightX + 18) -Y 538 -Width ($colW - 36)
    $findings = @(
        'Language proficiency has a strong positive effect on rights trading because it reduces friction in search, negotiation, and contract monitoring.',
        'Competency requirements differ structurally across high-context and low-context cultures; one training model does not fit all markets.',
        'Writing and oral communication are complementary. Writing anchors legal precision, while speaking manages trust and real-time strategy.',
        'Germany shows the clearest link between systematic multilingual education and trade resilience; China shows the strongest growth momentum.'
    )
    [void](Draw-BulletList -Graphics $graphics -Items $findings -Font $bodyFont -Brush $bodyBrush -X ($rightX + 34) -Y 620 -Width ($colW - 68) -LineGap 18)

    Draw-RoundedPanel -Graphics $graphics -X $rightX -Y 1330 -Width $colW -Height 630 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Implications for Training' -X ($rightX + 18) -Y 1348 -Width ($colW - 36)
    $impText = "For civil-law and highly regulated markets, specialized writing deserves priority: contract drafting, close reading, business reports, and rights catalog localization.`n`nFor high-context and relationship-driven markets, oral communication needs more scenario-based training in pragmatics, silence, indirectness, and conflict repair.`n`nThe paper argues for a shift from general English to scenario-specific language training for copyright trade."
    Draw-StringBlock -Graphics $graphics -Text $impText -Font $bodyFont -Brush $bodyBrush -X ($rightX + 34) -Y 1430 -Width ($colW - 68) -Height 470

    Draw-RoundedPanel -Graphics $graphics -X $rightX -Y 1990 -Width $colW -Height 580 -Radius 28 -FillBrush $panelFill -BorderPen $panelPen
    Draw-SectionHeader -Graphics $graphics -Title 'Policy Recommendations' -X ($rightX + 18) -Y 2008 -Width ($colW - 36)
    $policyItems = @(
        'Create tiered language standards for copyright managers and link them to hiring and promotion.',
        'Build cross-cultural negotiation simulation labs for publishing programs.',
        'Develop multilingual contract templates and a national copyright-trade corpus.',
        'Promote a WIPO-led language service guideline and mutual recognition of professional proficiency.'
    )
    [void](Draw-BulletList -Graphics $graphics -Items $policyItems -Font $bodyFont -Brush $bodyBrush -X ($rightX + 34) -Y 2090 -Width ($colW - 68) -LineGap 18)

    $footerBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.Rectangle]::new(70, 2650, 2260, 690),
        (New-Color 17 77 82),
        (New-Color 28 104 110),
        0
    )
    $footerPen = New-Object System.Drawing.Pen((New-Color 236 199 91), 3)
    Draw-RoundedPanel -Graphics $graphics -X 70 -Y 2650 -Width 2260 -Height 690 -Radius 34 -FillBrush $footerBrush -BorderPen $footerPen
    $footerBrush.Dispose()
    $footerPen.Dispose()

    $footerTitleFont = New-Object System.Drawing.Font('Georgia', 32, [System.Drawing.FontStyle]::Bold)
    $footerBodyFont = New-Object System.Drawing.Font('Segoe UI', 24, [System.Drawing.FontStyle]::Regular)
    $footerSmallFont = New-Object System.Drawing.Font('Segoe UI', 19, [System.Drawing.FontStyle]::Regular)
    $footerWhite = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $footerAccent = New-Object System.Drawing.SolidBrush (New-Color 236 199 91)

    Draw-StringBlock -Graphics $graphics -Text 'Conclusion' -Font $footerTitleFont -Brush $footerAccent -X 110 -Y 2710 -Width 320 -Height 48
    $conclusionText = "Foreign language proficiency is a production factor in international copyright trade. Its competitive value comes from three linked effects: faster information access, stronger trust formation, and more accurate cultural translation across markets."
    Draw-StringBlock -Graphics $graphics -Text $conclusionText -Font $footerBodyFont -Brush $footerWhite -X 110 -Y 2780 -Width 1050 -Height 220

    Draw-StringBlock -Graphics $graphics -Text 'Key References' -Font $footerTitleFont -Brush $footerAccent -X 1240 -Y 2710 -Width 700 -Height 72
    $refs = @(
        'Helpman (1993), Innovation, Imitation, and Intellectual Property Rights.',
        'Melitz (2008), Language and Foreign Trade.',
        'Hall (1976), Beyond Culture.',
        'WIPO (2023), The Global Publishing Industry in 2022.'
    )
    $refY = 2780
    foreach ($ref in $refs) {
        Draw-StringBlock -Graphics $graphics -Text $ref -Font $footerSmallFont -Brush $footerWhite -X 1240 -Y $refY -Width 930 -Height 34
        $refY += 56
    }

    $footerTitleFont.Dispose()
    $footerBodyFont.Dispose()
    $footerSmallFont.Dispose()
    $footerWhite.Dispose()
    $footerAccent.Dispose()

    $outputPath = Join-Path (Get-Location) 'copyright-trade-poster.png'
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $outputPath
}
finally {
    $panelFill.Dispose()
    $panelPen.Dispose()
    $bodyBrush.Dispose()
    $bodyFont.Dispose()
    $bodyBoldFont.Dispose()
    $captionFont.Dispose()
    $miniFont.Dispose()
    $miniBoldFont.Dispose()
    $metricFont.Dispose()
    $metricLabelFont.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
