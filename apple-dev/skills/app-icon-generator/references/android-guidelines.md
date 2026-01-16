# Android App Icon Guidelines - Complete Reference

## Overview

Android 8.0 (API level 26) introduced **adaptive icons**, which consist of two layers (foreground and background) that device manufacturers can mask with different shapes. Adaptive icons are part of Material Design.

## Adaptive Icon Structure

### Two-Layer System

Adaptive icons are composed of two separate layers:

| Layer | Size | Purpose | Requirements |
|-------|------|---------|--------------|
| **Foreground** | 108 × 108 dp | Main visual content | Can have transparency |
| **Background** | 108 × 108 dp | Base color/texture | Must be fully opaque |

### How Adaptive Icons Work

```
┌─────────────────────────────────────────────────────────────┐
│                     DEVICE MASK SHAPE                        │  ← Applied by launcher
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   BACKGROUND LAYER                    │  │  ← 108×108dp, opaque
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              FOREGROUND LAYER                   │  │  │  ← 108×108dp, can be transparent
│  │  │                                                 │  │  │
│  │  │           Main icon content here               │  │  │
│  │  │                                                 │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Keyline Masks

Device launchers apply different mask shapes to the 108×108dp canvas:

| Shape | Description | Common Devices |
|-------|-------------|----------------|
| **Circle** | Perfect circle | Pixel, OnePlus, Motorola |
| **Squircle** | Rounded square | Samsung, Nokia |
| **Square** | Square with slight radius | Some OEM skins |
| **Rounded Square** | Variable radius | Various launchers |
| **Tear Drop** | Teardrop shape | Less common |
| **Rectangle** | Vertical or horizontal | Rare, specialized |

**Critical**: You cannot control which shape devices use. Design for all possibilities.

## Keyline Specifications

### Google's Official Keyline Shapes

| Shape | Safe Area | Full Layer | Notes |
|-------|-----------|------------|-------|
| **Circle** | 66 dp diameter | 108 dp | 52 dp visible content area |
| **Squircle** | 66 × 66 dp | 108 × 108 dp | Rounded square variant |
| **Square** | 62 × 62 dp | 108 × 108 dp | 4 dp corner radius |
| **Vertical Rectangle** | 52 × 62 dp | 36 × 52 dp | 4 dp corner radius |
| **Horizontal Rectangle** | 62 × 52 dp | 52 × 36 dp | 4 dp corner radius |

### Safe Zone Guidelines

| Specification | Safe Zone | Source |
|---------------|-----------|--------|
| **66 × 66 dp** | 61% of canvas | Official Google keyline |
| **72 × 72 dp** | 67% of canvas | Some third-party guides |

**Recommendation**: Use the more conservative 66×66dp safe zone to ensure compatibility.

### Safe Zone Visual

```
┌─────────────────────────────────────────────────────────────┐
│                      FULL 108×108dp LAYER                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   SAFE ZONE MARGIN                    │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              66×66dp SAFE ZONE                  │  │  │  ← Critical content only
│  │  │                                                 │  │  │
│  │  │         Keep essential elements here           │  │  │
│  │  │                                                 │  │  │
│  │  │    This area visible in ALL mask shapes        │  │  │
│  │  │                                                 │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  │         Outer area may be CROPPED by masks            │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Size Requirements

### Google Play Store

| Use Case | Size | Format |
|----------|------|--------|
| **Store Listing** | 512 × 512 px | PNG |
| **Feature Graphic** | 1024 × 500 px | PNG (optional) |

### Adaptive Icon Layers

| Layer | Size | Format |
|-------|------|--------|
| Foreground | 108 × 108 dp | PNG or XML |
| Background | 108 × 108 dp | PNG or XML |

### Legacy Icons (Pre-Android 8.0)

| Density | Size | Use Case |
|---------|------|----------|
| mdpi | 48 × 48 dp | Base density (1x) |
| hdpi | 72 × 72 dp | High (1.5x) |
| xhdpi | 96 × 96 dp | Extra high (2x) |
| xxhdpi | 144 × 144 dp | Extra extra high (3x) |
| xxxhdpi | 192 × 192 dp | Extra extra extra high (4x) |

### Pixel Conversion

For reference, 1 dp (density-independent pixel) equals different physical pixels:

| Density | Conversion | Example for 108 dp |
|---------|------------|-------------------|
| mdpi | 1× | 108 × 108 px |
| hdpi | 1.5× | 162 × 162 px |
| xhdpi | 2× | 216 × 216 px |
| xxhdpi | 3× | 324 × 324 px |
| xxxhdpi | 4× | 432 × 432 px |

## Color Space and Format

### Color Requirements

| Property | Requirement |
|----------|-------------|
| **Color space** | sRGB (default for Material Design) |
| **Background** | Must be fully opaque |
| **Foreground** | Can have transparency |
| **Contrast** | Minimum 3:1 for accessibility |

### Format Options

| Format | When to Use | Advantages |
|--------|-------------|------------|
| **PNG** | Photographic, complex designs | Wider compatibility, easier |
| **XML drawable** | Vector, simple shapes | Scales perfectly, smaller file size |

### When to Use XML vs PNG

**Use XML drawable when:**
- Icon uses simple geometric shapes
- Design can be expressed as vector paths
- File size is a concern
- Perfect scaling at any size is needed

**Use PNG when:**
- Icon has gradients or complex effects
- Design uses photographic elements
- Not comfortable with vector graphics

## Visual Effects

### Parallax Effect

When user swipes the home screen:
- Foreground and background move slightly at different speeds
- Creates depth perception
- Add padding to foreground to account for movement

### Zoom Effect

When user taps to launch app:
- Slight scale animation applied
- Typically 3-5% scale change
- Ensure design looks good at this scale

### Accounting for Effects

| Effect | Padding Needed | Reason |
|--------|----------------|--------|
| **Parallax** | ~3 dp from edges | Foreground moves within frame |
| **Zoom** | Not usually needed | Scales proportionally |
| **Masking** | Use safe zone | Shape crops content |

## Design Principles

### Material Design Icon Principles

| Principle | Description | Application |
|-----------|-------------|-------------|
| **Bold geometry** | Clear, simple shapes | Use recognizable forms |
| **Limited palette** | 1-3 colors | Avoid visual clutter |
| **Distinctiveness** | Stand out from other apps | Unique combination of elements |
| **Thematic coherence** | Relate to app function | Clear visual metaphor |

### Design Requirements and Restrictions

| Requirement | Why |
|-------------|-----|
| **No text in icon** | Not localized, hard to read at small sizes |
| **No badges** | System adds its own badges |
| **Foreground/background independent** | Each layer should work alone |
| **Background must be opaque** | Prevents visual artifacts |

### Common Design Mistakes

| Mistake | Why It's Wrong | Alternative |
|---------|----------------|-------------|
| Text in icon | Not localized, poor scaling | Symbol-only design |
| Critical content near edges | Gets cropped by masks | Keep in 66×66dp safe zone |
| Background not opaque | Visual artifacts on some launchers | Solid color or opaque image |
| Only testing one mask shape | Will look wrong on other devices | Test with multiple masks |
| Foreground depends on background | Layers displayed independently | Each layer works alone |
| Too much detail | Lost at 48×48dp (legacy) | Simple, bold shapes |

### Recommended Design Approach

1. **Design within safe zone**: Keep critical content in 66×66dp center
2. **Separate layers**: Foreground and background should make sense alone
3. **Bold geometry**: Simple shapes scale better
4. **Limit colors**: 1-3 colors maximum
5. **Test masks**: Verify appearance with circle, squircle, square
6. **Check legacy**: Ensure 48×48dp version is recognizable
7. **Test on devices**: Verify on real Android devices

## Implementation in Android Studio

### Directory Structure

```
res/
├── mipmap-anydpi-v26/
│   ├── ic_launcher.xml
│   ├── ic_launcher_foreground.xml
│   └── ic_launcher_background.xml
├── mipmap-mdpi/
│   ├── ic_launcher.png (48×48px)
│   └── ic_launcher_round.png (48×48px)
├── mipmap-hdpi/
│   ├── ic_launcher.png (72×72px)
│   └── ic_launcher_round.png (72×72px)
├── mipmap-xhdpi/
│   ├── ic_launcher.png (96×96px)
│   └── ic_launcher_round.png (96×96px)
├── mipmap-xxhdpi/
│   ├── ic_launcher.png (144×144px)
│   └── ic_launcher_round.png (144×144px)
└── mipmap-xxxhdpi/
    ├── ic_launcher.png (192×192px)
    └── ic_launcher_round.png (192×192px)
```

### XML Adaptive Icon Definition

```xml
<!-- res/mipmap-anydpi-v26/ic_launcher.xml -->
<adaptive-icon>
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
```

### Example Foreground Layer (XML)

```xml
<!-- res/drawable/ic_launcher_foreground.xml -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M54,20 L54,20 ..." />
</vector>
```

### Example Background Layer (XML)

```xml
<!-- res/drawable/ic_launcher_background.xml -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#3DDC84"
        android:pathData="M0,0h108v108h-108z" />
</vector>
```

### Manifest Declaration

```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round"
    ... >
    ...
</application>
```

## Validation Checklist

### Design Phase

```
□ Critical content in 66×66dp safe zone
□ Foreground and background work independently
□ Background is fully opaque
□ No text in design
□ No badges or overlays
□ Test at 48×48dp (legacy size)
□ Limited color palette (1-3 colors)
```

### Export Phase

```
□ Foreground: 108×108dp PNG or XML
□ Background: 108×108dp PNG or XML
□ Play Store: 512×512px PNG
□ sRGB color space
□ Background layer is opaque
□ File sizes reasonable
```

### Testing Phase

```
□ Test with circle mask
□ Test with squircle mask
□ Test with square mask
□ Verify on multiple devices
□ Check parallax effect
□ Test launcher appearance
□ Verify legacy icon (pre-8.0)
```

## Export Workflow

### Vector (XML) Workflow

```
Design Phase
    ↓
Create foreground vector (108×108dp)
    ↓
Create background vector (108×108dp, opaque)
    ↓
Export as XML drawables
    ↓
Add to res/drawable/
    ↓
Reference in adaptive-icon XML
    ↓
Test on devices
```

### Raster (PNG) Workflow

```
Design Phase
    ↓
Export foreground at 432×432px (xxxhdpi)
    ↓
Export background at 432×432px (xxxhdpi, opaque)
    ↓
Generate other densities (hdpi, xhdpi, xxhdpi)
    ↓
Add to appropriate mipmap directories
    ↓
Reference in adaptive-icon XML
    ↓
Test on devices
```

## Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Icon appears cropped | Content outside safe zone | Move elements into 66×66dp center |
| Background visible through foreground | Foreground has unexpected transparency | Check alpha channels, design intent |
| Colors look different | Non-sRGB profile | Convert to sRGB |
| Icon blurry on high-density | Insufficient resolution | Provide xxxhdpi (4x) assets |
| Foreground moves too much in parallax | Too much padding used | Reduce padding to ~3dp |
| Legacy icon unrecognizable | Too much detail for 48×48dp | Simplify design for small sizes |

## Resources

### Official Documentation

- [Android Adaptive Icons Guide](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- [Material Design - Icons](https://m3.material.io/styles/icons/overview)
- [Android App Icon Best Practices](https://developer.android.com/guide/practices/ui_guidelines/icon_design)

### Templates and Tools

- [Android Studio Image Asset Studio](https://developer.android.com/studio/write/image-asset-studio)
- [Material Design Icons](https://fonts.google.com/icons)
- [Android Icon Templates](https://github.com/google/material-design-icons)

## Device-Specific Behavior

| OEM | Common Mask Shape | Notes |
|-----|-------------------|-------|
| **Google Pixel** | Circle | Consistent across Pixel lineup |
| **Samsung** | Squircle | OneUI uses rounded square |
| **OnePlus** | Circle | OxygenOS uses circle |
| **Motorola** | Circle | Near-stock Android |
| **Nokia** | Squircle | Varies by model |
| **Sony** | Squircle | Some customization possible |
| **Xiaomi** | Circle/Squircle | Varies by MIUI version |

**Important**: This list changes with Android version updates. Always design for all shapes, not just common ones.

## Sources

- [Android Developer Documentation - Adaptive Icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- [Designing Adaptive Icons - Google Design](https://medium.com/google-design/designing-adaptive-icons-515af294c783)
- [Android Icon Sizes Made Simple (2025 Guide)](https://creativefreedom.co.uk/icon-designers-blog/android-icon-sizes/)
- [App Icon Guide 2025](https://appsamurai.com/blog/how-to-design-a-compelling-app-icon/)
