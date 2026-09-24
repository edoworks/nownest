import importlib.util
import pathlib
import tempfile
import unittest
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
                    "included": [{"type": "apps", "id": MODULE.APP_ID}],
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
            ({"data": [{"type": "builds", "id": "build-4"}]}, 200),
        ]

    def activate(self, responses):
        with tempfile.TemporaryDirectory() as directory:
            receipt = pathlib.Path(directory) / "receipt.json"
            with mock.patch.object(MODULE, "get_token", return_value="token"), mock.patch.object(
                MODULE, "api_request", side_effect=responses
            ):
                result = MODULE.activate("build-4", "a" * 40, "owner request", "operator", receipt)
            self.assertTrue(receipt.is_file())
            return result

    def test_success_requires_exact_build_app_state_and_group(self):
        result = self.activate(self.responses())
        self.assertEqual(result["build_version"], "4")
        self.assertEqual(result["states"]["internal_group_membership"], "CONFIRMED")

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

    def test_malformed_patch_response_fails(self):
        responses = self.responses()
        responses[1] = ({}, 200)
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_missing_group_membership_fails(self):
        responses = self.responses()
        responses[3] = ({"data": []}, 200)
        with self.assertRaises(MODULE.ActivationError):
            self.activate(responses)

    def test_http_error_is_sanitized(self):
        responses = self.responses()
        responses[0] = ({"errors": [{"status": "401", "title": "Denied"}]}, 401)
        with self.assertRaisesRegex(MODULE.ActivationError, "HTTP 401"):
            self.activate(responses)


if __name__ == "__main__":
    unittest.main()
