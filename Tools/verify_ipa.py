"""Structural checks for an unsigned physical iOS application, not runtime tests."""
import plistlib
import struct
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    assert archive.testzip() is None, 'ZIP CRC error'
    paths = archive.namelist()
    plists = [p for p in paths if p.startswith('Payload/') and p.count('/') == 2 and p.endswith('.app/Info.plist')]
    assert len(plists) == 1, f'Expected one application, got {plists}'
    info = plistlib.loads(archive.read(plists[0]))
    assert info['CFBundlePackageType'] == 'APPL'
    assert info['CFBundleSupportedPlatforms'] == ['iPhoneOS']
    assert set(info['UIDeviceFamily']) == {1, 2}
    assert info['MinimumOSVersion'] == '17.0', info['MinimumOSVersion']
    root = plists[0].rsplit('/', 1)[0]
    binary_path = root + '/' + info['CFBundleExecutable']
    binary = archive.read(binary_path)
    magic, cpu, subtype, kind, count, size, flags, reserved = struct.unpack_from('<8I', binary)
    assert magic == 0xfeedfacf, 'Expected thin 64-bit Mach-O'
    assert cpu == 0x0100000c and kind == 2, 'Expected arm64 executable'
    offset = 32
    platforms = []
    for _ in range(count):
        cmd, length = struct.unpack_from('<II', binary, offset)
        assert length >= 8 and offset + length <= len(binary)
        if cmd == 0x32:
            platforms.append(struct.unpack_from('<I', binary, offset + 8)[0])
        offset += length
    assert platforms == [2], f'Expected iOS platform, got {platforms}'
    assert not any(p.endswith('/embedded.mobileprovision') for p in paths)
    assert archive.getinfo(binary_path).external_attr >> 16 & 0o111, 'Executable mode missing'
    for name in ('Vanguard556.as3d', 'Boreas556.as3d', 'Boreas556.asmo', 'BoreasMorphBinding556.json', 'default.metallib'):
        assert any(p.startswith(root + '/') and p.endswith('/' + name) for p in paths), f'Missing resource: {name}'
    print(f'PASS: Payload, application, Info.plist, arm64, physical iOS, iOS 17.0, iPhone/iPad, bundled assets, ZIP CRC. Bundle: {info["CFBundleIdentifier"]}')
    print('Not a signature or runtime test. Physical device and Sideloadly installation remain untested.')
