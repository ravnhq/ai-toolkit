#!/usr/bin/swift sh

// ──────────────────────────────────────────────────────────────────────────────
// add_to_xcodeproj.swift
//
// Adds a file to an Xcode project (.pbxproj) using the XcodeProj library.
// Creates a PBXFileReference, places it in the correct group hierarchy,
// registers it in the target's Resources build phase, and enables the
// SWIFT_EMIT_LOC_STRINGS build setting.
//
// Dependencies are resolved at runtime by swift-sh — XcodeProj is NOT
// installed in the app's Package.swift or Xcode project.
//
// Usage:
//   swift sh .claude/skills/localize-ios/scripts/add_to_xcodeproj.swift \
//     <path/to/Project.xcodeproj> <path/to/file> \
//     [--group <GroupName>] [--target <TargetName>]
//
// Examples:
//   swift sh add_to_xcodeproj.swift MyApp.xcodeproj \
//     "MyApp/Resources/Localization/Localizable.xcstrings"
//
//   swift sh add_to_xcodeproj.swift MyApp.xcodeproj \
//     "MyApp/Resources/Localization/Localizable.xcstrings" \
//     --group Localization
//
//   swift sh add_to_xcodeproj.swift MyApp.xcodeproj \
//     "MyApp/Resources/Localization/Localizable.xcstrings" \
//     --group Localization --target "MyApp"
// ──────────────────────────────────────────────────────────────────────────────

import Foundation
import XcodeProj  // tuist/XcodeProj ~> 8.0
// PathKit is a transitive dependency of XcodeProj — provides the Path type
import PathKit

// MARK: - File Type Mapping

/// Maps common file extensions to Xcode's `lastKnownFileType` identifiers.
/// Xcode uses these to decide syntax highlighting, build rules, and icons.
let knownFileTypes: [String: String] = [
    "xcstrings":    "text.json.xcstrings",
    "strings":      "text.plist.strings",
    "stringsdict":  "text.plist.stringsdict",
    "swift":        "sourcecode.swift",
    "json":         "text.json",
    "mp4":          "file.mp4",
    "png":          "image.png",
    "jpg":          "image.jpeg",
    "xcassets":     "folder.assetcatalog",
    "storyboard":   "file.storyboard",
    "xib":          "file.xib",
]

/// Returns the Xcode file type string for a given filename based on its extension.
func fileType(for filename: String) -> String {
    let ext = (filename as NSString).pathExtension
    return knownFileTypes[ext] ?? "file"
}

// MARK: - Argument Parsing

/// Validate that at least the two required positional arguments are present.
guard CommandLine.arguments.count >= 3 else {
    let scriptName = (CommandLine.arguments[0] as NSString).lastPathComponent
    print("""
    Usage: \(scriptName) <path/to/Project.xcodeproj> <path/to/file> \
      [--group <GroupName>] [--target <TargetName>]

    Arguments:
      xcodeproj   Path to the .xcodeproj directory (contains project.pbxproj)
      filepath    Path to the file to add, relative to the project root
      --group     PBXGroup name to place the file in (default: parent folder name)
      --target    Target name to add the file to (default: main app target)
    """)
    exit(1)
}

let xcodeprojPath = CommandLine.arguments[1]
let filePath = CommandLine.arguments[2]

/// Parse the optional --group and --target flags from the remaining arguments.
var groupFlag: String?
var targetFlag: String?
var argIndex = 3

while argIndex < CommandLine.arguments.count {
    let arg = CommandLine.arguments[argIndex]
    switch arg {
    case "--group" where argIndex + 1 < CommandLine.arguments.count:
        groupFlag = CommandLine.arguments[argIndex + 1]
        argIndex += 2
    case "--target" where argIndex + 1 < CommandLine.arguments.count:
        targetFlag = CommandLine.arguments[argIndex + 1]
        argIndex += 2
    default:
        print("Error: Unknown argument '\(arg)'.")
        exit(1)
    }
}

// MARK: - Derive Path Components

/// Extract the filename, its parent directory, and grandparent directory from the
/// file path. These are used to locate the correct group hierarchy in the project.
///
/// Example: for "Resources/Localization/Localizable.xcstrings"
///   filename          = "Localizable.xcstrings"
///   parentDirName     = "Localization"       (used as default group name)
///   grandparentDir    = "Resources"          (the parent group to nest under)
let filename = (filePath as NSString).lastPathComponent
let parentDirName = ((filePath as NSString).deletingLastPathComponent as NSString).lastPathComponent
let grandparentDir = (((filePath as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent as NSString).lastPathComponent

/// Use the --group flag if provided, otherwise fall back to the parent directory name.
let resolvedGroupName = groupFlag ?? parentDirName

// MARK: - Load Xcode Project

/// Open the .xcodeproj using XcodeProj. This parses the entire project.pbxproj
/// into an in-memory object graph that we can manipulate safely.
let projectPath = Path(xcodeprojPath)
let xcodeproj: XcodeProj

do {
    xcodeproj = try XcodeProj(path: projectPath)
} catch {
    print("Error: Could not open Xcode project at '\(xcodeprojPath)': \(error)")
    exit(1)
}

let pbxproj = xcodeproj.pbxproj

// MARK: - Duplicate Check

/// Before making any changes, check if a PBXFileReference with the same filename
/// already exists in the project. If so, there's nothing to do.
let alreadyReferenced = pbxproj.fileReferences.contains { ref in
    ref.path == filename || ref.name == filename
}

if alreadyReferenced {
    print("'\(filename)' is already referenced in project.pbxproj — nothing to do.")
    exit(0)
}

// MARK: - Find Target

/// Locate the native target to register the file under.
/// - If --target was provided, find that specific target by name.
/// - Otherwise, auto-detect the main app target by looking for
///   productType == .application (the standard iOS/macOS app type).
let target: PBXNativeTarget

if let name = targetFlag {
    guard let found = pbxproj.nativeTargets.first(where: { $0.name == name }) else {
        print("Error: could not find target '\(name)'.")
        exit(1)
    }
    target = found
} else {
    guard let found = pbxproj.nativeTargets.first(where: { $0.productType == .application }) else {
        print("Error: could not find main app target (productType = application).")
        exit(1)
    }
    target = found
}

print("Target: \(target.name)")

// MARK: - Find Resources Build Phase

/// Every target has a PBXResourcesBuildPhase that lists files to bundle into the
/// app (images, string catalogs, JSON files, etc.). We need to add our file here
/// so it actually gets included in the final .app bundle.
guard let resourcesPhase = target.buildPhases
    .compactMap({ $0 as? PBXResourcesBuildPhase })
    .first else {
    print("Error: PBXResourcesBuildPhase not found for target '\(target.name)'.")
    exit(1)
}

// MARK: - Create PBXFileReference

/// A PBXFileReference represents a file on disk within Xcode's project model.
/// - sourceTree = .group means the path is relative to the containing group.
/// - lastKnownFileType tells Xcode how to treat the file (icon, syntax, etc.).
/// - path is just the filename — the group hierarchy handles the directory structure.
let fileReference = PBXFileReference(
    sourceTree: .group,
    lastKnownFileType: fileType(for: filename),
    path: filename
)
pbxproj.add(object: fileReference)

// MARK: - Create PBXBuildFile

/// A PBXBuildFile is the bridge between a PBXFileReference and a build phase.
/// It tells Xcode "this file participates in this build step".
let buildFile = PBXBuildFile(file: fileReference)
pbxproj.add(object: buildFile)

// MARK: - Place in Group Hierarchy

/// Xcode organizes files into PBXGroup objects that mirror the folder structure
/// in the project navigator. We need to:
///   1. Find the grandparent group (e.g., "Resources")
///   2. Find or create the child group (e.g., "Localization") under it
///   3. Add our file reference to that child group
///
/// This two-level lookup prevents the group from being created under the wrong
/// parent (e.g., under "UI" instead of "Resources"), which would cause Xcode
/// to resolve the file path incorrectly and fail to find it on disk.

/// Recursively searches for a PBXGroup whose `path` matches the given name.
/// We match on `path` (the filesystem directory name) rather than `name`
/// (the display name), because path is the reliable, stable identifier.
func findGroup(named name: String, in group: PBXGroup) -> PBXGroup? {
    if group.path == name {
        return group
    }
    for child in group.children {
        if let childGroup = child as? PBXGroup,
           let found = findGroup(named: name, in: childGroup) {
            return found
        }
    }
    return nil
}

/// Get the project's root group — the top-level node of the navigator tree.
guard let mainGroup = pbxproj.projects.first?.mainGroup else {
    print("Error: Could not find project main group.")
    exit(1)
}

/// Find the grandparent group by path (e.g., "Resources").
guard let parentGroup = findGroup(named: grandparentDir, in: mainGroup) else {
    print("Warning: parent group '\(grandparentDir)' not found in project.pbxproj.")
    print("Could not create group '\(resolvedGroupName)'. Add it manually under the correct parent.")
    exit(1)
}

/// Look for the target group (e.g., "Localization") as a direct child of the parent.
/// We only check direct children to ensure we find the group at the right level.
let existingChildGroup = parentGroup.children
    .compactMap { $0 as? PBXGroup }
    .first { $0.path == resolvedGroupName || $0.name == resolvedGroupName }

if let childGroup = existingChildGroup {
    // Group already exists under the correct parent — just add our file to it.
    childGroup.children.append(fileReference)
    print("  Added to existing group: \(resolvedGroupName) under \(grandparentDir)")
} else {
    // Group doesn't exist yet — create it as a child of the parent group.
    // The new group gets `path = resolvedGroupName` so Xcode knows which
    // directory on disk it corresponds to.
    let newGroup = PBXGroup(
        children: [fileReference],
        sourceTree: .group,
        path: resolvedGroupName
    )
    pbxproj.add(object: newGroup)
    parentGroup.children.append(newGroup)
    print("  Created group: \(resolvedGroupName) under \(grandparentDir)")
}

// MARK: - Add to Resources Build Phase

/// Register the build file in the target's Resources phase so the file
/// gets copied into the app bundle at build time.
if resourcesPhase.files != nil {
    resourcesPhase.files?.append(buildFile)
} else {
    resourcesPhase.files = [buildFile]
}
print("  Added to Resources build phase")

// MARK: - Enable SWIFT_EMIT_LOC_STRINGS

/// SWIFT_EMIT_LOC_STRINGS = YES tells the Swift compiler to emit .strings
/// metadata alongside compiled code. This is required for String Catalogs
/// (.xcstrings) to work — without it, Xcode can't extract localized strings
/// at compile time. We add it to every build configuration (Debug, Release, etc.)
/// of the target, but only if it isn't already set.
if let configList = target.buildConfigurationList {
    for config in configList.buildConfigurations {
        if config.buildSettings["SWIFT_EMIT_LOC_STRINGS"] == nil {
            config.buildSettings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
            print("  Set SWIFT_EMIT_LOC_STRINGS = YES in '\(config.name)' configuration")
        }
    }
}

// MARK: - Write Project Back to Disk

/// Serialize the entire modified project graph back to project.pbxproj.
/// XcodeProj handles all the formatting, UUID references, and section ordering
/// that the old Python regex-based approach had to do manually.
do {
    try xcodeproj.write(path: projectPath)
} catch {
    print("Error: Failed to write project: \(error)")
    exit(1)
}

print("\nDone. Added '\(filename)' to \(xcodeprojPath)/project.pbxproj")
print("  Target              : \(target.name)")
