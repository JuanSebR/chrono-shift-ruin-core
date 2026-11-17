Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$tiles = Split-Path -Parent $root
$background = [Drawing.Bitmap]::new((Join-Path $tiles 'fondo s3.png'))
$architecture = [Drawing.Bitmap]::new((Join-Path $tiles 'entorno s3.png'))
$platforms = [Drawing.Bitmap]::new((Join-Path $tiles 'plataformas s3.png'))
$module = [Drawing.Bitmap]::new((Join-Path $root 'module_levitation/01.png'))
$player = [Drawing.Bitmap]::new((Join-Path $root 'pickup_interacting/01.png'))
$pedestal = [Drawing.Bitmap]::new(148, 109, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$pg = [Drawing.Graphics]::FromImage($pedestal)
$pg.DrawImage($platforms, [Drawing.Rectangle]::new(0, 0, 148, 109), [Drawing.Rectangle]::new(1195, 618, 148, 109), [Drawing.GraphicsUnit]::Pixel)
$pg.Dispose()
$comparison = [Drawing.Bitmap]::new(1200, 330)
$scales = @(1.0, 0.9, 0.85, 0.8)
for ($index = 0; $index -lt $scales.Count; $index++) {
    $panel = [Drawing.Bitmap]::new(300, 300)
    $g = [Drawing.Graphics]::FromImage($panel)
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    foreach ($layer in @($background, $architecture, $platforms)) {
        $g.DrawImage($layer, [Drawing.Rectangle]::new(0, 0, 300, 300), [Drawing.Rectangle]::new(1110, 470, 300, 300), [Drawing.GraphicsUnit]::Pixel)
    }
    $g.FillRectangle([Drawing.Brushes]::Black, 85, 148, 148, 109)
    $scaledWidth = [int][Math]::Round(148 * $scales[$index])
    $scaledHeight = [int][Math]::Round(109 * $scales[$index])
    $g.DrawImage($pedestal, [Drawing.Rectangle]::new(159 - [int]($scaledWidth / 2), 257 - $scaledHeight, $scaledWidth, $scaledHeight))
    $g.DrawImage($module, [Drawing.Rectangle]::new(97, 30 + [int]((109 - $scaledHeight) / 2), 124, 107))
    $g.DrawImage($player, [Drawing.Rectangle]::new(72, 180, 77, 89))
    $g.Dispose()
    $label = ('{0:P0}' -f $scales[$index])
    $panel.Save((Join-Path $root ('pedestal_' + $label + '.png')), [Drawing.Imaging.ImageFormat]::Png)
    $cg = [Drawing.Graphics]::FromImage($comparison)
    $cg.DrawImageUnscaled($panel, $index * 300, 30)
    $cg.DrawString($label, [Drawing.Font]::new('Arial', 16), [Drawing.Brushes]::White, $index * 300 + 10, 2)
    $cg.Dispose()
    $panel.Dispose()
}
$comparison.Save((Join-Path $root 'pedestal_scale_comparison.png'), [Drawing.Imaging.ImageFormat]::Png)
$comparison.Dispose()
foreach ($bitmap in @($background, $architecture, $platforms, $module, $player, $pedestal)) { $bitmap.Dispose() }
