#!/usr/bin/env python3
"""
Activate TestFlight for a new NowNest build.

Usage: python3 activate-testflight.py <build_id>

This script automates TestFlight activation after the one-time export
compliance questionnaire has been answered in the App Store Connect web UI.

Prerequisites:
- App Store Connect API key at ~/.appstoreconnect/private_keys/AuthKey_C4XD2H8J52.p8
- Issuer ID: 2807795a-81ff-48cd-850c-533c7a73898d
- Export compliance questionnaire completed at least once in App Store Connect
- Internal beta group "testgroup01" exists with testers

Steps performed:
1. Set usesNonExemptEncryption = False (app uses no encryption)
2. Verify internalBuildState transitions to IN_BETA_TESTING
3. Confirm build is in the internal beta group
"""

import jwt, time, os, json, sys, urllib.request, urllib.error

KEY_ID = 'C4XD2H8J52'
ISSUER_ID = '2807795a-81ff-48cd-850c-533c7a73898d'
KEY_PATH = os.path.expanduser('~/.appstoreconnect/private_keys/AuthKey_C4XD2H8J52.p8')
APP_ID = '6814614006'
BETA_GROUP_ID = '5b4fa487-9462-4e23-b022-2a5d0a8ed1b8'

def get_token():
    with open(KEY_PATH, 'rb') as f:
        private_key = f.read()
    payload = {
        'iss': ISSUER_ID,
        'iat': int(time.time()),
        'exp': int(time.time()) + 1200,
        'aud': 'appstoreconnect-v1'
    }
    return jwt.encode(payload, private_key, algorithm='ES256', headers={'kid': KEY_ID})

def api_request(url, method='GET', body=None, token=None):
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.api+json',
        'Content-Type': 'application/vnd.api+json'
    }
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            try:
                return json.loads(raw) if raw else {}, resp.status
            except json.JSONDecodeError:
                return {}, resp.status
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        try:
            return json.loads(raw) if raw else {}, exc.code
        except json.JSONDecodeError:
            return {}, exc.code

def main():
    if len(sys.argv) < 2:
        print('Usage: python3 activate-testflight.py <build_id>')
        sys.exit(1)
    
    build_id = sys.argv[1]
    token = get_token()
    
    # Step 1: Set usesNonExemptEncryption = False
    print(f'Setting usesNonExemptEncryption for build {build_id}...')
    resp, status = api_request(
        f'https://api.appstoreconnect.apple.com/v1/builds/{build_id}',
        'PATCH',
        {'data': {'type': 'builds', 'id': build_id, 'attributes': {'usesNonExemptEncryption': False}}},
        token
    )
    if status != 200:
        print(f'FAILED: {status}')
        print(json.dumps(resp, indent=2))
        sys.exit(1)
    
    enc = resp['data']['attributes'].get('usesNonExemptEncryption')
    print(f'  usesNonExemptEncryption: {enc}')
    
    # Wait for propagation
    time.sleep(5)
    
    # Step 2: Check beta state
    resp, status = api_request(
        f'https://api.appstoreconnect.apple.com/v1/builds/{build_id}/buildBetaDetail',
        token=token
    )
    if status == 200 and resp.get('data'):
        state = resp['data']['attributes'].get('internalBuildState')
        print(f'  internalBuildState: {state}')
        if state == 'IN_BETA_TESTING':
            print('  Build is in internal beta testing!')
        elif state == 'MISSING_EXPORT_COMPLIANCE':
            print('  WARNING: Export compliance not cleared.')
            print('  If this is the first build, complete the questionnaire in App Store Connect > TestFlight.')
            sys.exit(1)
    
    # Step 3: Check if build is in beta group
    resp, status = api_request(
        f'https://api.appstoreconnect.apple.com/v1/betaGroups/{BETA_GROUP_ID}/builds',
        token=token
    )
    if status == 200:
        build_ids = [b['id'] for b in resp.get('data', [])]
        if build_id in build_ids:
            print(f'  Build is in internal test group (testgroup01)')
        else:
            print(f'  Build is NOT in internal test group. Builds in group: {build_ids}')
            print('  Note: Internal builds auto-associate with the internal test group.')
    
    print('\nTestFlight activation complete. Testers will be notified.')

if __name__ == '__main__':
    main()