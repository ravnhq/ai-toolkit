# App Icon Size Quick Reference

## iOS Sizes

### Master / App Store
| Use | Size | Notes |
|-----|------|-------|
| App Store | **1024 × 1024 px** | Design at this size |

### iPhone
| Use Case | Size (px) | Points | Scale |
|----------|-----------|--------|-------|
| Home Screen @3x | 180 × 180 | 60 pt | @3x |
| Home Screen @2x | 120 × 120 | 60 pt | @2x |
| Spotlight | 120 × 120 | 40 pt | @3x |
| Settings | 87 × 87 | 29 pt | @3x |
| Settings @2x | 58 × 58 | 29 pt | @2x |

### iPad
| Use Case | Size (px) | Points | Scale |
|----------|-----------|--------|-------|
| iPad Pro | 167 × 167 | 83.5 pt | @2x |
| iPad Retina | 152 × 152 | 76 pt | @2x |
| Spotlight | 80 × 80 | 40 pt | @2x |
| Settings | 58 × 58 | 29 pt | @2x |

---

## Android Sizes

### Play Store
| Use | Size | Notes |
|-----|------|-------|
| Store Listing | **512 × 512 px** | Required for Play Store |

### Adaptive Icons (Android 8.0+)
| Layer | Size | Notes |
|-------|------|-------|
| Foreground | 108 × 108 dp | Can be transparent |
| Background | 108 × 108 dp | Must be opaque |

### Legacy Icons (Pre-Android 8.0)
| Density | Size (px) | Scale |
|---------|-----------|-------|
| mdpi | 48 × 48 | 1× (base) |
| hdpi | 72 × 72 | 1.5× |
| xhdpi | 96 × 96 | 2× |
| xxhdpi | 144 × 144 | 3× |
| xxxhdpi | 192 × 192 | 4× |

### Adaptive Icon Export (PNG)
| Density | Size (px) for 108 dp |
|---------|----------------------|
| mdpi | 108 × 108 |
| hdpi | 162 × 162 |
| xhdpi | 216 × 216 |
| xxhdpi | 324 × 324 |
| xxxhdpi | 432 × 432 |

---

## Comparison Table

| Aspect | iOS | Android |
|--------|-----|---------|
| **Master Size** | 1024 × 1024 px | 512 × 512 px (store) |
| **Working Size** | 1024 × 1024 px | 108 × 108 dp (adaptive) |
| **Safe Zone** | Center 66% (~680px) | 66 × 66 dp |
| **Smallest Size** | 29 × 29 pt | 48 × 48 dp (legacy) |
| **Color Space** | sRGB | sRGB |
| **Format** | PNG | PNG or XML |
| **Transparency** | Not allowed | Allowed in foreground only |
| **Corners** | System applies | Device masks vary |

---

## Safe Zones at a Glance

### iOS Safe Zone (1024 × 1024 canvas)

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

Margin: ~90px from each edge (for 1024px master)
Safe area: Center ~680 × 680 px
```

### Android Safe Zone (108 × 108 dp canvas)

```
┌─────────────────────────────────────────────────────────────┐
│                   FULL 108×108dp LAYER                      │
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

Margin: 21dp from each edge
Safe area: 66 × 66 dp (center ~61% of canvas)
```

---

## Export Checklist Summary

### iOS Export
- [ ] 1024 × 1024 px PNG
- [ ] sRGB color profile
- [ ] No transparency (opaque)
- [ ] No pre-rounded corners
- [ ] Under 1 MB file size
- [ ] Critical content in center 66%

### Android Export
- [ ] Foreground: 108 × 108 dp (PNG or XML)
- [ ] Background: 108 × 108 dp (PNG or XML, opaque)
- [ ] Play Store: 512 × 512 px PNG
- [ ] sRGB color profile
- [ ] Critical content in 66 × 66 dp zone
- [ ] Legacy icons: 48-192 dp depending on density

---

## Minimum Test Sizes

When validating your design, always test at these minimum sizes:

| Platform | Minimum Size | Why It Matters |
|----------|--------------|----------------|
| **iOS** | 29 × 29 pt | Settings icon size |
| **Android** | 48 × 48 dp | Legacy/mdpi icon size |

If your design is not clearly recognizable at these sizes, simplify it.
