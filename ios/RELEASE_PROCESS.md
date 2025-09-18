# IzzoCam Release Process

## Available Fastlane Lanes

### 🧪 Testing & Development
```bash
# Build and upload to TestFlight (beta testing)
fastlane beta

# Build release candidate for final testing before App Store
fastlane release_candidate
```

### 🚀 App Store Release
```bash
# Build and submit to App Store (manual review submission)
fastlane release

# Check current version and build number
fastlane version_info

# Bump version number
fastlane bump_version type:patch   # 1.0.0 → 1.0.1
fastlane bump_version type:minor   # 1.0.0 → 1.1.0  
fastlane bump_version type:major   # 1.0.0 → 2.0.0
```

## Release Workflow

### 1. Development to TestFlight
1. **Test your changes locally**
2. **Upload to TestFlight**: `fastlane beta`
3. **Test with beta users**
4. **Repeat until ready for release**

### 2. TestFlight to App Store
1. **Final testing**: `fastlane release_candidate`
2. **Test thoroughly in TestFlight**
3. **Bump version if needed**: `fastlane bump_version type:patch`
4. **Submit to App Store**: `fastlane release`
5. **Manually submit for review in App Store Connect**

## Configuration Notes

### Automatic vs Manual Submission
- **Current setup**: Builds upload but don't auto-submit for review
- **To enable auto-submission**: Edit `Fastfile` and set `submit_for_review: true`
- **To enable auto-release**: Edit `Fastfile` and set `automatic_release: true`

### Metadata Management
- **App description**: `fastlane/metadata/en-US/description.txt`
- **Keywords**: `fastlane/metadata/en-US/keywords.txt`
- **Screenshots**: Place in `fastlane/screenshots/en-US/`
- **Release notes**: `fastlane/metadata/en-US/release_notes.txt`

### Version Strategy
- **Build numbers**: Auto-incremented with each upload
- **Version numbers**: Manually managed with `bump_version` lane
- **Recommendation**: Use semantic versioning (major.minor.patch)

## Security
- API keys are stored in `.env` file (not committed to git)
- Screenshots and metadata are committed for team collaboration
- AuthKey.p8 is excluded from git for security