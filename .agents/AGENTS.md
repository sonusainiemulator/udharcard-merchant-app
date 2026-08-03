# GitHub Release Policy
Always push both debug and release versions (APK) on the GitHub release page for every release.

## APK Naming Convention
When releasing to GitHub, always rename the APK files before uploading using this exact pattern:
- Release APK: `udharcard-merchant-app-v{version}-release.apk`
- Debug APK: `udharcard-merchant-app-v{version}-debug.apk`

Where `{version}` is the version name from pubspec.yaml (e.g. `1.0.12`).

### PowerShell snippet to use before `gh release create`:
```powershell
$version = (Select-String -Path pubspec.yaml -Pattern '^version:').Line.Split(':')[1].Trim().Split('+')[0].Trim()
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\udharcard-merchant-app-v$version-release.apk"
Copy-Item "build\app\outputs\flutter-apk\app-debug.apk" "build\app\outputs\flutter-apk\udharcard-merchant-app-v$version-debug.apk"
```
Then pass the renamed files to `gh release create`.

# Changelog Policy
Always update `CHANGELOG.md` upon completing any feature, bug fix, refactoring, or significant task.

