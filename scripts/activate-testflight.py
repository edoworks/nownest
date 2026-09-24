#!/usr/bin/env python3
"""Fail-closed activation of one processed NowNest build for internal TestFlight."""

import argparse
import datetime
import json
import os
import sys
import time
import urllib.error
import urllib.request

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


def activate(build_id, source_revision, authorization_reference, operator, receipt_path):
    token = get_token()
    payload, status = api_request(f"/builds/{build_id}?include=app", token=token)
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
    attributes = build.get("attributes")
    if not isinstance(attributes, dict) or attributes.get("processingState") != "VALID":
        raise ActivationError(
            f"build processing state is {attributes.get('processingState') if isinstance(attributes, dict) else None!r}"
        )

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
        "marketing_version": "0.1.0",
        "build_version": attributes.get("version"),
        "source_revision": source_revision,
        "authorization_reference": authorization_reference,
        "operator": operator,
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
        )
    except (ActivationError, OSError, ValueError) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        return 1
    print(json.dumps(receipt, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
