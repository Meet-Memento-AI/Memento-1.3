# Tab Bar Implementation - Apple HIG Compliant

## Overview
This implementation uses **native iOS 26+ Liquid Glass TabView** with a space-between layout where tab items are grouped on the left and a floating action button is positioned on the right.

## Implementation Details

### iOS 26+ (Liquid Glass)
- Uses the new `Tab` API introduced in iOS 26
- Native `.sidebarAdaptable` tab view style
- Automatic Liquid Glass material background
- Proper integration with toolbar items for the floating action button

### iOS 25 and Below (Fallback)
- Uses traditional `TabView` with `.tabItem`
- Manual toolbar button placement
- Maintains same visual spacing approach

## Key Components

### 1. RootTabView (BottomTabsNav.swift)
Main tab container with version checking:
```swift
if #available(iOS 26.0, *) {
    TabView(selection: $selectedTab) {
        Tab("Journal", systemImage: "book.closed", value: BottomTabType.journal) {
            // Content with toolbar button
        }
        Tab("Insights", systemImage: "sparkles", value: BottomTabType.insights) {
            // Content with toolbar button
        }
    }
    .tabViewStyle(.sidebarAdaptable)
}
```

### 2. Floating Action Button
Positioned using toolbar items:
```swift
.toolbar {
    ToolbarItem(placement: .bottomBar) {
        Spacer() // Pushes button to trailing edge
    }
    ToolbarItem(placement: .bottomBar) {
        Button { ... } label: {
            // Circular button with primary color
        }
    }
}
```

## Apple HIG Compliance

✅ **Tab Bar Placement** - Bottom of screen (native iOS behavior)
✅ **Tab Count** - 2 tabs (well within 3-5 recommended limit)
✅ **Icon Sizing** - System handles sizing automatically
✅ **Touch Targets** - Native components ensure 44pt minimum
✅ **Visual Feedback** - System provides selection states
✅ **Accessibility** - Native accessibility labels and traits
✅ **Liquid Glass** - Automatic on iOS 26+
✅ **Persistent Navigation** - Always visible tab bar

### Space-Between Layout
- **Left side**: Tab items grouped naturally by the system
- **Right side**: Floating action button via toolbar Spacer()
- **Material**: Ultra-thin material (iOS 26+) or standard tab bar (iOS 25-)

## Button Specifications

### Floating Action Button
- **Size**: 56x56pt circular button
- **Icon**: square.and.pencil (22pt, semibold)
- **Background**: Primary color gradient with shadow
- **Position**: Trailing edge via ToolbarItem + Spacer
- **Touch Target**: Exceeds 44pt minimum (HIG compliant)

## Color Scheme
- **Selected Tab**: PrimaryScale.primary600 (#6125B1)
- **Unselected Tab**: System opacity (handled by native components)
- **FAB Background**: theme.primary with gradient
- **FAB Shadow**: Primary color at 30% opacity, 12pt radius

## Files Modified
1. `BottomTabsNav.swift` - Main tab view with iOS version checking
2. `TabTest.swift` - Test component following same pattern
3. `TabPill.swift` - Kept for TabSwitcher compatibility (separate component)

## Best Practices Applied

### From Apple HIG Tab Bars Documentation

1. **Always visible** - Tab bar remains persistent across navigation
2. **Limited tabs** - Only 2 tabs (< 5 maximum)
3. **Clear purpose** - Each tab leads to distinct top-level content
4. **Consistent icons** - Using SF Symbols with filled variants
5. **Native behavior** - Leveraging system components
6. **Accessibility** - Proper labels and hints for all interactive elements

### Additional Considerations

- **Haptic Feedback**: Medium impact on button tap
- **Animations**: System-provided transitions
- **Dark Mode**: Automatic adaptation via theme system
- **iPad Support**: Tab view automatically adapts layout

## References
- [Apple Developer Tab Bars Documentation](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Enhancing your app's content with tab navigation](https://developer.apple.com/documentation/SwiftUI/Enhancing-your-app-content-with-tab-navigation)
