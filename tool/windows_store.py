#!/usr/bin/env python3
"""Prepare MSIX inputs anywhere; build unsigned Store candidates on Windows.

No installation, certificate trust changes, upload, or release is performed.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "apps/flutter_forge"
FOUNDATION = "http://schemas.microsoft.com/appx/manifest/foundation/windows10"
UAP = "http://schemas.microsoft.com/appx/manifest/uap/windows10"
RESCAP = "http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
LOCAL_IDENTITY = {
    "identity_name": "Forest.FlutterForge.LocalTest",
    "publisher": "CN=Forest Flutter Forge Local Test",
    "publisher_display_name": "Forest",
    "display_name": "Flutter Forge by Forest (Local Test)",
}
ASSETS = {"StoreLogo.png": 50, "Square44x44Logo.png": 44,
          "Square150x150Logo.png": 150}
RUNTIME_REQUIRED = {"msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll"}


def read_version(pubspec):
    match = re.search(r"^version:\s*['\"]?(\d+\.\d+\.\d+)(?:\+(\d+))?['\"]?\s*$",
                      pubspec, re.MULTILINE)
    if not match:
        raise ValueError("Missing numeric application version in pubspec.yaml")
    parts = [int(value) for value in match[1].split(".")]
    if parts[0] == 0 or any(value > 65535 for value in parts):
        raise ValueError("MSIX version fields must fit UInt16; major must be positive")
    # The fourth field is reserved for the Store, not Flutter's build number.
    return match[1] + (f"+{match[2]}" if match[2] else ""), ".".join(map(str, parts)) + ".0"


def read_identity(file=None, local_test=False):
    value = dict(LOCAL_IDENTITY) if local_test else json.loads(file.read_text(encoding="utf-8"))
    if set(value) != set(LOCAL_IDENTITY):
        raise ValueError("Identity config must contain exactly the four example fields")
    for key, text in value.items():
        if not isinstance(text, str) or not text.strip() or text != text.strip():
            raise ValueError(f"Missing or invalid identity field: {key}")
        if any(ord(char) < 32 for char in text) or any(word in text.lower() for word in
                ("placeholder", "replace_me", "todo", "<", ">")):
            raise ValueError(f"Placeholder or control character in {key}")
    if not re.fullmatch(r"[A-Za-z0-9.-]{3,50}", value["identity_name"]):
        raise ValueError("Identity name must be 3-50 ASCII letters, digits, periods or hyphens")
    if not value["publisher"].startswith("CN="):
        raise ValueError("Publisher must be the exact Partner Center distinguished name (CN=...)")
    if not local_test and ("localtest" in value["identity_name"].lower()
                           or value["publisher"] == LOCAL_IDENTITY["publisher"]):
        raise ValueError("Local test identity cannot be used as a Store identity")
    return value


def manifest(identity, version):
    ET.register_namespace("", FOUNDATION)
    ET.register_namespace("uap", UAP)
    ET.register_namespace("rescap", RESCAP)
    def child(parent, tag, **attrs):
        return ET.SubElement(parent, f"{{{FOUNDATION}}}{tag}", attrs)
    root = ET.Element(f"{{{FOUNDATION}}}Package", {"IgnorableNamespaces": "uap rescap"})
    child(root, "Identity", Name=identity["identity_name"], Publisher=identity["publisher"],
          Version=version, ProcessorArchitecture="x64")
    properties = child(root, "Properties")
    for name, text in (("DisplayName", identity["display_name"]),
                       ("PublisherDisplayName", identity["publisher_display_name"]),
                       ("Logo", "Assets\\StoreLogo.png")):
        child(properties, name).text = text
    resources = child(root, "Resources")
    child(resources, "Resource", Language="zh-CN")
    dependencies = child(root, "Dependencies")
    child(dependencies, "TargetDeviceFamily", Name="Windows.Desktop",
          MinVersion="10.0.17763.0", MaxVersionTested="10.0.26100.0")
    applications = child(root, "Applications")
    app = child(applications, "Application", Id="FlutterForge", Executable="flutter_forge.exe",
                EntryPoint="Windows.FullTrustApplication")
    ET.SubElement(app, f"{{{UAP}}}VisualElements", {
        "DisplayName": identity["display_name"],
        "Description": "Flutter 交互式学习与实验工作台",
        "BackgroundColor": "transparent",
        "Square150x150Logo": "Assets\\Square150x150Logo.png",
        "Square44x44Logo": "Assets\\Square44x44Logo.png",
    })
    capabilities = child(root, "Capabilities")
    ET.SubElement(capabilities, f"{{{RESCAP}}}Capability", {"Name": "runFullTrust"})
    ET.indent(root)
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def write_assets(directory, icon):
    from PIL import Image, ImageOps
    directory.mkdir()
    with Image.open(icon) as source:
        source = source.convert("RGBA")
        for name, size in ASSETS.items():
            image = Image.new("RGBA", (size, size))
            inset = max(1, size // 10)
            logo = ImageOps.contain(source, (size - 2 * inset, size - 2 * inset),
                                    Image.Resampling.LANCZOS)
            image.alpha_composite(logo, ((size - logo.width) // 2, (size - logo.height) // 2))
            image.save(directory / name)


def require_x64(file):
    with file.open("rb") as stream:
        header = stream.read(64)
        if len(header) < 64 or header[:2] != b"MZ":
            raise ValueError(f"Not a Windows PE binary: {file}")
        stream.seek(struct.unpack_from("<I", header, 0x3C)[0])
        pe = stream.read(6)
    if len(pe) != 6 or pe[:4] != b"PE\0\0" or struct.unpack_from("<H", pe, 4)[0] != 0x8664:
        raise ValueError(f"Not an x64 PE binary: {file}")


def require_x64_aot_snapshot(file):
    # Flutter's WindowsAotBundle is produced by AotElfRelease, not the PE linker.
    # The embedder loads this ELF snapshot; Windows only loads the EXE/DLLs as PE.
    with file.open("rb") as stream:
        header = stream.read(64)
    if (len(header) != 64 or header[:7] != b"\x7fELF\x02\x01\x01"
            or struct.unpack_from("<HHI", header, 16) != (3, 62, 1)
            or struct.unpack_from("<H", header, 52)[0] != 64):
        raise ValueError(f"Not a 64-bit little-endian x64 AOT ELF snapshot: {file}")


def stage_runtime(bundle, runtime, stage):
    for required in ("flutter_forge.exe", "flutter_windows.dll", "data/icudtl.dat", "data/app.so"):
        if not (bundle / required).is_file():
            raise ValueError(f"Missing Flutter Release payload: {required}")
    files = sorted(bundle.rglob("*"))
    for file in files:
        if file.is_symlink():
            raise ValueError(f"Symlink in runtime payload: {file}")
        if not file.is_file() or file.suffix.lower() in (".pdb", ".lib", ".exp"):
            continue
        relative = file.relative_to(bundle)
        if relative.parts[0].lower() == "assets" or relative.name.lower() == "appxmanifest.xml":
            raise ValueError(f"Reserved MSIX input name: {relative}")
        if relative.as_posix() == "data/app.so":
            require_x64_aot_snapshot(file)
        elif file.suffix.lower() in (".exe", ".dll"):
            require_x64(file)
        target = stage / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file, target)
    dlls = {file.name.lower(): file for file in runtime.glob("*.dll")}
    if not RUNTIME_REQUIRED <= dlls.keys():
        raise ValueError("VC runtime directory must contain x64 retail Microsoft.VC*.CRT DLLs")
    for name, file in dlls.items():
        require_x64(file)
        if name.endswith("d.dll"):
            raise ValueError(f"Debug runtime is forbidden: {name}")
        target = stage / file.name
        if target.exists() and target.read_bytes() != file.read_bytes():
            raise ValueError(f"Conflicting VC runtime DLL: {name}")
        shutil.copy2(file, target)


def sdk_tool(name):
    executable = shutil.which(name)
    if executable:
        return executable
    kits = Path(os.environ.get("ProgramFiles(x86)", "C:/Program Files (x86)")) / "Windows Kits/10/bin"
    versions = sorted((p for p in kits.glob("*") if re.fullmatch(r"\d+(\.\d+){3}", p.name)),
                      key=lambda p: tuple(map(int, p.name.split("."))), reverse=True)
    for version in versions:
        candidate = version / "x64" / name
        if candidate.is_file():
            return str(candidate)
    raise ValueError(f"Install Windows SDK or put {name} on PATH")


def digest(file):
    return hashlib.sha256(file.read_bytes()).hexdigest()


def source_evidence():
    def git(*args):
        return subprocess.check_output(["git", *args], cwd=ROOT).decode("utf-8").strip()
    return {"head": git("rev-parse", "HEAD"), "status": git("status", "--porcelain"),
            "diff_sha256": hashlib.sha256(subprocess.check_output(
                ["git", "diff", "--binary", "HEAD"], cwd=ROOT)).hexdigest()}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("preview", "package"))
    identity = parser.add_mutually_exclusive_group(required=True)
    identity.add_argument("--identity-config", type=Path)
    identity.add_argument("--local-test", action="store_true")
    parser.add_argument("--output", required=True, type=Path, help="New directory; never overwritten")
    parser.add_argument("--vc-runtime-dir", type=Path, help="Matching VS x64 retail Microsoft.VC*.CRT directory")
    args = parser.parse_args(argv)
    config = read_identity(args.identity_config, args.local_test)
    app_version, package_version = read_version((APP / "pubspec.yaml").read_text(encoding="utf-8"))
    makeappx = None
    if args.mode == "package":
        if platform.system() != "Windows":
            raise ValueError("MSIX build requires a Windows host; use preview for manifest/assets only")
        if not args.vc_runtime_dir or not args.vc_runtime_dir.is_dir():
            raise ValueError("--vc-runtime-dir is required; use the runtime matching your Visual Studio compiler")
        makeappx = sdk_tool("makeappx.exe")
    args.output.mkdir(parents=True, exist_ok=False)
    stage = args.output / "payload"
    stage.mkdir()
    (stage / "AppxManifest.xml").write_bytes(manifest(config, package_version))
    write_assets(stage / "Assets", APP / "windows/runner/resources/app_icon.ico")
    report = {"schema": "flutter_forge.windows_store.v1", "mode": args.mode,
              "identity_kind": "local-test" if args.local_test else "partner-center-config",
              "identity": config, "app_version": app_version, "package_version": package_version,
              "source": source_evidence(), "host": platform.platform(),
              "package_build": "NOT_RUN", "installation": "NOT_RUN", "wack": "NOT_RUN",
              "store_submission": "NOT_RUN", "signing": "unsigned", "files": []}
    report_path = args.output / "result.json"
    try:
        if args.mode == "package":
            flutter = shutil.which("flutter")
            if not flutter:
                raise ValueError("Flutter must be on PATH")
            report["flutter_version"] = subprocess.check_output(
                [flutter, "--version", "--machine"], cwd=APP).decode("utf-8")
            # A fresh build is mandatory; no option silently packages an old binary.
            subprocess.run([flutter, "build", "windows", "--release"], cwd=APP, check=True)
            stage_runtime(APP / "build/windows/x64/runner/Release", args.vc_runtime_dir, stage)
            suffix = "local-test" if args.local_test else "store-unsigned"
            package = args.output / f"FlutterForge-{package_version}-windows-x64-{suffix}.msix"
            subprocess.run([makeappx, "pack", "/v", "/h", "SHA256", "/d", str(stage.resolve()),
                            "/p", str(package.resolve())], check=True)
            if not package.is_file() or not package.stat().st_size:
                raise ValueError("MakeAppx produced no package")
            report["package_build"] = "PASS"
            report["package"] = {"path": package.name, "sha256": digest(package)}
        report["files"] = [{"path": file.relative_to(stage).as_posix(), "sha256": digest(file)}
                           for file in sorted(stage.rglob("*")) if file.is_file()]
    except Exception as error:
        report["package_build"] = "FAIL"
        report["error"] = str(error)
        raise
    finally:
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{args.mode}: complete; installation/WACK/submission remain NOT_RUN; report: {report_path}")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f"windows_store: {error}", file=sys.stderr)
        sys.exit(1)
