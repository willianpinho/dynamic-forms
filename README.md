# Dynamic Forms

A cross-platform project for dynamic forms with native implementations for Android and iOS.

## Project Structure

This main repository contains:
- Shared configurations and documentation
- JSON schemas for dynamic forms
- Git submodules for native implementations

### Submodules

- `dynamic-forms-android/` - Android implementation (Kotlin)
- `dynamic-forms-ios/` - iOS implementation (Swift)

## Working with Submodules

### Initial Clone
```bash
git clone --recursive https://github.com/willianpinho/dynamic-forms.git
```

### Clone without submodules (then initialize)
```bash
git clone https://github.com/willianpinho/dynamic-forms.git
cd dynamic-forms
git submodule init
git submodule update
```

### Update submodules
```bash
git submodule update --remote
```

### Working on a submodule
```bash
cd dynamic-forms-android  # or dynamic-forms-ios
# Make changes, commits, etc.
# The submodule is an independent Git repository
```

### Update submodule reference in main project
```bash
# After making commits in the submodule
git add dynamic-forms-android  # or dynamic-forms-ios
git commit -m "Update Android submodule to latest version"
```

## Configuration Files

- `200-form.json` - Complex form example
- `all-fields.json` - Example with all supported field types

## License

MIT License - see the [LICENSE](LICENSE) file for details.