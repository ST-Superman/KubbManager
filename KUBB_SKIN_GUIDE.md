# 🎨 Kubb Skin System - Image-Based Skins Guide

## Overview
The Kubb Manager now supports both color-based and image-based skins for kubb pieces. This guide explains how to add new image-based skins using .png or .svg files.

## 📁 File Structure for Image Assets

### Assets.xcassets Organization
```
Assets.xcassets/
├── kubbSkins/
│   ├── wooden_kubb.imageset/
│   │   ├── Contents.json
│   │   ├── wooden_kubb.png
│   │   ├── wooden_kubb@2x.png
│   │   └── wooden_kubb@3x.png
│   ├── wooden_king.imageset/
│   │   ├── Contents.json
│   │   ├── wooden_king.png
│   │   ├── wooden_king@2x.png
│   │   └── wooden_king@3x.png
│   ├── marble_kubb.imageset/
│   │   └── ...
│   └── viking_kubb.imageset/
│       └── ...
```

## 🖼️ Image Requirements

### Kubb Piece Images
- **Format**: PNG (recommended) or SVG
- **Aspect Ratio**: 2:5 (width:height) for regular kubbs
- **Recommended Size**: 40x100 points (120x300px @3x)
- **Background**: Transparent (PNG with alpha channel)
- **Orientation**: Vertical (standing kubb)

### King Piece Images
- **Format**: PNG (recommended) or SVG
- **Aspect Ratio**: 2:5 (width:height) for king kubbs
- **Recommended Size**: 48x120 points (144x360px @3x)
- **Background**: Transparent (PNG with alpha channel)
- **Orientation**: Vertical (standing king)

## 📝 Adding New Image-Based Skins

### Step 1: Add Images to Assets.xcassets
1. Create new image sets in `Assets.xcassets/kubbSkins/`
2. Name them descriptively (e.g., `wooden_kubb`, `marble_king`)
3. Include @2x and @3x versions for retina displays

### Step 2: Add Skin Definition
Add your skin to the `KubbSkin.defaultSkins` array in `KubbSkin.swift`:

```swift
KubbSkin(
    id: "your_skin_id",
    name: "Your Skin Name",
    description: "Description of your skin",
    category: .yourCategory,
    unlockType: .achievement,
    unlockRequirement: "What user needs to do",
    kubbColor: SkinColor(red: 0.0, green: 0.5, blue: 1.0), // Fallback color
    kingColor: SkinColor(red: 0.5, green: 0.0, blue: 0.8), // Fallback color
    kubbImageName: "your_kubb_image",     // Image name (without .png)
    kingImageName: "your_king_image",     // Image name (without .png)
    kubbImageScale: 1.0,                  // Scale factor (1.0 = normal)
    kingImageScale: 1.2,                  // Scale factor (1.2 = 20% larger)
    iconName: "star.fill",
    previewImageName: "your_preview"
)
```

## 🎨 Image Design Guidelines

### Visual Style
- **Consistent Lighting**: Use consistent light source direction
- **Realistic Proportions**: Maintain realistic kubb piece proportions
- **Clear Details**: Ensure details are visible at small sizes
- **High Contrast**: Good contrast against game background

### Color Considerations
- **Fallback Colors**: Always provide fallback colors for compatibility
- **Accessibility**: Ensure good contrast and visibility
- **Theme Consistency**: Match the overall skin theme

### Technical Specifications
- **File Size**: Keep under 100KB per image for performance
- **Resolution**: Provide @1x, @2x, and @3x versions
- **Format**: PNG with transparency for best results
- **Naming**: Use descriptive, consistent naming convention

## 🔧 Advanced Features

### Image Scaling
Use `kubbImageScale` and `kingImageScale` to adjust image size:
- `1.0` = Normal size
- `1.2` = 20% larger
- `0.8` = 20% smaller

### Fallback System
The system automatically falls back to color-based rendering if:
- Image file is missing
- Image fails to load
- Device has low memory

### Animation Support
Image-based skins support all existing animations:
- Knock-over animation
- Rotation effects
- Scale transitions
- Position changes

## 📋 Complete Example

Here's a complete example of adding a "Crystal Kubb" skin:

### 1. Add Images to Assets.xcassets
- `crystal_kubb.png` (40x100 points)
- `crystal_king.png` (48x120 points)
- Include @2x and @3x versions

### 2. Add Skin Definition
```swift
KubbSkin(
    id: "crystal_kubb",
    name: "Crystal Kubb",
    description: "Transparent crystal kubb pieces that shimmer",
    category: .fantasy,
    unlockType: .achievement,
    unlockRequirement: "Achieve 95% accuracy in 3 sessions",
    kubbColor: SkinColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.8),
    kingColor: SkinColor(red: 1.0, green: 0.8, blue: 1.0, alpha: 0.9),
    kubbImageName: "crystal_kubb",
    kingImageName: "crystal_king",
    kubbImageScale: 1.0,
    kingImageScale: 1.3,
    iconName: "sparkles",
    previewImageName: "crystal_kubb_preview"
)
```

## 🚀 Best Practices

### Performance
- Optimize image file sizes
- Use appropriate image scales
- Test on different device sizes

### User Experience
- Provide clear unlock requirements
- Use descriptive names and descriptions
- Ensure good visual hierarchy

### Maintenance
- Keep consistent naming conventions
- Document custom unlock requirements
- Test fallback behavior

## 🔍 Troubleshooting

### Common Issues
1. **Image not showing**: Check image name matches exactly
2. **Wrong size**: Adjust `kubbImageScale` or `kingImageScale`
3. **Poor quality**: Ensure @3x version is high resolution
4. **Animation issues**: Verify image has transparent background

### Testing
- Test on different device sizes
- Verify fallback colors work
- Check unlock requirements function correctly
- Ensure animations work smoothly

## 📚 Additional Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Image Documentation](https://developer.apple.com/documentation/swiftui/image)
- [Asset Catalog Best Practices](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/)

---

This system provides maximum flexibility while maintaining performance and user experience. You can create highly detailed, realistic kubb pieces that enhance the visual appeal of your training app!
