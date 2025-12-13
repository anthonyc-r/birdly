# Asset Organization Guide

This document describes how assets are organized by topic.

## Topic Structure

### Common Garden Birds
**Topic Image:** `Common Garden Birds.imageset`

**Bird Images:**
- Blackbird (Perched, Flight Side, Flight Underbelly)
- Blue Tit (Perched, Flight Side, Flight Underbelly)
- Goldfinch (Perched, Flight Side, Flight Underbelly)
- Great Tit (Perched, Flight Side, Flight Underbelly)
- House Sparrow (Perched, Flight Side, Flight Underbelly)
- Long Tailed Tit (Perched, Flight Side, Flight Underbelly)
- Magpie (Perched, Flight Side, Flight Underbelly)
- Robin (Perched, Flight Side, Flight Underbelly)
- Starling (Perched, Flight Side, Flight Underbelly)
- Wood Pigeon (Perched, Flight Side, Flight Underbelly)

### Winter Birds
**Topic Image:** `Winter Birds.imageset`

**Bird Images:**
- Bullfinch (Perched, Flight Side, Flight Underbelly)
- Chaffinch (Perched, Flight Side, Flight Underbelly)
- Coal Tit (Perched, Flight Side, Flight Underbelly)
- Collared Dove (Perched, Flight Side, Flight Underbelly)
- Dunnock (Perched, Flight Side, Flight Underbelly)
- Greenfinch (Perched, Flight Side, Flight Underbelly)
- Jackdaw (Perched, Flight Side, Flight Underbelly)
- Nuthatch (Perched, Flight Side, Flight Underbelly)
- Song Thrush (Perched, Flight Side, Flight Underbelly)
- Wren (Perched, Flight Side, Flight Underbelly)

## Recommended Asset Catalog Organization

In Xcode, organize the Assets.xcassets catalog as follows:

```
Assets.xcassets/
├── AppIcon.appiconset/
├── Splash.imageset/
├── Common Garden Birds/
│   ├── Common Garden Birds.imageset/
│   ├── Blackbird Perched.imageset/
│   ├── Blackbird Flight Side.imageset/
│   ├── Blackbird Flight Underbelly.imageset/
│   ├── Blue Tit Perched.imageset/
│   ├── Blue Tit Flight Side.imageset/
│   ├── Blue Tit Flight Underbelly.imageset/
│   ├── ... (other Common Garden Birds images)
└── Winter Birds/
    ├── Winter Birds.imageset/
    ├── Bullfinch Perched.imageset/
    ├── Bullfinch Flight Side.imageset/
    ├── Bullfinch Flight Underbelly.imageset/
    ├── ... (other Winter Birds images)
```

## Notes

- Topic images (Common Garden Birds, Winter Birds) should remain at the root or in their respective topic folders
- Each bird has 3 image variants: perched, flight_side, and flight_underbelly
- The asset names in the JSON files reference these imageset names directly
- Organizing assets into folders helps maintain clarity and makes it easier to manage large numbers of images


