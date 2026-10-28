"""MSIX preparation safety tests. No Windows host or installation is simulated as PASS."""

import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

from PIL import Image

import windows_store as store


def pe(file, machine=0x8664):
    file.parent.mkdir(parents=True, exist_ok=True)
    content = bytearray(80)
    content[:2] = b"MZ"
    struct.pack_into("<I", content, 0x3C, 64)
    content[64:68] = b"PE\0\0"
    struct.pack_into("<H", content, 68, machine)
    file.write_bytes(content)


class StoreTest(unittest.TestCase):
    def test_version_reserves_store_revision(self):
        self.assertEqual(store.read_version("version: 1.2.10+5\n"), ("1.2.10+5", "1.2.10.0"))
        for value in ("0.2.3", "1.65536.0", "1.2", "1.2.3-beta"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                store.read_version("version: " + value)

    def test_identity_requires_real_values_and_separates_test_identity(self):
        with tempfile.TemporaryDirectory() as temporary:
            file = Path(temporary) / "identity.json"
            for config in ({**store.LOCAL_IDENTITY, "identity_name": ""}, store.LOCAL_IDENTITY):
                file.write_text(json.dumps(config))
                with self.assertRaises(ValueError):
                    store.read_identity(file)
            config = {**store.LOCAL_IDENTITY, "identity_name": "12345.ForestFlutterForge",
                      "publisher": "CN=01234567-1234-1234-1234-0123456789ab"}
            file.write_text(json.dumps(config))
            self.assertEqual(store.read_identity(file), config)

    def test_manifest_xml_escaping_and_desktop_entry(self):
        config = {**store.LOCAL_IDENTITY, "display_name": 'Flutter Forge & Forest "Lab"'}
        root = ET.fromstring(store.manifest(config, "1.2.10.0"))
        namespace = {"f": store.FOUNDATION, "u": store.UAP, "r": store.RESCAP}
        self.assertEqual(root.find("f:Identity", namespace).get("ProcessorArchitecture"), "x64")
        self.assertEqual(root.find("f:Applications/f:Application", namespace).get("EntryPoint"),
                         "Windows.FullTrustApplication")
        self.assertEqual(root.find("f:Applications/f:Application/u:VisualElements", namespace)
                         .get("DisplayName"), config["display_name"])
        self.assertEqual(root.find("f:Capabilities/r:Capability", namespace).get("Name"), "runFullTrust")

    def test_assets_have_manifest_dimensions(self):
        with tempfile.TemporaryDirectory() as temporary:
            assets = Path(temporary) / "Assets"
            store.write_assets(assets, store.APP / "windows/runner/resources/app_icon.ico")
            for name, size in store.ASSETS.items():
                with Image.open(assets / name) as image:
                    self.assertEqual(image.size, (size, size))
                    self.assertEqual(image.mode, "RGBA")

    def test_payload_requires_release_and_x64_and_omits_private_symbols(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            bundle, runtime, stage = (directory / name for name in ("bundle", "runtime", "stage"))
            stage.mkdir()
            for name in ("flutter_forge.exe", "flutter_windows.dll", "data/app.so"):
                pe(bundle / name)
            (bundle / "data/icudtl.dat").write_bytes(b"icu")
            (bundle / "private.pdb").write_bytes(b"private")
            for name in store.RUNTIME_REQUIRED:
                pe(runtime / name)
            store.stage_runtime(bundle, runtime, stage)
            self.assertFalse((stage / "private.pdb").exists())
            self.assertTrue((stage / "vcruntime140_1.dll").is_file())
            pe(bundle / "flutter_forge.exe", 0xAA64)
            with self.assertRaisesRegex(ValueError, "Not an x64"):
                store.stage_runtime(bundle, runtime, stage)

    def test_missing_release_payload_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            with self.assertRaisesRegex(ValueError, "Missing Flutter"):
                store.stage_runtime(directory, directory, directory)

    def test_package_failure_preserves_report_without_acceptance(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "package"
            runtime = Path(temporary) / "runtime"
            runtime.mkdir()
            with patch.object(store.platform, "system", return_value="Windows"), \
                    patch.object(store.platform, "platform", return_value="Windows-test-fixture"), \
                    patch.object(store, "sdk_tool", return_value="makeappx.exe"), \
                    patch.object(store.shutil, "which", return_value="flutter.bat"), \
                    patch.object(store, "source_evidence", return_value={}), \
                    patch.object(store.subprocess, "check_output", return_value=b"{}"), \
                    patch.object(store.subprocess, "run", side_effect=store.subprocess.CalledProcessError(1, "flutter")):
                with self.assertRaises(store.subprocess.CalledProcessError):
                    store.main(["package", "--local-test", "--vc-runtime-dir", str(runtime),
                                "--output", str(output)])
            report = json.loads((output / "result.json").read_text())
            self.assertEqual(report["package_build"], "FAIL")
            self.assertEqual(report["installation"], "NOT_RUN")
            self.assertNotIn("package", report)

    def test_preview_does_not_claim_windows_acceptance_and_never_overwrites(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "preview"
            args = ["preview", "--local-test", "--output", str(output)]
            store.main(args)
            report = json.loads((output / "result.json").read_text())
            for key in ("package_build", "installation", "wack", "store_submission"):
                self.assertEqual(report[key], "NOT_RUN")
            with self.assertRaises(FileExistsError):
                store.main(args)

    def test_non_windows_package_fails_before_writing(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(store.platform, "system", return_value="Darwin"):
            output = Path(temporary) / "package"
            with self.assertRaisesRegex(ValueError, "Windows host"):
                store.main(["package", "--local-test", "--output", str(output)])
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
