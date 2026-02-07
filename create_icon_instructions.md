# Creating Liquid Glass Icon with Icon Composer

## Steps:

1. **Open Icon Composer** (already opened)

2. **Import Layers** (in order):
   - `icon_layers/01_base.png` - Base white rounded square
   - `icon_layers/02_highlight.png` - Specular highlight ellipse  
   - `icon_layers/03_glow.png` - Inner glow border

3. **Set Liquid Glass Properties**:
   - **Base Layer**: 
     - Material: Liquid Glass
     - Color: #8ACE00 (brat green)
     - Translucency: ~85%
     - Blur: Medium
   - **Highlight Layer**:
     - Blend Mode: Screen or Overlay
     - Opacity: ~70%
   - **Glow Layer**:
     - Blend Mode: Screen
     - Opacity: ~30%

4. **Adjust Specular Highlights**: Enable and set intensity to High

5. **Export as .icon file** and add to Xcode project

## Alternative: Use Assets.xcassets with proper PNG

If Icon Composer doesn't work, we can create a proper Liquid Glass PNG manually.
