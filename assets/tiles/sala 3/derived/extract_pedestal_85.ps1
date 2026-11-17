Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = [Drawing.Bitmap]::new((Join-Path (Split-Path -Parent $root) 'plataformas s3.png'))
$crop = [Drawing.Bitmap]::new(148, 109, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt 109; $y++) {
    for ($x = 0; $x -lt 148; $x++) {
        $pixel = $source.GetPixel(1195 + $x, 618 + $y)
        if ($pixel.A -gt 0 -and $y -lt 105) { $crop.SetPixel($x, $y, $pixel) }
    }
}
$crop.Save((Join-Path $root 'pedestal_original_transparent.png'), [Drawing.Imaging.ImageFormat]::Png)
$scaled = [Drawing.Bitmap]::new(126, 93, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($scaled)
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$graphics.DrawImage($crop, [Drawing.Rectangle]::new(0, 0, 126, 93))
$graphics.Dispose()
$scaled.Save((Join-Path $root 'pedestal_85_transparent.png'), [Drawing.Imaging.ImageFormat]::Png)
$scaled.Dispose()
$crop.Dispose()
$source.Dispose()
