#!/usr/bin/env python3
"""Generate QuickSend.xcodeproj/project.pbxproj with deterministic UUIDs.

Run from ~/workspace/quicksend-ios:
    python3 gen_project.py

Single target: QuickSend (iOS + iPadOS app, iOS 17+).
All .swift under QuickSend/ -> app target sources.
Assets.xcassets -> app target resources.
"""
import hashlib
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
APP_DIR = "QuickSend"


def uid(key: str) -> str:
    return hashlib.sha256(key.encode()).hexdigest().upper()[:24]


def collect_swift():
    files = []
    for dirpath, _dn, fns in os.walk(os.path.join(ROOT, APP_DIR)):
        for fn in sorted(fns):
            if fn.endswith(".swift"):
                rel = os.path.relpath(os.path.join(dirpath, fn), ROOT).replace(os.sep, "/")
                files.append(rel)
    return sorted(files)


class PBX:
    def __init__(self):
        self.sections = {}
        self.root_object = ""

    def add(self, section, id_, comment, body):
        self.sections.setdefault(section, []).append((id_, comment, body))

    def render(self):
        out = ["// !$*UTF8*$!", "{", "\tarchiveVersion = 1;", "\tclasses = {", "\t};",
               "\tobjectVersion = 56;", "\tobjects = {"]
        for section in ["PBXBuildFile", "PBXFileReference", "PBXFrameworksBuildPhase",
                        "PBXGroup", "PBXNativeTarget", "PBXProject",
                        "PBXResourcesBuildPhase", "PBXSourcesBuildPhase",
                        "XCBuildConfiguration", "XCConfigurationList"]:
            entries = self.sections.get(section, [])
            if not entries:
                continue
            out.append(f"\n/* Begin {section} section */")
            for id_, comment, body in sorted(entries):
                out.append(f"\t\t{id_} /* {comment} */ = {{")
                for line in body.split("\n"):
                    out.append(f"\t\t\t{line}")
                out.append("\t\t};")
            out.append(f"/* End {section} section */")
        out.append("\t};")
        out.append(f"\trootObject = {self.root_object} /* Project object */;")
        out.append("}")
        return "\n".join(out) + "\n"


def q(s):
    return f'"{s}"'


def build_settings(d):
    lines = ["buildSettings = {"]
    for k in sorted(d):
        lines.append(f"\t\t\t{k} = {d[k]};")
    lines.append("\t\t};")
    return "\n".join(lines)


def main():
    sources = collect_swift()
    print(f"swift sources: {len(sources)}")
    pbx = PBX()

    project_id = uid("project:QuickSend")
    pbx.root_object = project_id
    main_group_id = uid("group:main")
    app_group_id = uid("group:QuickSend")
    products_group_id = uid("group:Products")
    target_id = uid("target:QuickSend")
    product_id = uid("product:QuickSend.app")
    sources_id = uid("phase:QuickSend:sources")
    frameworks_id = uid("phase:QuickSend:frameworks")
    resources_id = uid("phase:QuickSend:resources")

    # ---- file refs ----
    file_refs = {}
    group_ids = {}

    def group_for(d):
        if d not in group_ids:
            group_ids[d] = uid(f"group:{d}")
        return group_ids[d]

    dirs = {APP_DIR}
    for source in sources:
        parent = os.path.dirname(source)
        while parent and parent != APP_DIR:
            dirs.add(parent)
            parent = os.path.dirname(parent)
    for d in sorted(dirs):
        group_for(d)

    # Info.plist + asset catalog refs
    static_files = [
        (f"{APP_DIR}/Info.plist", "text.plist.xml"),
        (f"{APP_DIR}/Assets.xcassets", "folder.assetcatalog"),
    ]
    for rel, ftype in static_files:
        ref = uid(f"fileref:{rel}")
        file_refs[rel] = ref
        pbx.add("PBXFileReference", ref, os.path.basename(rel),
                "isa = PBXFileReference;\nfileEncoding = 4;\n"
                f"lastKnownFileType = {ftype};\npath = {q(os.path.basename(rel))};\n"
                f"sourceTree = {q('<group>')};")

    build_files = {}
    for rel in sources:
        ref = uid(f"fileref:{rel}")
        b = uid(f"buildfile:{rel}")
        build_files[rel] = b
        file_refs[rel] = ref
        pbx.add("PBXBuildFile", b, f"{os.path.basename(rel)} in Sources",
                f"isa = PBXBuildFile;\nfileRef = {ref} /* {os.path.basename(rel)} */;")
        pbx.add("PBXFileReference", ref, os.path.basename(rel),
                "isa = PBXFileReference;\nfileEncoding = 4;\nlastKnownFileType = sourcecode.swift;\n"
                f"path = {q(os.path.basename(rel))};\nsourceTree = {q('<group>')};")

    assets_build = uid("buildfile:Assets.xcassets")
    pbx.add("PBXBuildFile", assets_build, "Assets.xcassets in Resources",
            f"isa = PBXBuildFile;\nfileRef = {file_refs[f'{APP_DIR}/Assets.xcassets']} /* Assets.xcassets */;")

    pbx.add("PBXFileReference", product_id, "QuickSend.app",
            "isa = PBXFileReference;\nexplicitFileType = wrapper.application;\n"
            f"path = {q('QuickSend.app')};\nsourceTree = BUILT_PRODUCTS_DIR;")

    # ---- groups ----
    def group_body(name, children, path=None):
        lines = ["isa = PBXGroup;", "children = ("]
        for cid, cname in sorted(children, key=lambda x: x[1].lower()):
            lines.append(f"\t\t\t{cid} /* {cname} */,")
        lines.append("\t\t);")
        if name is not None:
            lines.append(f"name = {q(name)};")
        if path is not None:
            lines.append(f"path = {q(path)};")
        lines.append("sourceTree = " + q("<group>") + ";")
        return "\n".join(lines)

    children = {d: [] for d in dirs}
    for rel in sources:
        children[os.path.dirname(rel)].append((file_refs[rel], os.path.basename(rel)))
    children[APP_DIR].append((file_refs[f"{APP_DIR}/Info.plist"], "Info.plist"))
    children[APP_DIR].append((file_refs[f"{APP_DIR}/Assets.xcassets"], "Assets.xcassets"))

    for d in sorted(dirs):
        subs = sorted({c for c in dirs if os.path.dirname(c) == d and c != d})
        kids = list(children[d])
        for s in subs:
            kids.append((group_ids[s], os.path.basename(s)))
        name = os.path.basename(d) if d != APP_DIR else "QuickSend"
        pbx.add("PBXGroup", group_ids[d], name, group_body(name, kids, os.path.basename(d)))

    pbx.add("PBXGroup", main_group_id, None,
            group_body(None, [(app_group_id, "QuickSend"), (products_group_id, "Products")]))
    pbx.add("PBXGroup", products_group_id, "Products",
            group_body("Products", [(product_id, "QuickSend.app")]))

    # ---- phases ----
    files = "\n".join(f"\t\t\t{build_files[r]} /* {os.path.basename(r)} in Sources */,"
                      for r in sources)
    pbx.add("PBXSourcesBuildPhase", sources_id, "Sources",
            "isa = PBXSourcesBuildPhase;\nbuildActionMask = 2147483647;\nfiles = (\n"
            + files + "\n\t\t);\nrunOnlyForDeploymentPostprocessing = 0;")
    pbx.add("PBXFrameworksBuildPhase", frameworks_id, "Frameworks",
            "isa = PBXFrameworksBuildPhase;\nbuildActionMask = 2147483647;\nfiles = (\n\t\t);"
            "\nrunOnlyForDeploymentPostprocessing = 0;")
    pbx.add("PBXResourcesBuildPhase", resources_id, "Resources",
            "isa = PBXResourcesBuildPhase;\nbuildActionMask = 2147483647;\nfiles = (\n"
            f"\t\t\t{assets_build} /* Assets.xcassets in Resources */,\n\t\t);"
            "\nrunOnlyForDeploymentPostprocessing = 0;")

    # ---- target ----
    pbx.add("PBXNativeTarget", target_id, "QuickSend",
            "isa = PBXNativeTarget;\nbuildConfigurationList = " + uid("cfglist:target") + " /* Build configuration list for PBXNativeTarget \"QuickSend\" */;\n"
            "buildPhases = (\n"
            f"\t\t\t{sources_id} /* Sources */,\n"
            f"\t\t\t{frameworks_id} /* Frameworks */,\n"
            f"\t\t\t{resources_id} /* Resources */,\n"
            "\t\t);\nbuildRules = (\n\t\t);\ndependencies = (\n\t\t);\n"
            f"name = QuickSend;\nproductName = \"$(TARGET_NAME)\";\n"
            f"productReference = {product_id} /* QuickSend.app */;\n"
            "productType = \"com.apple.product-type.application\";")

    # ---- project ----
    pbx.add("PBXProject", project_id, "Project object",
            "isa = PBXProject;\nbuildConfigurationList = " + uid("cfglist:project") + " /* Build configuration list for PBXProject \"QuickSend\" */;\n"
            "compatibilityVersion = \"Xcode 15.0\";\ndevelopmentRegion = en;\n"
            "hasScannedForEncodings = 0;\nknownRegions = (\n\t\t\ten,\n\t\t);\n"
            f"mainGroup = {main_group_id};\n"
            f"productRefGroup = {products_group_id} /* Products */;\n"
            "projectDirPath = \"\";\nprojectRoot = \"\";\n"
            "targets = (\n"
            f"\t\t\t{target_id} /* QuickSend */,\n\t\t);")

    # ---- configurations ----
    base = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "COPY_PHASE_STRIP": "NO",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "SDKROOT": "iphoneos",
        "SUPPORTED_PLATFORMS": q("iphoneos iphonesimulator"),
        "SUPPORTS_MACCATALYST": "NO",
        "ONLY_ACTIVE_ARCH": "YES",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": q("1,2"),
    }

    def app_cfg(debug):
        s = dict(base)
        s.update({
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "ENABLE_PREVIEWS": "YES",
            "INFOPLIST_FILE": q("QuickSend/Info.plist"),
            "INFOPLIST_KEY_CFBundleDisplayName": "QuickSend",
            "INFOPLIST_KEY_LSRequiresIPhoneOS": "YES",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": q("UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"),
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": q("UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"),
            "LD_RUNPATH_SEARCH_PATHS": q("$(inherited) @executable_path/Frameworks"),
            "MARKETING_VERSION": "1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.quicksend.app",
            "PRODUCT_NAME": q("$(TARGET_NAME)"),
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "SWIFT_STRICT_CONCURRENCY": "complete",
        })
        if debug:
            s.update({
                "DEBUG_INFORMATION_FORMAT": "dwarf",
                "ENABLE_TESTABILITY": "YES",
                "GCC_DYNAMIC_NO_PIC": "NO",
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
                "SWIFT_OPTIMIZATION_LEVEL": q("-Onone"),
            })
        else:
            s.update({
                "DEBUG_INFORMATION_FORMAT": q("dwarf-with-dsym"),
                "ENABLE_NS_ASSERTIONS": "NO",
                "SWIFT_COMPILATION_MODE": "wholemodule",
                "SWIFT_OPTIMIZATION_LEVEL": q("-O"),
            })
        return s

    proj_cfg = dict(base)
    proj_cfg.update({"CODE_SIGN_STYLE": "Automatic"})

    for cfg_id, name, settings in [
        (uid("cfg:project:debug"), "Debug", proj_cfg),
        (uid("cfg:project:release"), "Release", proj_cfg),
        (uid("cfg:target:debug"), "Debug", app_cfg(True)),
        (uid("cfg:target:release"), "Release", app_cfg(False)),
    ]:
        pbx.add("XCBuildConfiguration", cfg_id, name,
                f"isa = XCBuildConfiguration;\n{build_settings(settings)}\nname = {name};")

    for list_id, comment, cfgs in [
        (uid("cfglist:project"), 'Build configuration list for PBXProject "QuickSend"',
         [(uid("cfg:project:debug"), "Debug"), (uid("cfg:project:release"), "Release")]),
        (uid("cfglist:target"), 'Build configuration list for PBXNativeTarget "QuickSend"',
         [(uid("cfg:target:debug"), "Debug"), (uid("cfg:target:release"), "Release")]),
    ]:
        body = ("isa = XCConfigurationList;\nbuildConfigurations = (\n"
                + "".join(f"\t\t\t{c} /* {n} */,\n" for c, n in cfgs)
                + "\t\t);\ndefaultConfigurationIsVisible = 0;\ndefaultConfigurationName = Release;")
        pbx.add("XCConfigurationList", list_id, comment, body)

    out_dir = os.path.join(ROOT, "QuickSend.xcodeproj")
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "project.pbxproj"), "w") as f:
        f.write(pbx.render())
    print("wrote QuickSend.xcodeproj/project.pbxproj")


if __name__ == "__main__":
    main()
