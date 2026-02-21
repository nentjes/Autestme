#!/usr/bin/env python3
"""
Autestme App Store Screenshot Generator
Generates marketing frames for App Store screenshots in all required sizes
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# Device configurations
DEVICES = {
    '6.7': {'width': 1290, 'height': 2796, 'phone_width': 520},  # iPhone 14/15 Pro Max
    '6.5': {'width': 1242, 'height': 2688, 'phone_width': 500},  # iPhone 11 Pro Max
    '5.5': {'width': 1242, 'height': 2208, 'phone_width': 480},  # iPhone 8 Plus
}

CORNER_RADIUS = 45

# Colors (RGB)
COLORS = {
    'teal': (13, 107, 93),
    'teal_dark': (26, 77, 69),
    'purple': (123, 94, 167),
    'purple_dark': (93, 69, 128),
    'coral': (232, 90, 90),
    'coral_dark': (209, 69, 69),
    'blue': (0, 122, 255),
    'blue_dark': (0, 85, 204),
    'gold': (245, 166, 35),
    'gold_dark': (224, 144, 0),
    'white': (255, 255, 255),
}

# Screenshot configurations
SCREENSHOTS = [
    {
        'input': 'start.jpeg',
        'output': 'appstore_1_start',
        'gradient': ('teal', 'teal_dark'),
        'title': 'Train Your Brain\nEarn Crypto',
        'subtitle': 'Memory game with $AUT rewards',
    },
    {
        'input': 'speel.jpeg',
        'output': 'appstore_2_gameplay',
        'gradient': ('purple', 'purple_dark'),
        'title': 'Remember\n& Count',
        'subtitle': 'Track shapes, letters, or numbers',
    },
    {
        'input': 'crypto.jpeg',
        'output': 'appstore_3_wallet',
        'gradient': ('coral', 'coral_dark'),
        'title': 'Connect Your\nWallet',
        'subtitle': 'Polygon network supported',
    },
    {
        'input': 'eind.jpeg',
        'output': 'appstore_4_results',
        'gradient': ('blue', 'blue_dark'),
        'title': 'See Your\nProgress',
        'subtitle': 'Detailed score breakdown',
    },
    {
        'input': 'eind en crypto.jpeg',
        'output': 'appstore_5_rewards',
        'gradient': ('gold', 'gold_dark'),
        'title': 'Earn $AUT\nTokens',
        'subtitle': 'Real crypto rewards for playing',
    },
]

def create_gradient(width, height, color1, color2):
    """Create a vertical gradient image"""
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)

    for y in range(height):
        ratio = y / height
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    return img

def add_rounded_corners(img, radius):
    """Add rounded corners to an image"""
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), img.size], radius=radius, fill=255)
    output = Image.new('RGBA', img.size, (0, 0, 0, 0))
    output.paste(img, mask=mask)
    return output

def generate_screenshot(config, script_dir, device_name, device_config):
    """Generate a single App Store screenshot for a specific device size"""
    output_width = device_config['width']
    output_height = device_config['height']
    phone_width = device_config['phone_width']

    output_filename = f"{config['output']}_{device_name}.png"
    print(f"  Generating {output_filename}...")

    # Create gradient background
    bg = create_gradient(
        output_width,
        output_height,
        COLORS[config['gradient'][0]],
        COLORS[config['gradient'][1]]
    )

    # Load phone screenshot
    input_path = os.path.join(script_dir, config['input'])
    if not os.path.exists(input_path):
        print(f"    Warning: {config['input']} not found, skipping...")
        return

    phone_img = Image.open(input_path)

    # Calculate phone dimensions maintaining aspect ratio
    phone_aspect = phone_img.width / phone_img.height
    phone_height = int(phone_width / phone_aspect)

    # Resize phone screenshot
    phone_img = phone_img.resize((phone_width, phone_height), Image.Resampling.LANCZOS)

    # Add rounded corners to phone
    phone_img = phone_img.convert('RGBA')
    phone_img = add_rounded_corners(phone_img, CORNER_RADIUS)

    # Create shadow
    shadow = Image.new('RGBA', (phone_width + 60, phone_height + 60), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [(30, 30), (phone_width + 30, phone_height + 30)],
        radius=CORNER_RADIUS,
        fill=(0, 0, 0, 100)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=20))

    # Position phone (centered horizontally, in lower portion)
    phone_x = (output_width - phone_width) // 2
    phone_y = output_height - phone_height - 150

    # Convert bg to RGBA for compositing
    bg = bg.convert('RGBA')

    # Paste shadow and phone
    bg.paste(shadow, (phone_x - 30, phone_y - 30), shadow)
    bg.paste(phone_img, (phone_x, phone_y), phone_img)

    # Add text
    draw = ImageDraw.Draw(bg)

    # Try to load fonts
    title_size = int(output_width * 0.07)  # Scale font based on width
    subtitle_size = int(output_width * 0.033)

    try:
        title_font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', title_size)
        subtitle_font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', subtitle_size)
    except:
        try:
            title_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', title_size)
            subtitle_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', subtitle_size)
        except:
            title_font = ImageFont.load_default()
            subtitle_font = ImageFont.load_default()

    # Draw title (centered)
    title_y = int(output_height * 0.06)
    line_height = int(title_size * 1.2)

    for line in config['title'].split('\n'):
        bbox = draw.textbbox((0, 0), line, font=title_font)
        text_width = bbox[2] - bbox[0]
        text_x = (output_width - text_width) // 2
        draw.text((text_x, title_y), line, font=title_font, fill=COLORS['white'])
        title_y += line_height

    # Draw subtitle
    subtitle_y = title_y + int(output_height * 0.015)
    bbox = draw.textbbox((0, 0), config['subtitle'], font=subtitle_font)
    text_width = bbox[2] - bbox[0]
    text_x = (output_width - text_width) // 2
    draw.text((text_x, subtitle_y), config['subtitle'], font=subtitle_font, fill=(255, 255, 255, 230))

    # Save
    output_path = os.path.join(script_dir, output_filename)
    bg = bg.convert('RGB')
    bg.save(output_path, 'PNG', quality=95)
    print(f"    Saved: {output_filename}")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))

    print("=" * 60)
    print("Autestme App Store Screenshot Generator")
    print("=" * 60)
    print()

    for device_name, device_config in DEVICES.items():
        print(f"\n[iPhone {device_name}\" - {device_config['width']}x{device_config['height']}]")

        for config in SCREENSHOTS:
            generate_screenshot(config, script_dir, device_name, device_config)

    print()
    print("=" * 60)
    print("Done! Screenshots generated for all device sizes.")
    print("=" * 60)
    print()
    print("Files created:")
    for device_name in DEVICES.keys():
        print(f"\niPhone {device_name}\":")
        for config in SCREENSHOTS:
            print(f"  - {config['output']}_{device_name}.png")

if __name__ == '__main__':
    main()
