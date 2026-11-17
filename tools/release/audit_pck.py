"""Inspect an unencrypted embedded Godot PCK without executing it."""
import argparse
import hashlib
import json
from pathlib import Path
import struct


def inspect(executable):
    data = executable.read_bytes()
    size, magic = struct.unpack_from("<QI", data, len(data)-12)
    assert magic == 0x43504447, "No embedded PCK footer"
    start = len(data)-12-size
    header, version, major, minor, patch, flags, base = struct.unpack_from("<6IQ",data,start)
    assert header == magic and version in (2,3,4) and not flags & 1
    base += start
    directory = start+struct.unpack_from("<Q",data,start+32)[0] if version >= 3 else start+96
    count = struct.unpack_from("<I",data,directory)[0]
    cursor = directory+4
    records=[]
    for _ in range(count):
        length=struct.unpack_from("<I",data,cursor)[0];cursor+=4
        path=data[cursor:cursor+length].decode().rstrip("\0");cursor+=length
        offset,length=struct.unpack_from("<QQ",data,cursor);cursor+=16
        digest=data[cursor:cursor+16];cursor+=16
        file_flags=struct.unpack_from("<I",data,cursor)[0];cursor+=4
        content=data[base+offset:base+offset+length]
        assert hashlib.md5(content).digest()==digest,path
        records.append({"path":path,"bytes":length,"sha256":hashlib.sha256(content).hexdigest(),"md5_verified":True})
    forbidden=[]
    for record in records:
        path=record['path'].removeprefix('res://')
        if path.startswith(('tests/','tools/','qa/','addons/','docs/','backups/','artifacts/','.agents/','.codex/')) \
            or any(x in path.lower() for x in ['progress_v1.json','opencode','videoplayback.m4a']) \
            or path.endswith(('.log','.bak','.ps1','.py','.tpz','.m4a')):
            forbidden.append(path)
    return {'exe':str(executable),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),
            'pack_version':version,'engine':[major,minor,patch],'embedded_pck_bytes':size,
            'file_count':count,'files':records,'forbidden':forbidden,'all_md5_verified':True}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('executable',type=Path)
    parser.add_argument('--report',type=Path,required=True)
    args=parser.parse_args()
    result=inspect(args.executable)
    args.report.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='files'},indent=2))
    assert not result['forbidden'],'Forbidden development/private content in pack'
