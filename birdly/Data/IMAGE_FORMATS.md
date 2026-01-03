# Image Format Documentation

## Supported Image Formats

The app supports two image source types:

### 1. Asset Catalog Images (Current Format - Backward Compatible)

Use the simple `imageName` string format:

```json
{
  "imageName": "robin"
}
```

This will automatically be converted to `ImageSource.asset(name: "robin")`.

### 2. New Flexible Format

Use the `imageSource` object format for more control:

#### Asset Catalog Image:
```json
{
  "imageSource": {
    "type": "asset",
    "value": "robin"
  }
}
```

#### URL Image:
```json
{
  "imageSource": {
    "type": "url",
    "value": "https://example.com/bird-images/robin.jpg"
  }
}
```

## Usage in Code

Use the `BirdImageView` component to display images:

```swift
BirdImageView(imageSource: bird.imageSource, contentMode: .fill)
```

The component automatically handles:
- Asset catalog images (instant loading)
- URL images (async loading with loading states and error handling)







