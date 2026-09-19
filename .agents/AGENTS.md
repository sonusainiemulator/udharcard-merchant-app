# GitHub Release Policy (STRICT & MANDATORY)
**ALWAYS build and upload BOTH Debug APK and Release APK to GitHub Releases on EVERY release.** Never skip the Debug APK under any circumstances.

## APK Naming & Upload Convention
When creating a GitHub release, always provide both named versions and standard names so users and testing tools can access both:
- **Release APK**: `udharcard-merchant-app-v{version}-release.apk`
- **Debug APK**: `udharcard-merchant-app-v{version}-debug.apk` (and also attach `app-debug.apk`)

Where `{version}` is the version name from `pubspec.yaml` (e.g. `1.0.68`).

### Mac / Zsh / Bash snippet to prepare and create release:
```bash
version=$(grep '^version:' pubspec.yaml | cut -d: -f2 | tr -d ' ' | cut -d+ -f1)
cp build/app/outputs/flutter-apk/app-release.apk "build/app/outputs/flutter-apk/udharcard-merchant-app-v${version}-release.apk"
cp build/app/outputs/flutter-apk/app-debug.apk "build/app/outputs/flutter-apk/udharcard-merchant-app-v${version}-debug.apk"
gh release create "v${version}" \
  "build/app/outputs/flutter-apk/udharcard-merchant-app-v${version}-release.apk" \
  "build/app/outputs/flutter-apk/udharcard-merchant-app-v${version}-debug.apk" \
  build/app/outputs/flutter-apk/app-debug.apk \
  --title "v${version}: Title Here" \
  --notes "Release Notes Here"
```

# Changelog & GitHub Push Policy (Mandatory)
Always update `CHANGELOG.md` upon completing each and every feature, bug fix, refactoring, or significant task.
- Every new entry in `CHANGELOG.md` MUST include the exact **Date and Time** (e.g. `YYYY-MM-DD HH:MM:SS IST`).
- Immediately after making the entry and committing the changes, **always push to GitHub** (`git push origin master` or the current branch).
- Never skip pushing to GitHub after completing a task.

