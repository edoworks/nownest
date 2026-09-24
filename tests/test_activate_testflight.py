import importlib.util
import pathlib
import plistlib
import tempfile
import unittest
import zipfile
from unittest import mock


SCRIPT = pathlib.Path(__file__).parents[1] / "scripts" / "activate-testflight.py"
SPEC = importlib.util.spec_from_file_location("activate_testflight", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ActivateTestFlightTests(unittest.TestCase):
    def responses(self):
        return [
            (
                {
                    "data": {
                        "type": "builds",
                        "id": "build-4",
                        "attributes": {"processingState": "VALID", "version": "4"},
                    },
                    "included": [
                        {"type": "apps", "id": MODULE.APP_ID},
                        {"type": "preReleaseVersions", "attributes": {"version": "0.1.0"}},
                    ],
                },
                200,
            ),
            (
                {
                    "data": {
                        "type": "builds",
                        "id": "build-4",
                        "attributes": {"usesNonExemptEncryption": False},
                    }
                },
                200,
            ),
            (
                {"data": {"attributes": {"internalBuildState": "IN_BETA_TESTING"}}},
                200,
            ),
            (
                {
                    "data": {
                        "type": "betaGroups",
                        "id": MODULE.BETA_GROUP_ID,
                        "attributes": {"isInternalGroup": True},
                    },
                    "included": [{"type": "apps", "id": MODULE.APP_ID}],
                },
                200,
            ),
            ({"data": [{"type": "builds", "id": "build-4"}]}, 200),
        ]

    def activate(self, responses):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            receipt = root / "receipt.json"
            archive = root / "NowNest.xcarchive"
            archive_info = archive / "Products" / "Applications" / "NowNest.app" / "Info.plist"
            archive_info.parent.mkdir(parents=True)
            metadata = {
                "CFBundleIdentifier": "com.foculoom.nownest",
                "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "4",
                "ITSAppUsesNonExemptEncryption": False,
                "UIDeviceFamily": [1, 2],
            }
            with open(archive_info, "wb") as handle:
                plistlib.dump(metadata, handle)
            ipa = root / "NowNest.ipa"
            with zipfile.ZipFile(ipa, "w") as bundle:
                bundle.writestr("Payload/NowNest.app/Info.plist", plistlib.dumps(metadata))
            with mock.patch.object(MODULE, "get_token", return_value="token"), mock.patch.object(
                MODULE, "api_request", side_effect=responses
            ), mock.patch.object(MODULE, "verify_source_revision"):
                result = MODULE.activate(
                    "build-4",
                    "a" * 40,
                    "owner request",
                    "operator",
                    receipt,
                    archive,
                    ipa,
                    "0.1.0",
                    "4",
                )
            self.assertTrue(receipt.is_file())
            return result

    def test_success_requires_exact_build_app_state_and_group(self):
        result = self.activate(self.responses())
        self.assertEqual(result["build_version"], "4")
        self.assertRegex(result["artifacts"]["archive_sha256"], r"^[0-9a-f]{64}$")
        self.assertEqual(result["states"]["internal_group_membership"], "CONFIRMED")

    def test_already_declared_export_compliance_skips_patch(self):
        responses = self.responses()
        responses[0][0]["data"]["attributes"]["usesNonExemptEncryption"] = False
        responses.pop(1)
        result = self.activate(responses)
        self.assertEqual(result["states"]["export_compliance"], "NON_EXEMPT_ENCRYPTION_FALSE")

    def test_wrong_app_fails(self):
        responses = self.responses()
        responses[0][0]["included"][0]["id"] = "wrong-app"
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_processing_state_fails_closed(self):
        responses = self.responses()
        responses[0][0]["data"]["attributes"]["processingState"] = "PROCESSING"
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_wrong_build_version_fails(self):
        responses = self.responses()
        responses[0][0]["data"]["attributes"]["version"] = "3"
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_wrong_marketing_version_fails(self):
        responses = self.responses()
        responses[0][0]["included"][1]["attributes"]["version"] = "0.0.9"
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_malformed_patch_response_fails(self):
        responses = self.responses()
        responses[1] = ({}, 200)
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_missing_group_membership_fails(self):
        responses = self.responses()
        responses[4] = ({"data": []}, 200)
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_wrong_group_app_fails(self):
        responses = self.responses()
        responses[3][0]["included"][0]["id"] = "wrong-app"
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_non_internal_group_fails(self):
        responses = self.responses()
        responses[3][0]["data"]["attributes"]["isInternalGroup"] = False
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_invalid_bundle_metadata_fails(self):
        with self.assertRaises(MODULE.ActivationError):
            MODULE.validate_bundle_metadata(
                {
                    "CFBundleIdentifier": "wrong.bundle",
                    "CFBundleShortVersionString": "0.1.0",
                    "CFBundleVersion": "4",
                    "ITSAppUsesNonExemptEncryption": False,
                    "UIDeviceFamily": [1, 2],
                },
                "0.1.0",
                "4",
                "archive",
            )

    def test_invalid_source_revision_fails(self):
        with self.assertRaises(MODULE.ActivationError):
            MODULE.verify_source_revision("not-a-commit")

    def test_failure_removes_stale_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = pathlib.Path(directory) / "receipt.json"
            receipt.write_text("stale", encoding="utf-8")
            with mock.patch.object(MODULE, "verify_source_revision"), mock.patch.object(
                MODULE, "inspect_artifacts", side_effect=MODULE.ActivationError("invalid artifact")
            ):
                with self.assertRaises(MODULE.ActivationError):
                    MODULE.activate(
                        "build-4",
                        "a" * 40,
                        "owner request",
                        "operator",
                        receipt,
                        pathlib.Path(directory) / "archive",
                        pathlib.Path(directory) / "app.ipa",
                        "0.1.0",
                        "4",
                    )
            self.assertFalse(receipt.exists())

    def test_http_error_is_sanitized(self):
        responses = self.responses()
        responses[0] = ({"errors": [{"status": "401", "title": "Denied"}]}, 401)
        with self.assertRaisesRegex(MODULE.ActivationError, "HTTP 401"):
            self.activate(responses)


if __name__ == "__main__":
    unittest.main()
