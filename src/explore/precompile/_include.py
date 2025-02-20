

import os 
import clang.cindex as cindex
from clang.cindex import *

def collect_header(prefix) -> list[str]:
    files: list[str] = os.listdir(prefix)
    h_files: list[str] = []
    for file in files:
        if file.endswith(".h"):
            h_files.append(os.path.join(prefix, file))

    return h_files

def hmm(probe: Cursor):

    print("--- Cursor")
    print(probe.kind)
    print(probe.spelling)
    print(probe.location)

def header_probe() -> str:
    headers = collect_header("include")
    if len(headers) == 0:
        return "!!! no headers find"

    idx: Index =  cindex.Index.create()
    tu: TranslationUnit = idx.parse(headers[0])
    if tu is None:
        return "!!! filed to parse"

    probe: Cursor = tu.cursor
    nodes = probe.get_children()
    for node in nodes:
        hmm(node)

    return "+++ finished"

def main():
    result = header_probe()
    print(result)

main()