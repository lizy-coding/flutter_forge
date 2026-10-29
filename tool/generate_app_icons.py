#!/usr/bin/env python3
"""Deterministic platform exports of the approved A2 clear-glass image master.

Pillow only resamples/composes platform canvases; the emblem is imagegen artwork.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / 'artwork/branding/forge-a2-glass'
APP = ROOT / 'apps/flutter_forge'
ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 96, 128, 256)
TARGET_SIZES = (16, 20, 24, 30, 32, 36, 40, 48, 60, 64, 72, 80, 96, 256)
SCALES = (100, 125, 150, 200, 250, 300, 400)
MSIX_BASES = {'StoreLogo': 50, 'Square44x44Logo': 44, 'Square150x150Logo': 150}


def source_mark():
    with Image.open(BRAND / 'source-foreground.png') as source:
        mark = source.convert('RGBA')
    bounds = mark.getchannel('A').getbbox()
    if not bounds or mark.getchannel('A').getextrema() != (0, 255):
        raise ValueError('Approved foreground must have real transparent alpha')
    return mark.crop(bounds)


def symbol(mark, size, occupancy=.82):
    image = Image.new('RGBA', (size, size))
    edge = max(1, round(size * occupancy))
    fitted = ImageOps.contain(mark, (edge, edge), Image.Resampling.LANCZOS)
    if size <= 48:
        fitted = fitted.filter(ImageFilter.UnsharpMask(radius=.5, percent=110, threshold=3))
    image.alpha_composite(fitted, ((size - fitted.width) // 2, (size - fitted.height) // 2))
    return image


def square(mark, size):
    # A simple code-native backdrop; platform masks are applied separately.
    image = Image.new('RGBA', (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(1, size - 1)
        draw.line((0, y, size, y), fill=(round(27 - t * 11), round(40 - t * 15), round(54 - t * 18), 255))
    image.alpha_composite(symbol(mark, size, .76))
    return image


def rounded(mark, size, inset=0):
    image = Image.new('RGBA', (size, size))
    edge = size - inset * 2
    tile = square(mark, edge)
    mask = Image.new('L', (edge * 4, edge * 4))
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, edge * 4 - 1, edge * 4 - 1), radius=edge * 4 * .22, fill=255)
    mask = mask.resize((edge, edge), Image.Resampling.LANCZOS)
    tile.putalpha(mask)
    image.alpha_composite(tile, (inset, inset))
    return image


def png(image):
    stream = io.BytesIO()
    image.save(stream, format='PNG', optimize=True)
    return stream.getvalue()


def windows_images(mark):
    images = {}
    for stem, base in MSIX_BASES.items():
        images[stem + '.png'] = symbol(mark, base)
        for scale in SCALES:
            # Windows sizes use conventional half-up rounding (50*1.25=63).
            size = (base * scale + 50) // 100
            images[f'{stem}.scale-{scale}.png'] = symbol(mark, size)
    for size in TARGET_SIZES:
        for suffix in ('', '_altform-unplated', '_altform-lightunplated'):
            image = symbol(mark, size, .90)
            if suffix == '_altform-lightunplated':
                # Theme export: preserve geometry/alpha, reduce glass luminance on white.
                image = ImageEnhance.Brightness(image).enhance(.58)
            images[f'Square44x44Logo.targetsize-{size}{suffix}.png'] = image
    return images


def outputs():
    mark = source_mark()
    files = {}
    def put(path, image):
        files[str(path)] = png(image)
    put(BRAND / 'app-icon-square-1024.png', square(mark, 1024).convert('RGB'))
    put(BRAND / 'app-icon-rounded-1024.png', rounded(mark, 1024, 96))
    put(BRAND / 'symbol-1024.png', symbol(mark, 1024))
    put(BRAND / 'google-play-512.png', square(mark, 512).convert('RGB'))
    # All density families retain the same geometry and platform-safe placement.
    for density, size, layer in [('mdpi', 48, 108), ('hdpi', 72, 162), ('xhdpi', 96, 216), ('xxhdpi', 144, 324), ('xxxhdpi', 192, 432)]:
        res = APP / 'android/app/src/main/res'
        put(res / f'mipmap-{density}/ic_launcher.png', rounded(mark, size))
        foreground = symbol(mark, layer, 60 / 108)
        put(res / f'drawable-{density}/ic_launcher_foreground.png', foreground)
        mono = Image.new('RGBA', foreground.size, 'white')
        mono.putalpha(foreground.getchannel('A'))
        put(res / f'drawable-{density}/ic_launcher_monochrome.png', mono)
    for size in (16, 32, 64, 128, 256, 512, 1024):
        put(APP / f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png', rounded(mark, size, round(size * 96 / 1024)))
    # iOS has no host yet. Prepare an importable catalog outside host directories.
    ios = BRAND / 'ios/AppIcon.appiconset'
    entries = []
    for idiom, points, scales in [('iphone', 20, (2, 3)), ('iphone', 29, (2, 3)), ('iphone', 40, (2, 3)), ('iphone', 60, (2, 3)), ('ipad', 20, (1, 2)), ('ipad', 29, (1, 2)), ('ipad', 40, (1, 2)), ('ipad', 76, (1, 2)), ('ipad', 83.5, (2,)), ('ios-marketing', 1024, (1,))]:
        for scale in scales:
            size = round(points * scale)
            name = f'icon-{size}.png'
            put(ios / name, square(mark, size).convert('RGB'))
            entries.append({'idiom': idiom, 'size': f'{points}x{points}', 'scale': f'{scale}x', 'filename': name})
    files[str(ios / 'Contents.json')] = (json.dumps({'images': entries, 'info': {'version': 1, 'author': 'xcode'}}, indent=2) + '\n').encode()
    for size in (192, 512):
        put(APP / f'web/icons/Icon-{size}.png', rounded(mark, size))
        # The PWA maskable safe circle contains the complete emblem.
        background = Image.new('RGBA', (size, size), '#121820')
        background.alpha_composite(symbol(mark, size, .64))
        put(APP / f'web/icons/Icon-maskable-{size}.png', background.convert('RGB'))
    put(APP / 'web/icons/apple-touch-icon.png', square(mark, 180).convert('RGB'))
    put(APP / 'web/favicon.png', rounded(mark, 32))
    stream = io.BytesIO()
    rounded(mark, 256).save(stream, format='ICO', sizes=[(size, size) for size in ICO_SIZES],
        append_images=[rounded(mark, size) for size in ICO_SIZES[:-1]])
    files[str(APP / 'windows/runner/resources/app_icon.ico')] = stream.getvalue()
    for name, image in windows_images(mark).items():
        put(APP / 'windows/store/Assets' / name, image)
    put(BRAND / 'microsoft-store-listing-300.png', square(mark, 300).convert('RGB'))
    # Contact sheet is export QA, not a new creative rendering.
    sheet = Image.new('RGB', (1120, 670), '#eef1f4')
    draw = ImageDraw.Draw(sheet)
    for index, (name, icon) in enumerate([
        ('Android / adaptive', square(mark, 230)), ('macOS', rounded(mark, 230, 22)),
        ('Windows / MSIX', symbol(mark, 230)), ('iOS / prepared', square(mark, 230)),
    ]):
        x = index * 275 + 12
        sheet.paste(icon, (x, 42), icon)
        draw.text((x, 18), name, fill='#16213b')
    for y, color in [(330, '#ffffff'), (480, '#121820')]:
        draw.rectangle((0, y, 1120, y + 140), fill=color)
        x = 22
        for size in (size for size in ICO_SIZES if size <= 96):
            icon = symbol(mark, size, .90)
            if color == '#ffffff':
                icon = ImageEnhance.Brightness(icon).enhance(.58)
            sheet.paste(icon, (x, y + 22), icon)
            draw.text((x, y + 122), str(size), fill='#7a8a9a')
            x += max(62, size + 18)
    put(BRAND / 'preview.png', sheet)
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--verify', action='store_true', help='Verify committed export hashes without rendering (portable across Pillow/OS versions)')
    args = parser.parse_args()
    if args.verify:
        manifest = json.loads((BRAND / 'exports.json').read_text())
        if hashlib.sha256((BRAND / 'source-foreground.png').read_bytes()).hexdigest() != manifest['source_sha256']:
            raise SystemExit('Icon master differs from export manifest')
        for path, expected in manifest['files'].items():
            file = ROOT / path
            if not file.resolve().is_relative_to(ROOT) or file.is_symlink() or not file.is_file() or hashlib.sha256(file.read_bytes()).hexdigest() != expected:
                raise SystemExit(f'Icon export differs from manifest: {path}')
        print(f'icon exports: {len(manifest["files"])} hashes verified')
        return
    files = outputs()
    manifest = {'schema': 'flutter_forge.icon_exports.v1', 'source': 'source-foreground.png',
        'source_sha256': hashlib.sha256((BRAND / 'source-foreground.png').read_bytes()).hexdigest(),
        'files': {str(Path(path).relative_to(ROOT)): hashlib.sha256(data).hexdigest() for path, data in sorted(files.items())}}
    files[str(BRAND / 'exports.json')] = (json.dumps(manifest, indent=2) + '\n').encode()
    for path, data in files.items():
        target = Path(path)
        if args.check:
            if not target.is_file() or target.read_bytes() != data:
                raise SystemExit(f'Icon export drift: {target.relative_to(ROOT)}')
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    print(f'icon exports: {len(files)} files; ' + ('verified' if args.check else 'generated'))


if __name__ == '__main__':
    main()
