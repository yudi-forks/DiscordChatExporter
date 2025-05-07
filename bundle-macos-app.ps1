param(
    [Parameter(Mandatory=$true)]
    [string]$MatrixAssetName,
    
    [Parameter(Mandatory=$true)]
    [string]$MatrixAppPath,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubSha,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRefType,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRefName,
    
    [string]$StagingDir = "app-bundle-staging",
    
    [Parameter(Mandatory=$true)]
    [string]$IconPath,

    [Parameter(Mandatory=$true)]
    [string]$Copyright,

    [Parameter(Mandatory=$true)]
    [string]$SpokenName,

    [Parameter(Mandatory=$true)]
    [string]$BundleIdentifier
)

# Setup paths
$appName = "$MatrixAssetName.app"
$appDir = Join-Path $StagingDir $appName
$contentsDir = Join-Path $appDir "Contents"
$macosDir = Join-Path $contentsDir "MacOS"
$resourcesDir = Join-Path $contentsDir "Resources"
$publishDir = Join-Path $MatrixAppPath "bin/publish"

# Create the macOS .app bundle directory structure
New-Item -ItemType Directory -Path $macosDir -Force
New-Item -ItemType Directory -Path $resourcesDir -Force

# Copy icon into the .app's Resources folder
Copy-Item -Path $IconPath -Destination (Join-Path $resourcesDir "AppIcon.icns") -Force

# Generate version string based on ref type
$versionString = if ($GitHubRefType -eq "tag") { $GitHubRefName } else { "999.9.9-ci" }

# Generate Info.plist metadata file with app information
$plistContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleDisplayName</key>
    <string>$MatrixAssetName</string>
    <key>CFBundleName</key>
    <string>$MatrixAssetName</string>
    <key>CFBundleExecutable</key>
    <string>$MatrixAssetName</string>
    <key>NSHumanReadableCopyright</key>
    <string>$Copyright</string>
    <key>CFBundleIdentifier</key>
    <string>$BundleIdentifier</string>
    <key>CFBundleSpokenName</key>
    <string>$SpokenName</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>$GitHubSha</string>
    <key>CFBundleShortVersionString</key>
    <string>$versionString</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
  </dict>
</plist>
"@

Set-Content -Path (Join-Path $contentsDir "Info.plist") -Value $plistContent

# Copy all built application files into the .app's MacOS directory
Get-ChildItem -Path $publishDir | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $macosDir -Force
}

# Move the final .app bundle into the publish directory for upload
Move-Item -Path $appDir -Destination $publishDir -Force
