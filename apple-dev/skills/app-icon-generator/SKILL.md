---
name: app-icon-generator
description: Generate appealing, high-quality iOS and Android app icons following each platform's design guidelines. Handles specifications, safe zones, export formats, and platform-specific requirements.
license: MIT
metadata:
  version: 1.0.0
  model: claude-opus-4-5-20251101
---

# App Icon Generator

Generate appealing, high-quality iOS and Android app icons following each platform's design guidelines.

## Quick Start

```
You: "Create app icons for my fitness app called FitPulse"
You: "Design an icon for my weather app with a sun and cloud"
You: "Generate iOS and Android icons for my banking app"
You: "I need app icons for a photography app"
```

The skill will gather requirements, design the icon, and provide export-ready specifications for both platforms.

## Triggers

| Phrase | Activates |
|--------|-----------|
| "Create app icon" | Icon generation workflow |
| "Design app icon" | Icon design workflow |
| "Generate iOS icon" | iOS-specific icon workflow |
| "Generate Android icon" | Android-specific icon workflow |
| "App icon for" | Full workflow with app name |

## Quick Reference

| Platform | Master Size | Safe Zone | Color Space | Format |
|----------|-------------|-----------|-------------|--------|
| **iOS** | 1024×1024px | 66% center, 90px margin | sRGB | PNG (opaque) |
| **Android** | 512×512px store, 108×108dp layers | 66×66dp | sRGB | PNG or XML |

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    GATHER REQUIREMENTS                      │
│  • App name and purpose                                      │
│  • Brand colors and style                                    │
│  • Key visual elements (symbol, text, abstract)             │
│  • Platform targets (iOS, Android, or both)                  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    DESIGN ICON CONCEPT                       │
│  • Choose base design approach                               │
│  • Apply platform-specific guidelines                        │
│  • Ensure safe zone compliance                               │
│  • Optimize for smallest display size                        │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    GENERATE SPECIFICATIONS                    │
│  • iOS: 1024×1024px master, all required sizes               │
│  • Android: Foreground + background layers, keyline shapes   │
│  • Export formats and color space requirements               │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    PROVIDE IMPLEMENTATION GUIDE              │
│  • Export instructions for all sizes                         │
│  • Xcode / Android Studio setup                              │
│  • Validation checklist                                      │
└─────────────────────────────────────────────────────────────┘
```

## Commands

| Command | Description |
|---------|-------------|
| `app-icon` | Start full icon generation workflow |
| `ios-icon` | iOS-specific icon generation |
| `android-icon` | Android-specific icon generation |
| `icon-specs` | Get technical specifications for a platform |
| `icon-validate` | Validate an existing icon against guidelines |

---

## iOS Icon Guidelines

### Shape and Geometry

- **Superellipse (squircle)** shape - DO NOT create rounded corners yourself
- System automatically applies corner masking
- Submit square icons only

### Size Requirements

| Use Case | Size | Scale |
|----------|------|-------|
| Master (App Store) | 1024×1024px | - |
| iPhone @3x | 180×180px | 60pt @3x |
| iPhone @2x | 120×120px | 60pt @2x |
| iPad Pro | 167×167px | 83.5pt @2x |
| iPad Retina | 152×152px | 76pt @2x |
| Settings | 87×87px | 29pt @3x |
| Spotlight | 80×80px | 40pt @2x |

### Safe Zone

- **Critical content**: Center 60-66% of icon
- **Minimum margin**: 90 pixels from edges (for 1024px)
- **Outer 33-40%** may be masked or cropped

### Technical Requirements

- **Color space**: sRGB (required)
- **Format**: PNG, 32-bit preferred
- **Transparency**: NOT allowed (fully opaque only)
- **File size**: Under 1MB for App Store
- **Corners**: DO NOT pre-round - system handles this

### iOS 18+ Variants

| Variant | Description |
|---------|-------------|
| **Light** | Standard full-color with background |
| **Dark** | Design WITHOUT solid background (system provides) |
| **Tinted** | Grayscale values only, no solid background |

**Sources:**
- [Apple HIG - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [iOS vs Android Icon Guidelines](https://www.iconcraft.app/blog/ios-android-guidelines)

---

## Android Icon Guidelines

### Adaptive Icon Structure

Android uses a **two-layer system**:

| Layer | Size | Purpose |
|-------|------|---------|
| **Foreground** | 108×108dp | Main visual content |
| **Background** | 108×108dp | Base color/texture |

### Keyline Shapes

Devices may apply different mask shapes:

| Shape | Description |
|-------|-------------|
| Circle | 52dp diameter |
| Squircle | Rounded square |
| Square | 44×44dp with 4dp radius |
| Rounded Square | Variable radius |
| Tear Drop | Teardrop shape |
| Rectangle | 52×36dp or 36×52dp |

### Safe Zone

- **Critical content**: 66×66dp (some sources say 72×72dp)
- Keep essential visual elements within this area
- Edges may be cropped by device masks

### Size Requirements

| Use Case | Size |
|----------|------|
| Play Store | 512×512px |
| Adaptive Layers | 108×108dp each |
| Legacy (pre-8.0) | 48×48dp, 72×72dp, 96×96dp, 144×144dp, 192×192dp |

### Technical Requirements

- **Color space**: sRGB
- **Format**: PNG or XML drawable (vector)
- **Background**: Must be fully opaque
- **No text** in icon design
- **No badges** or overlays

**Sources:**
- [Android Adaptive Icons Documentation](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- [Designing Adaptive Icons - Google Design](https://medium.com/google-design/designing-adaptive-icons-515af294c783)

---

## Design Principles

### Both Platforms

| Principle | Why |
|-----------|-----|
| **Simplicity** | Detail lost at small sizes (29×29px iOS, 48×48dp Android) |
| **Recognition** | Must be identifiable at smallest size |
| **Uniqueness** | Stand out among other apps |
| **Consistency** | Align with platform design language |

### Common Mistakes to Avoid

| Mistake | Why It's Wrong |
|---------|----------------|
| Too much detail | Invisible at small sizes |
| Text in icon | Hard to read, not localized |
| Pre-rounded corners (iOS) | System handles masking |
| Transparency (iOS) | Not supported, must be opaque |
| Critical content near edges | Will be cropped by masks |

---

## Implementation Guide

### iOS Export Checklist

```
□ Master: 1024×1024px PNG, sRGB
□ All required sizes generated
□ No transparency
□ No pre-rounded corners
□ Under 1MB file size
□ Test at smallest size (29×29px)
□ Verify in light and dark mode
```

### Android Export Checklist

```
□ Foreground: 108×108dp PNG/XML
□ Background: 108×108dp PNG/XML (opaque)
□ Play Store: 512×512px PNG
□ Safe zone compliance (66×66dp)
□ Test with different mask shapes
□ No text in design
```

---

## Validation

After generating icon specifications, verify:

- [ ] Safe zone compliance for both platforms
- [ ] Color space is sRGB
- [ ] Smallest size is legible (iOS: 29×29px, Android: 48×48dp)
- [ ] File formats are correct
- [ ] No transparency in iOS icons
- [ ] Android background is opaque
- [ ] Critical content is centered

---

<details>
<summary><strong>Deep Dive: iOS Superellipse Geometry</strong></summary>

### The iOS Squircle

iOS uses a mathematical superellipse, not a simple rounded rectangle:

- **Formula**: Superellipse with n≈5
- **Corner radius**: ~22% of icon size (roughly size/6.4)
- **Variable radius**: Curve gets larger approaching straight edges

### Why Designers Should Use Apple's Template

1. **Mathematical precision**: Cannot recreate manually with standard tools
2. **System consistency**: Apple's template ensures perfect alignment
3. **Automatic masking**: System applies shape, submit square only

### Grid System

Apple provides a grid template with:
- 10×10 base grid
- Inner zone for critical content
- Outer zone that may be masked

Use Apple's official template from Xcode or HIG resources.

</details>

<details>
<summary><strong>Deep Dive: Android Keyline System</strong></summary>

### What Are Keylines?

Keylines are shape templates that device manufacturers apply to adaptive icons:

| Device OEM | Common Shape |
|------------|--------------|
| Pixel | Circle |
| Samsung | Squircle |
| OnePlus | Circle |
| Motorola | Circle |
| Nokia | Circle |
| Sony | Squircle |

### Designing for All Keylines

Since you can't predict which shape a device will use:

1. **Keep critical content in safe zone** (66×66dp)
2. **Design foreground to work independently** of background
3. **Test with multiple masks** during development
4. **Ensure foreground and background** have visual cohesion

### Visual Effects

Android supports optional visual effects:
- **Parallax**: Slight movement when launcher is swiped
- **Zoom**: Slight scale on app launch

Account for these by adding padding to the foreground layer.

</details>

<details>
<summary><strong>Deep Dive: Color Space and Export</strong></summary>

### Why sRGB?

| Platform | Color Space | Reason |
|----------|-------------|--------|
| iOS | sRGB | Standard profile, consistent display |
| Android | sRGB | Default for Material Design |

### Export Workflow

**iOS:**
```
Design (1024×1024)
  ↓
Export to PNG (sRGB profile)
  ↓
Validate opacity (no transparency)
  ↓
Run through Xcode asset catalog
  ↓
System generates all sizes
```

**Android:**
```
Design foreground (108×108dp)
Design background (108×108dp)
  ↓
Export to PNG or XML
  ↓
Configure in res/mipmap-anydpi-v26/
  ↓
Provide legacy icons for pre-8.0
```

### Color Tips

- Use gradients sparingly (may band at small sizes)
- Ensure contrast ratio ≥ 3:1 for accessibility
- Test in both light and dark contexts
- Avoid neon colors that may oversaturate

</details>

<details>
<summary><strong>Deep Dive: Testing and Validation</strong></summary>

### iOS Testing

```bash
# Add all sizes to Xcode asset catalog
# Test on physical devices:
- iPhone (various screen sizes)
- iPad (various screen sizes)
- Test in Settings, Spotlight, Home Screen

# Verify:
- Visibility at 29×29px (Settings)
- Appearance in light/dark mode
- No artifacts from scaling
```

### Android Testing

```bash
# Test on devices with different launchers:
- Pixel Launcher (circle mask)
- One UI (squircle mask)
- Nova Launcher (various masks)
- Stock Android (squircle/circle)

# Verify:
- Safe zone compliance
- Foreground/background cohesion
- Appearance with different masks
```

### Common Issues Found in Testing

| Issue | Cause | Fix |
|-------|-------|-----|
| Icon looks blurry | Wrong export resolution | Export at 2x target size |
| Colors appear wrong | Non-sRGB profile | Convert to sRGB |
| Content cropped | Outside safe zone | Move elements inward |
| Icon has halo | Transparency present | Make fully opaque |

</details>
