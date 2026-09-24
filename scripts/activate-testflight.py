#!/usr/bin/env python3
"""Fail-closed activation of one processed NowNest build for internal TestFlight."""

import argparse
import datetime
import hashlib
import json
import os
import pathlib
import plistlib
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile

import jwt

KEY_ID = "C4XD2H8J52"
ISSUER_ID = "2807795a-81ff-48cd-850c-533c7a73898d"
KEY_PATH = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_C4XD2H8J52.p8")
APP_ID = "6814614006"
BETA_GROUP_ID = "5b4fa487-9462-4e23-b022-2a5d0a8ed1b8"
API_ROOT = "https://api.appstoreconnect.apple.com/v1"


class ActivationError(RuntimeError):
    pass


def get_token():
    with open(KEY_PATH, "rb") as handle:
        private_key = handle.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def api_request(path, method="GET", body=None, token=None):
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.api+json",
        "Content-Type": "application/vnd.api+json",
    }
    request = urllib.request.Request(
        f"{API_ROOT}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()
            return (json.loads(raw) if raw else {}), response.status
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            payload = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            payload = {}
        return payload, error.code


def require_response(payload, status, expected_status, label):
    if status != expected_status or not isinstance(payload, dict):
        errors = payload.get("errors", []) if isinstance(payload, dict) else []
        safe_errors = [
            {key: item.get(key) for key in ("status", "code", "title", "detail")}
            for item in errors
            if isinstance(item, dict)
        ]
        raise ActivationError(f"{label} failed with HTTP {status}: {safe_errors}")
    return payload


def sha256_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_tree(path):
    digest = hashlib.sha256()
    for item in sorted(path.rglob("*")):
        if item.is_file():
            digest.update(str(item.relative_to(path)).encode())
            digest.update(b"\0")
            digest.update(bytes.fromhex(sha256_file(item)))
    return digest.hexdigest()


def validate_bundle_metadata(metadata, expected_marketing_version, expected_build_version, label):
    expected = {
        "CFBundleIdentifier": "com.foculoom.nownest",
        "CFBundleShortVersionString": expected_marketing_version,
        "CFBundleVersion": expected_build_version,
        "ITSAppUsesNonExemptEncryption": False,
        "UIDeviceFamily": [1, 2],
    }
    observed = {key: metadata.get(key) for key in expected}
    if observed != expected:
        raise ActivationError(f"{label} metadata mismatch: expected {expected!r}, observed {observed!r}")


def inspect_artifacts(archive_path, ipa_path, expected_marketing_version, expected_build_version):
    archive_info = archive_path / "Products" / "Applications" / "NowNest.app" / "Info.plist"
    with open(archive_info, "rb") as handle:
        validate_bundle_metadata(
            plistlib.load(handle), expected_marketing_version, expected_build_version, "archive"
        )
    with zipfile.ZipFile(ipa_path) as archive:
        info_paths = [
            name for name in archive.namelist() if name == "Payload/NowNest.app/Info.plist"
        ]
        if len(info_paths) != 1:
            raise ActivationError("IPA does not contain exactly one NowNest Info.plist")
        validate_bundle_metadata(
            plistlib.loads(archive.read(info_paths[0])),
            expected_marketing_version,
            expected_build_version,
            "IPA",
        )
    return {
        "archive_sha256": sha256_tree(archive_path),
        "ipa_sha256": sha256_file(ipa_path),
    }


def verify_source_revision(source_revision):
    if not re.fullmatch(r"[0-9a-f]{40}", source_revision):
        raise ActivationError("source revision must be a full lowercase commit hash")
    repository = pathlib.Path(__file__).resolve().parents[1]
    commit = subprocess.run(
        ["git", "cat-file", "-e", f"{source_revision}^{{commit}}"],
        cwd=repository,
        capture_output=True,
        check=False,
    )
    if commit.returncode != 0:
        raise ActivationError("source revision is not a commit in this repository")
    app_diff = subprocess.run(
        [
            "git",
            "diff",
            "--quiet",
            source_revision,
            "--",
            "NowNest",
            "NowNest.xcodeproj/project.pbxproj",
            "project.yml",
        ],
        cwd=repository,
        check=False,
    )
    if app_diff.returncode != 0:
        raise ActivationError("current candidate app sources do not match the source revision")


def activate(
    build_id,
    source_revision,
    authorization_reference,
    operator,
    receipt_path,
    archive_path,
    ipa_path,
    expected_marketing_version,
    expected_build_version,
):
    receipt_path = pathlib.Path(receipt_path)
    receipt_path.unlink(missing_ok=True)
    archive_path = pathlib.Path(archive_path)
    ipa_path = pathlib.Path(ipa_path)
    verify_source_revision(source_revision)
    artifacts = inspect_artifacts(
        archive_path, ipa_path, expected_marketing_version, expected_build_version
    )
    token = get_token()
    payload, status = api_request(
        f"/builds/{build_id}?include=app,preReleaseVersion", token=token
    )
    payload = require_response(payload, status, 200, "build lookup")
    build = payload.get("data")
    if not isinstance(build, dict) or build.get("id") != build_id or build.get("type") != "builds":
        raise ActivationError("build lookup returned the wrong or malformed build")
    included_apps = [
        item.get("id")
        for item in payload.get("included", [])
        if isinstance(item, dict) and item.get("type") == "apps"
    ]
    if included_apps != [APP_ID]:
        raise ActivationError(f"build belongs to unexpected app IDs: {included_apps}")
    included_versions = [
        item.get("attributes", {}).get("version")
        for item in payload.get("included", [])
        if isinstance(item, dict) and item.get("type") == "preReleaseVersions"
    ]
    if included_versions != [expected_marketing_version]:
        raise ActivationError(f"build belongs to unexpected marketing versions: {included_versions}")
    attributes = build.get("attributes")
    if not isinstance(attributes, dict) or attributes.get("processingState") != "VALID":
        raise ActivationError(
            f"build processing state is {attributes.get('processingState') if isinstance(attributes, dict) else None!r}"
        )
    if attributes.get("version") != expected_build_version:
        raise ActivationError(
            f"build version is {attributes.get('version')!r}, expected {expected_build_version!r}"
        )

    if attributes.get("usesNonExemptEncryption") is not False:
        payload, status = api_request(
            f"/builds/{build_id}",
            "PATCH",
            {
                "data": {
                    "type": "builds",
                    "id": build_id,
                    "attributes": {"usesNonExemptEncryption": False},
                }
            },
            token,
        )
        payload = require_response(payload, status, 200, "export-compliance update")
        patched = payload.get("data")
        patched_attributes = patched.get("attributes") if isinstance(patched, dict) else None
        if (
            not isinstance(patched, dict)
            or patched.get("id") != build_id
            or not isinstance(patched_attributes, dict)
            or patched_attributes.get("usesNonExemptEncryption") is not False
        ):
            raise ActivationError("export-compliance response did not confirm the requested build")

    payload, status = api_request(f"/builds/{build_id}/buildBetaDetail", token=token)
    payload = require_response(payload, status, 200, "beta-state lookup")
    detail = payload.get("data")
    detail_attributes = detail.get("attributes") if isinstance(detail, dict) else None
    beta_state = (
        detail_attributes.get("internalBuildState")
        if isinstance(detail_attributes, dict)
        else None
    )
    if beta_state != "IN_BETA_TESTING":
        raise ActivationError(f"internal beta state is {beta_state!r}")

    payload, status = api_request(f"/betaGroups/{BETA_GROUP_ID}?include=app", token=token)
    payload = require_response(payload, status, 200, "beta-group identity lookup")
    group = payload.get("data")
    group_attributes = group.get("attributes") if isinstance(group, dict) else None
    group_apps = [
        item.get("id")
        for item in payload.get("included", [])
        if isinstance(item, dict) and item.get("type") == "apps"
    ]
    if (
        not isinstance(group, dict)
        or group.get("id") != BETA_GROUP_ID
        or group.get("type") != "betaGroups"
        or not isinstance(group_attributes, dict)
        or group_attributes.get("isInternalGroup") is not True
        or group_apps != [APP_ID]
    ):
        raise ActivationError("configured beta group identity or app relationship is invalid")

    payload, status = api_request(f"/betaGroups/{BETA_GROUP_ID}/builds?limit=200", token=token)
    payload = require_response(payload, status, 200, "beta-group lookup")
    group_builds = payload.get("data")
    if not isinstance(group_builds, list) or build_id not in {
        item.get("id") for item in group_builds if isinstance(item, dict)
    }:
        raise ActivationError("build is not in the configured internal beta group")

    receipt = {
        "schema_version": 1,
        "kind": "TESTFLIGHT_LIFECYCLE_RECEIPT",
        "recorded_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "app_id": APP_ID,
        "build_id": build_id,
        "marketing_version": expected_marketing_version,
        "build_version": attributes.get("version"),
        "candidate_source_revision": source_revision,
        "source_checkout_validation": "candidate app source paths match the recorded Git commit",
        "artifact_source_binding": "OPERATOR_ATTESTED_BUILD_SEQUENCE_NOT_EMBEDDED_IN_ARCHIVE",
        "authorization_reference": authorization_reference,
        "operator": operator,
        "artifacts": artifacts,
        "effective_bundle": {
            "bundle_id": "com.foculoom.nownest",
            "device_families": ["iPhone", "iPad"],
            "uses_non_exempt_encryption": False,
        },
        "states": {
            "processed": attributes.get("processingState"),
            "export_compliance": "NON_EXEMPT_ENCRYPTION_FALSE",
            "internal_testflight": beta_state,
            "internal_group_membership": "CONFIRMED",
        },
    }
    with open(receipt_path, "w", encoding="utf-8") as handle:
        json.dump(receipt, handle, indent=2, sort_keys=True)
        handle.write("\n")
    return receipt


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("build_id")
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--authorization-reference", required=True)
    parser.add_argument("--operator", default=os.environ.get("USER", "unknown"))
    parser.add_argument("--receipt", required=True)
    parser.add_argument("--archive-path", required=True)
    parser.add_argument("--ipa-path", required=True)
    parser.add_argument("--expected-marketing-version", required=True)
    parser.add_argument("--expected-build-version", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    try:
        receipt = activate(
            args.build_id,
            args.source_revision,
            args.authorization_reference,
            args.operator,
            args.receipt,
            args.archive_path,
            args.ipa_path,
            args.expected_marketing_version,
            args.expected_build_version,
        )
    except (ActivationError, OSError, ValueError) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        return 1
    print(json.dumps(receipt, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
