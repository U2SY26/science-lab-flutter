#!/usr/bin/env python3
"""Generate app icon for Science Lab Flutter app - Clean atom design"""

from PIL import Image, ImageDraw, ImageFilter
import math

def create_icon(size=1024):
    # Create base image with dark blue background
    img = Image.new('RGB', (size, size), (12, 20, 35))
    draw = ImageDraw.Draw(img)
    center = size // 2

    # Background gradient (darker at edges)
    for r in range(size // 2, 0, -2):
        ratio = r / (size // 2)
        brightness = 0.6 + 0.4 * ratio
        color = (
            int(25 * brightness),
            int(35 * brightness),
            int(55 * brightness)
        )
        draw.ellipse([center - r, center - r, center + r, center + r], fill=color)

    # === DRAW ORBITS ===
    orbit_radius = size * 0.38
    orbit_width = max(10, size // 50)

    orbit_colors = [
        (0, 230, 200),    # Cyan
        (100, 180, 255),  # Blue
        (180, 120, 255),  # Purple
    ]

    for idx, angle_deg in enumerate([0, 60, 120]):
        angle = math.radians(angle_deg)
        color = orbit_colors[idx]

        # Calculate ellipse points
        points = []
        for t in range(361):
            rad = math.radians(t)
            a = orbit_radius
            b = orbit_radius * 0.28

            x = a * math.cos(rad)
            y = b * math.sin(rad)

            rx = x * math.cos(angle) - y * math.sin(angle) + center
            ry = x * math.sin(angle) + y * math.cos(angle) + center
            points.append((rx, ry))

        # Draw orbit line
        for i in range(len(points) - 1):
            draw.line([points[i], points[i+1]], fill=color, width=orbit_width)

    # === DRAW NUCLEUS (on top of orbits) ===
    nucleus_r = size // 8

    # Nucleus base color
    for r in range(nucleus_r, 0, -1):
        ratio = r / nucleus_r
        color = (
            int(30 + 170 * (1 - ratio)),
            int(180 + 75 * (1 - ratio)),
            int(160 + 95 * (1 - ratio))
        )
        draw.ellipse([center - r, center - r, center + r, center + r], fill=color)

    # Highlight
    hl_r = nucleus_r // 3
    hl_off = nucleus_r // 3
    draw.ellipse(
        [center - hl_off - hl_r, center - hl_off - hl_r,
         center - hl_off + hl_r, center - hl_off + hl_r],
        fill=(255, 255, 255)
    )

    # === DRAW ELECTRONS ===
    electron_r = size // 20
    electron_positions = [(0, 35), (60, 175), (120, 295)]

    for idx, (angle_deg, t_offset) in enumerate(electron_positions):
        angle = math.radians(angle_deg)
        t = math.radians(t_offset)
        color = orbit_colors[idx]

        a = orbit_radius
        b = orbit_radius * 0.28

        x = a * math.cos(t)
        y = b * math.sin(t)

        ex = x * math.cos(angle) - y * math.sin(angle) + center
        ey = x * math.sin(angle) + y * math.cos(angle) + center

        # Colored ring around electron
        draw.ellipse(
            [ex - electron_r - 4, ey - electron_r - 4,
             ex + electron_r + 4, ey + electron_r + 4],
            fill=color
        )

        # White electron center
        draw.ellipse(
            [ex - electron_r, ey - electron_r,
             ex + electron_r, ey + electron_r],
            fill=(255, 255, 255)
        )

        # Highlight
        inner_r = electron_r // 3
        draw.ellipse(
            [ex - inner_r - 4, ey - inner_r - 4,
             ex + inner_r - 4, ey + inner_r - 4],
            fill=(255, 255, 255)
        )

    # Convert to RGBA for saving
    img = img.convert('RGBA')
    return img

if __name__ == '__main__':
    import os

    os.makedirs('assets/icon', exist_ok=True)

    icon = create_icon(1024)
    icon.save('assets/icon/app_icon.png', 'PNG')
    print('Icon saved to assets/icon/app_icon.png')
