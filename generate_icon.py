#!/usr/bin/env python3
"""Generate app icon for Science Lab Flutter app - Atom design"""

from PIL import Image, ImageDraw
import math

def create_icon(size=1024):
    # Create base image
    img = Image.new('RGBA', (size, size), (15, 20, 30, 255))
    draw = ImageDraw.Draw(img)

    center = size // 2

    # Draw subtle radial gradient background
    for r in range(size // 2, 0, -2):
        ratio = r / (size // 2)
        color = (
            int(20 + 15 * (1 - ratio)),
            int(25 + 20 * (1 - ratio)),
            int(40 + 30 * (1 - ratio)),
            255
        )
        draw.ellipse(
            [center - r, center - r, center + r, center + r],
            fill=color
        )

    # === NUCLEUS FIRST (so orbits draw on top) ===
    nucleus_r = size // 9  # Smaller nucleus

    # Outer glow (smaller range)
    for r in range(nucleus_r * 2, 0, -2):
        alpha = int(80 * (1 - r / (nucleus_r * 2)))
        draw.ellipse(
            [center - r, center - r, center + r, center + r],
            fill=(0, 180, 150, alpha)
        )

    # Nucleus gradient
    for r in range(nucleus_r, 0, -1):
        ratio = r / nucleus_r
        color = (
            int(0 + 100 * (1 - ratio)),
            int(200 + 55 * (1 - ratio)),
            int(160 + 95 * (1 - ratio)),
            255
        )
        draw.ellipse(
            [center - r, center - r, center + r, center + r],
            fill=color
        )

    # Highlight on nucleus
    highlight_r = nucleus_r // 3
    highlight_offset = nucleus_r // 3
    draw.ellipse(
        [center - highlight_offset - highlight_r,
         center - highlight_offset - highlight_r,
         center - highlight_offset + highlight_r,
         center - highlight_offset + highlight_r],
        fill=(255, 255, 255, 180)
    )

    # === ORBITS (on top of nucleus glow) ===
    orbit_radius = size * 0.40
    orbit_width = max(6, size // 80)  # Thicker orbits

    orbit_colors = [
        (0, 220, 180),   # Cyan-green
        (100, 200, 255), # Light blue
        (180, 130, 255), # Purple
    ]

    for idx, angle_deg in enumerate([0, 60, 120]):
        angle = math.radians(angle_deg)
        orbit_color = orbit_colors[idx]

        # Draw orbit as connected points
        points = []
        for t in range(361):
            rad = math.radians(t)

            # Ellipse (elongated)
            a = orbit_radius
            b = orbit_radius * 0.32

            x = a * math.cos(rad)
            y = b * math.sin(rad)

            # Rotate
            rx = x * math.cos(angle) - y * math.sin(angle) + center
            ry = x * math.sin(angle) + y * math.cos(angle) + center

            points.append((rx, ry))

        # Draw orbit glow (outer)
        for i in range(len(points) - 1):
            draw.line([points[i], points[i+1]],
                     fill=(*orbit_color, 40),
                     width=orbit_width + 8)

        # Draw orbit glow (middle)
        for i in range(len(points) - 1):
            draw.line([points[i], points[i+1]],
                     fill=(*orbit_color, 80),
                     width=orbit_width + 4)

        # Main orbit line (bright)
        for i in range(len(points) - 1):
            draw.line([points[i], points[i+1]],
                     fill=(*orbit_color, 255),
                     width=orbit_width)

    # === ELECTRONS (on top of everything) ===
    electron_r = size // 25  # Slightly larger electrons
    electron_positions = [(0, 30), (60, 170), (120, 290)]

    for idx, (angle_deg, t_offset) in enumerate(electron_positions):
        angle = math.radians(angle_deg)
        t = math.radians(t_offset)
        orbit_color = orbit_colors[idx]

        a = orbit_radius
        b = orbit_radius * 0.32

        x = a * math.cos(t)
        y = b * math.sin(t)

        ex = x * math.cos(angle) - y * math.sin(angle) + center
        ey = x * math.sin(angle) + y * math.cos(angle) + center

        # Electron outer glow
        for r in range(electron_r * 3, 0, -2):
            alpha = int(150 * (1 - r / (electron_r * 3)))
            draw.ellipse(
                [ex - r, ey - r, ex + r, ey + r],
                fill=(*orbit_color, alpha)
            )

        # Solid electron (white core)
        draw.ellipse(
            [ex - electron_r, ey - electron_r, ex + electron_r, ey + electron_r],
            fill=(255, 255, 255, 255)
        )

        # Inner highlight
        inner_r = electron_r // 2
        draw.ellipse(
            [ex - inner_r - 2, ey - inner_r - 2, ex + inner_r - 2, ey + inner_r - 2],
            fill=(255, 255, 255, 200)
        )

    return img

if __name__ == '__main__':
    import os

    os.makedirs('assets/icon', exist_ok=True)

    icon = create_icon(1024)
    icon.save('assets/icon/app_icon.png', 'PNG')
    print('Icon saved to assets/icon/app_icon.png')
