# iOS App Icon Guidelines - Complete Reference

## Overview

iOS app icons use a **superellipse (squircle) shape** that the system automatically applies. Designers must submit **square icons only** - never pre-round corners.

## Shape and Geometry

### Superellipse Specification

| Property | Value |
|----------|-------|
| **Shape type** | Superellipse (not simple rounded rectangle) |
| **Formula** | Superellipse with n ≈ 5 |
| **Corner radius** | ~22% of icon size (roughly size/6.4) |
| **Radius behavior** | Variable - gets larger approaching straight edges |

### Why You Cannot Recreate the Squircle

The iOS corner curve is mathematically complex:
1. Not a standard bezier curve in most design tools
2. Variable radius increases near straight edges
3. Requires Apple's official template for precision

**Always use Apple's grid template** from Xcode or Human Interface Guidelines resources.

## Complete Size Requirements

### Master Size

| Use | Size | Notes |
|-----|------|-------|
| **App Store / Master** | 1024 × 1024 px | Design at this size, system generates others |

### iPhone Sizes

| Use Case | Size | Points | Scale |
|----------|------|--------|-------|
| Home Screen (Plus/Max) | 180 × 180 px | 60 pt | @3x |
| Home Screen (Standard) | 120 × 120 px | 60 pt | @2x |
| Spotlight / Search | 120 × 120 px | 40 pt | @3x |
| Settings | 87 × 87 px | 29 pt | @3x |
| Settings (older) | 58 × 58 px | 29 pt | @2x |
| Notifications | 60 × 60 px | 20 pt | @3x |
| Notifications (older) | 40 × 40 px | 20 pt | @2x |

### iPad Sizes

| Use Case | Size | Points | Scale |
|----------|------|--------|-------|
| Home Screen (Pro) | 167 × 167 px | 83.5 pt | @2x |
| Home Screen (Retina) | 152 × 152 px | 76 pt | @2x |
| Spotlight | 80 × 80 px | 40 pt | @2x |
| Settings | 58 × 58 px | 29 pt | @2x |

### Design Implication

**Critical requirement**: Must be recognizable at **29 × 29 pixels** (smallest size). Test your design at this scale.

## Safe Zone Guidelines

### Safe Area for 1024×1024px Master

| Zone | Area | Purpose |
|------|------|---------|
| **Critical content** | Center 60-66% | Essential visual elements |
| **Safe margin** | 90 px from edges | Minimum padding for 1024px |
| **Outer area** | Outer 33-40% | May be masked/cropped |

### Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                         OUTER 17%                           │  ← May be masked
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    OUTER 17%                          │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              CRITICAL 66% ZONE                 │  │  │  ← Safe for content
│  │  │                                                 │  │  │
│  │  │          Keep essential elements here          │  │  │
│  │  │                                                 │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Safe Zone by Size

| Master Size | Critical Zone | Safe Margin |
|-------------|---------------|-------------|
| 1024 × 1024 px | Center ~680 px | 90 px |
| 180 × 180 px | Center ~120 px | ~16 px |
| 120 × 120 px | Center ~80 px | ~11 px |

### Additional Safety Considerations

- **Focus effects**: iOS may apply subtle depth/blur when user focuses on icon
- **Motion effects**: Parallax may shift content slightly
- **Layer depth**: Foreground layers are cropped more aggressively than backgrounds
- **Edge content**: May be rounded or masked depending on context

## Color Space Requirements

### Required Color Profiles

| Profile | When to Use |
|---------|-------------|
| **sRGB** | Standard for all iOS icons (primary) |
| **Gray Gamma 2.2** | Grayscale or tinted icons |
| **Display P3** | Wide-gamut color (optional, supported on iOS 10+) |

### sRGB Requirement

**Why sRGB is mandatory:**
- Consistent color reproduction across devices
- Standard profile for iOS rendering
- Prevents color shifts when displayed

### Color Best Practices

| Practice | Why |
|----------|-----|
| Use sRGB profile | Consistent display |
| Avoid neon colors | May oversaturate on some displays |
| Ensure contrast | Minimum 3:1 ratio for accessibility |
| Test on devices | Colors vary by screen |

### Dark Mode Icons (iOS 18+)

| Variant | Requirements |
|---------|--------------|
| **Light** | Full-color with background (standard) |
| **Dark** | Design WITHOUT solid background - system provides |
| **Tinted** | Grayscale values only, no solid background |

**Dark mode guidelines:**
- Use complementary colors to light version
- Avoid excessively bright images
- May use gradients and opacity
- Base on light icon design

## File Format Requirements

### Specifications

| Property | Requirement |
|----------|-------------|
| **Format** | PNG (32-bit preferred) |
| **Dimensions** | Square only (1024 × 1024 px for master) |
| **Transparency** | NOT allowed - must be fully opaque |
| **Color space** | sRGB (required) |
| **Corner radius** | DO NOT apply - system handles this |
| **Shadows/gloss** | DO NOT add - system handles this |
| **Max file size** | Under 1 MB for App Store submission |

### Why No Transparency

- iOS renders icons on variable backgrounds
- Transparency can cause visual artifacts
- System may add its own effects
- Ensures consistent appearance

### Why No Pre-Rounded Corners

- Each device may use slightly different corner radius
- System optimizes for display context
- Future iOS versions may change radius
- Guarantees consistency across iOS versions

## Asset Catalog Integration

### Xcode Asset Catalog

1. Create App Icon asset in Xcode
2. Drag 1024×1024 master into "App Store" slot
3. System automatically generates all required sizes
4. Can add alternate app icons (Xcode 13+)

### Asset Catalog Slots

| Slot | Size | Platform |
|------|------|----------|
| App Store | 1024 × 1024 | Universal |
| iPhone @2x | 120 × 120 | iPhone |
| iPhone @3x | 180 × 180 | iPhone |
| iPad @2x | 152 × 152 | iPad |
| iPad Pro @2x | 167 × 167 | iPad Pro |
| Settings @2x | 58 × 58 | Universal |
| Settings @3x | 87 × 87 | Universal |

## Design Principles

### Core iOS Icon Principles

| Principle | Description | Application |
|-----------|-------------|-------------|
| **Simplicity** | Clear, uncluttered designs | Limit elements, avoid detail |
| **Recognition** | Identifiable at smallest size | Test at 29×29px |
| **Uniqueness** | Distinctive from other apps | Avoid cliché symbols |
| **Consistency** | Align with iOS design language | Follow platform conventions |

### Common Design Mistakes

| Mistake | Why It's Wrong | Alternative |
|---------|----------------|-------------|
| Too much detail | Lost at small sizes | Simple, bold shapes |
| Text in icon | Hard to read, not localized | Symbol-only design |
| Pre-rounded corners | Inconsistent with system | Submit square only |
| Transparency | Not supported, artifacts | Use opaque background |
| Near-edge content | Gets masked/cropped | Keep in safe zone |
| Gloss effects | System adds automatically | Flat design |
| Small logo on large field | Wasted space | Fill canvas intentionally |

### Recommended Design Approach

1. **Start with symbol**: What represents your app?
2. **Use bold geometry**: Simple shapes work best
3. **Limit color palette**: 1-3 colors maximum
4. **Test at small sizes**: Verify 29×29px legibility
5. **Check safe zones**: Ensure critical content centered
6. **Validate on devices**: Test on actual iOS devices

## Validation Checklist

### Before Export

```
□ Design at 1024×1024px
□ All content in 66% safe zone
□ Minimum 90px margin from edges
□ sRGB color profile assigned
□ No transparency in design
□ No pre-rounded corners
□ No shadows/gloss effects
```

### After Export

```
□ PNG format
□ sRGB profile preserved
□ File size under 1MB
□ Opaque (no alpha channel)
□ Square dimensions
```

### Final Testing

```
□ Visible at 29×29px (smallest size)
□ Legible in Settings app
□ Clear in Spotlight search
□ Looks correct in light mode
□ Looks correct in dark mode (iOS 18+)
□ Test on multiple iOS devices
```

## Export Workflow

### Recommended Export Process

```
Design Phase (1024×1024 canvas)
    ↓
Apply Safe Zone Guidelines (center 66%)
    ↓
Limit Detail (test at 29×29)
    ↓
Assign sRGB Profile
    ↓
Export as PNG
    ↓
Validate File Size (< 1MB)
    ↓
Add to Xcode Asset Catalog
    ↓
Test on Devices
```

### Export Settings (for design tools)

| Setting | Value |
|---------|-------|
| Format | PNG |
| Bit depth | 32-bit |
| Color profile | sRGB |
| Transparency | Off/None |
| Interlacing | None |

## Resources

### Official Documentation

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Apple Developer - App Icons](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

### Templates and Tools

- Xcode Asset Catalog (built-in templates)
- Apple Design Resources (official Sketch/Figma templates)
- App Icon Generator (third-party, use with caution)

## Sources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [iOS vs Android: App Icon Guidelines for 2025](https://www.iconcraft.app/blog/ios-android-guidelines)
