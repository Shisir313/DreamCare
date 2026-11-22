# App Icon Assets

Place your app icon files here to generate launcher icons for all platforms.

## Required Files

### 1. Main Icon (Required)
- **Filename**: `app_icon.png`
- **Size**: 1024x1024 pixels
- **Format**: PNG
- **Transparency**: NO (solid background for iOS compatibility)
- **Description**: Main app icon used for all platforms

### 2. Adaptive Icon Foreground (Android)
- **Filename**: `app_icon_foreground.png`
- **Size**: 432x432 pixels (or 1024x1024)
- **Format**: PNG
- **Transparency**: YES
- **Description**: Foreground layer for Android adaptive icons (icon element only)

## Design Guidelines

### Icon Specifications
- **Style**: Simple, recognizable, professional
- **Colors**: 2-3 colors maximum
- **Padding**: Leave 10% padding around edges
- **Test**: Must be recognizable at 48x48 pixels

### DermaCare Icon Concepts
1. **Water Droplet** 💧 - Blue droplet with shine
2. **Face + Drop** - Silhouette with water element
3. **Shield + Heart** - Protection + care symbol
4. **Leaf + Drop** - Natural skincare emphasis
5. **DC Monogram** - Stylized letters

## Color Scheme
```
Primary Blue: #4A90E2
Light Blue: #E3F2FD
Dark Blue: #0D47A1
White: #FFFFFF
Accent Green: #81C784
```

## Generation Steps

1. **Create Icons**
   - Design in Canva, Figma, or any design tool
   - Export as PNG at required sizes
   - Save files in this directory

2. **Generate Launcher Icons**
   ```bash
   flutter pub run flutter_launcher_icons
   ```

3. **Verify**
   ```bash
   flutter clean
   flutter run
   ```

4. **Check Platforms**
   - Android: `android/app/src/main/res/mipmap-*/`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Web: `web/icons/`

## Quick Creation Tools

- **Canva**: https://www.canva.com (search "App Icon")
- **Icon Kitchen**: https://icon.kitchen
- **AppIcon.co**: https://appicon.co
- **Figma**: https://www.figma.com

## Current Status

- [ ] Create `app_icon.png` (1024x1024)
- [ ] Create `app_icon_foreground.png` (432x432) 
- [ ] Run icon generator
- [ ] Test on Android device
- [ ] Test on iOS device (if available)

See `docs/APP_ICON_CREATION.md` for detailed guide.
