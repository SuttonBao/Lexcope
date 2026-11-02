#!/usr/bin/env python3
"""Deterministic, dependency-free Xcode project generation. Run after adding App files."""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent.parent

def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

def quoted(value):
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'

objects = []
def obj(name, body):
    objects.append(f'{uid(name)} = {{ {body} }};')

sources = sorted((root / 'App').rglob('*.swift'))
for path in sources:
    rel = path.relative_to(root).as_posix()
    obj(rel, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quoted(rel)}; sourceTree = SOURCE_ROOT;')
    obj('build:' + rel, f'isa = PBXBuildFile; fileRef = {uid(rel)};')
obj('app', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = Lexcope.app; sourceTree = BUILT_PRODUCTS_DIR;')
obj('products', f'isa = PBXGroup; children = ({uid("app")},); name = Products; sourceTree = "<group>";')
obj('group', f'isa = PBXGroup; children = ({",".join(uid(p.relative_to(root).as_posix()) for p in sources)},{uid("products")},); sourceTree = "<group>";')
obj('sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(uid("build:" + p.relative_to(root).as_posix()) for p in sources)},); runOnlyForDeploymentPostprocessing = 0;')
obj('core', 'isa = XCSwiftPackageProductDependency; productName = LexcopeCore;')
obj('coreBuild', f'isa = PBXBuildFile; productRef = {uid("core")};')
obj('frameworks', f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({uid("coreBuild")},); runOnlyForDeploymentPostprocessing = 0;')
obj('resources', 'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
obj('package', 'isa = XCLocalSwiftPackageReference; relativePath = .;')
obj('target', f'isa = PBXNativeTarget; buildConfigurationList = {uid("targetConfigs")}; buildPhases = ({uid("sources")},{uid("frameworks")},{uid("resources")},); buildRules = (); dependencies = (); name = Lexcope; packageProductDependencies = ({uid("core")},); productName = Lexcope; productReference = {uid("app")}; productType = "com.apple.product-type.application";')
for config in ('Debug', 'Release'):
    common = 'CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0;'
    common += ' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; DEBUG_INFORMATION_FORMAT = dwarf;' if config == 'Debug' else ' SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'
    if config == 'Debug': common += ' SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;'
    obj('project' + config, f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{ {common} }};')
    app = 'PRODUCT_BUNDLE_IDENTIFIER = com.suttonbao.lexcope; PRODUCT_NAME = "$(TARGET_NAME)"; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = Lexcope; INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.education"; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait"; INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; TARGETED_DEVICE_FAMILY = "1,2"; SUPPORTS_MACCATALYST = NO; MARKETING_VERSION = 1.0.0; CURRENT_PROJECT_VERSION = 1; CODE_SIGN_STYLE = Automatic;'
    obj('target' + config, f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{ {app} }};')
for kind in ('project', 'target'):
    obj(kind + 'Configs', f'isa = XCConfigurationList; buildConfigurations = ({uid(kind + "Debug")},{uid(kind + "Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
obj('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; }}; buildConfigurationList = {uid("projectConfigs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hans"; knownRegions = ("zh-Hans",en,Base,); mainGroup = {uid("group")}; packageReferences = ({uid("package")},); productRefGroup = {uid("products")}; projectDirPath = ""; projectRoot = ""; targets = ({uid("target")},);')
project = root / 'Lexcope.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(objects) + f'\n}}; rootObject = {uid("project")}; }}\n')
scheme_dir = project / 'xcshareddata/xcschemes'
scheme_dir.mkdir(parents=True, exist_ok=True)
scheme_dir.joinpath('Lexcope.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('target')}" BuildableName="Lexcope.app" BlueprintName="Lexcope" ReferencedContainer="container:Lexcope.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('target')}" BuildableName="Lexcope.app" BlueprintName="Lexcope" ReferencedContainer="container:Lexcope.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('target')}" BuildableName="Lexcope.app" BlueprintName="Lexcope" ReferencedContainer="container:Lexcope.xcodeproj"/></BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>\n''')
