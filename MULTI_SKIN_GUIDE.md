# Multi-Skin System Guide

## Overview

The Kubb Manager now supports a sophisticated multi-skin system that allows you to provide multiple images for kubbs, batons, and kings, with random selection and custom down animations.

## Features

### 1. Multiple Kubb Images (1-10)
- Provide 1-10 kubb images (Swedish_Kubb_1, Swedish_Kubb_2, etc.)
- If only 1 image provided, all kubbs look the same
- If multiple images provided, each kubb gets a randomly selected image

### 2. Multiple King Images (1+)
- Provide 1+ king images
- Random selection for each session

### 3. Multiple Baton Images (1-6)
- Provide 1-6 baton images
- Each baton gets a randomly selected image

### 4. Custom Down Images
- Optional custom "knocked down" images for kubbs and king
- If no custom down image provided, the standing image rotates
- If custom down images provided, smooth transition animation

## Implementation

### KubbSkin Model Updates

The `KubbSkin` struct now includes:

```swift
// Multiple kubb images (1-10)
let kubbImageNames: [String]
let kubbDownImageNames: [String] // Custom down images

// Multiple king images (1+)
let kingImageNames: [String]
let kingDownImageNames: [String] // Custom down images

// Multiple baton images (1-6)
let batonImageNames: [String]
```

### Helper Methods

```swift
// Get random kubb image for specific index (0-9)
func getKubbImageName(for index: Int) -> String?

// Get random kubb down image for specific index (0-9)
func getKubbDownImageName(for index: Int) -> String?

// Get random king image
func getKingImageName() -> String?

// Get random king down image
func getKingDownImageName() -> String?

// Get random baton image for specific index (0-5)
func getBatonImageName(for index: Int) -> String?
```

## Usage Examples

### Example 1: Single Image (All Look the Same)
```swift
let swedishSkin = KubbSkin(
    id: "swedish_single",
    name: "Swedish Classic",
    // ... other properties ...
    kubbImageName: "Swedish_Kubb", // Single image
    kingImageName: "Swedish_King", // Single image
    batonImageName: "Swedish_Baton" // Single image
)
```

### Example 2: Multiple Images (Random Selection)
```swift
let swedishMultiSkin = KubbSkin(
    id: "swedish_multi",
    name: "Swedish Variety",
    // ... other properties ...
    kubbImageNames: [
        "Swedish_Kubb_1",
        "Swedish_Kubb_2",
        "Swedish_Kubb_3",
        "Swedish_Kubb_4",
        "Swedish_Kubb_5"
    ],
    kubbDownImageNames: [
        "Swedish_Kubb_Down_1",
        "Swedish_Kubb_Down_2",
        "Swedish_Kubb_Down_3",
        "Swedish_Kubb_Down_4",
        "Swedish_Kubb_Down_5"
    ],
    kingImageNames: [
        "Swedish_King_1",
        "Swedish_King_2"
    ],
    kingDownImageNames: [
        "Swedish_King_Down_1",
        "Swedish_King_Down_2"
    ],
    batonImageNames: [
        "Swedish_Baton_1",
        "Swedish_Baton_2",
        "Swedish_Baton_3"
    ]
)
```

### Example 3: Mixed (Some Multiple, Some Single)
```swift
let mixedSkin = KubbSkin(
    id: "mixed_skin",
    name: "Mixed Variety",
    // ... other properties ...
    kubbImageNames: [
        "Kubb_Variant_1",
        "Kubb_Variant_2",
        "Kubb_Variant_3"
    ],
    // No custom down images - will use rotation
    kingImageName: "Single_King", // Single king image
    kingDownImageName: "Single_King_Down", // Single down image
    batonImageNames: [
        "Baton_1",
        "Baton_2"
    ]
)
```

## Image Naming Conventions

### Kubb Images
- Standing: `Swedish_Kubb_1`, `Swedish_Kubb_2`, ..., `Swedish_Kubb_10`
- Down: `Swedish_Kubb_Down_1`, `Swedish_Kubb_Down_2`, ..., `Swedish_Kubb_Down_10`

### King Images
- Standing: `Swedish_King_1`, `Swedish_King_2`, etc.
- Down: `Swedish_King_Down_1`, `Swedish_King_Down_2`, etc.

### Baton Images
- `Swedish_Baton_1`, `Swedish_Baton_2`, ..., `Swedish_Baton_6`

## Animation Behavior

### With Custom Down Images
- Smooth transition from standing image to down image
- No rotation animation
- Custom down image is displayed when knocked down

### Without Custom Down Images
- Standing image rotates 90 degrees when knocked down
- Original rotation animation behavior

## Backward Compatibility

The system is fully backward compatible:
- Existing skins with single images continue to work
- New multi-image properties are optional
- Falls back to single image if multiple images not provided

## Performance Considerations

- Images are selected once per kubb/king when the view appears
- No performance impact during gameplay
- Random selection is deterministic per kubb position for consistency
