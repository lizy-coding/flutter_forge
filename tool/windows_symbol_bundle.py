"""Collect private runner/plugin symbols; verify PE RSDS versus PDB GUID/age.

Uses only Python's standard library. Does not modify an installation or upload symbols.
"""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path
import shutil
import struct
import subprocess
import uuid


def u32(data, offset):
    return struct.unpack_from('<I', data, offset)[0]


def pe_identity(data):
    if data[:2] != b'MZ':
        raise ValueError('Not a PE image')
    pe = u32(data, 60)
    if data[pe:pe+4] != b'PE\0\0':
        raise ValueError('Missing PE signature')
    sections, optional_size = struct.unpack_from('<H12xH', data, pe+6)
    optional = pe+24
    magic = struct.unpack_from('<H', data, optional)[0]
    directory = optional + (112 if magic == 0x20b else 96 if magic == 0x10b else 0)
    if directory == optional:
        raise ValueError('Unsupported optional header')
    debug_rva, size = struct.unpack_from('<II', data, directory+6*8)
    def file_offset(rva):
        for i in range(sections):
            entry = optional+optional_size+i*40
            virtual_size, address, raw_size, raw = struct.unpack_from('<IIII', data, entry+8)
            if address <= rva < address+max(virtual_size, raw_size):
                return raw+rva-address
        raise ValueError('Unmapped debug RVA')
    debug = file_offset(debug_rva)
    for entry in range(debug, debug+size, 28):
        if u32(data, entry+12) == 2:
            length, raw = u32(data, entry+16), u32(data, entry+24)
            record = data[raw:raw+length]
            if record[:4] == b'RSDS':
                return {'guid': str(uuid.UUID(bytes_le=record[4:20])), 'age': u32(record,20),
                        'pdb': record[24:].split(b'\0')[0].decode('utf-8', errors='replace').replace('\\','/').split('/')[-1]}
    raise ValueError('No RSDS CodeView identity in image')


def pdb_identity(data):
    if not data.startswith(b'Microsoft C/C++ MSF 7.00\r\n\x1aDS\0\0\0'):
        raise ValueError('Unsupported PDB; MSF 7 required')
    block_size, directory_size, block_map = u32(data,32), u32(data,44), u32(data,52)
    if block_size not in (512,1024,2048,4096,8192,16384,32768):
        raise ValueError('Invalid PDB block size')
    directory_blocks = [u32(data,block_map*block_size+i*4) for i in range(math.ceil(directory_size/block_size))]
    directory = b''.join(data[i*block_size:(i+1)*block_size] for i in directory_blocks)[:directory_size]
    count = u32(directory,0)
    sizes = [u32(directory,4+i*4) for i in range(count)]
    offset = 4+count*4
    for index, size in enumerate(sizes):
        blocks = 0 if size == 0xffffffff else math.ceil(size/block_size)
        indices = [u32(directory,offset+i*4) for i in range(blocks)]
        offset += blocks*4
        if index == 1:
            stream = b''.join(data[i*block_size:(i+1)*block_size] for i in indices)[:size]
            return {'guid': str(uuid.UUID(bytes_le=stream[12:28])), 'age': u32(stream,8)}
    raise ValueError('No PDB info stream')


def matched(image, pdb):
    pe, symbols = pe_identity(image), pdb_identity(pdb)
    if any(pe[key] != symbols[key] for key in ('guid','age')):
        raise ValueError('PE/PDB GUID or age mismatch')
    return pe


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True, help='apps/flutter_forge/build/windows/x64')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    files = []
    for name in ['flutter_forge.exe','desktop_multi_window_plugin.dll','usb_network_bridge.dll']:
        image = args.build/'runner'/'Release'/name
        identity = pe_identity(image.read_bytes())
        pdb = args.build/'private-symbols'/'Release'/identity['pdb']
        matched(image.read_bytes(), pdb.read_bytes())
        for source in (image,pdb):
            shutil.copy2(source,args.output/source.name)
            files.append({'name': source.name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(), **identity})
    root = Path(__file__).resolve().parent.parent
    def command(*cmd):
        return subprocess.check_output(cmd, cwd=root, text=True, stderr=subprocess.STDOUT).strip()
    manifest = {'schema': 'forge.private-windows-symbols.v1', 'files': files,
                'kind': 'validation-identity-not-a-published-release',
                'sourceSha': command('git','rev-parse','HEAD'),
                'sourceStatus': command('git','status','--porcelain'),
                'flutter': json.loads(command('flutter','--version','--machine')),
                'cmakeCacheSha256': hashlib.sha256((args.build/'CMakeCache.txt').read_bytes()).hexdigest()}
    manifest['appVersion'] = re.search(r'^version:\s*(\S+)',
        (root/'apps/flutter_forge/pubspec.yaml').read_text(), re.M).group(1)
    engine = args.build/'runner'/'Release'/'flutter_windows.dll'
    manifest['engineSha256'] = hashlib.sha256(engine.read_bytes()).hexdigest()
    # Preserve measured generator/compiler identity, not only a cache digest.
    manifest['cmakeToolchain'] = [line for line in (args.build/'CMakeCache.txt').read_text(errors='replace').splitlines()
        if line.startswith(('CMAKE_CXX_COMPILER:', 'CMAKE_GENERATOR:', 'CMAKE_VS_PLATFORM_TOOLSET:', 'CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION:'))]
    (args.output/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print(json.dumps({'status':'PASS','output':str(args.output),'matchedPairs':3}))


if __name__ == '__main__':
    main()
