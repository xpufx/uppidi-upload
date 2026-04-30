#!/usr/bin/env python3
import subprocess

proc = subprocess.Popen(
    ['adb', 'pair', '10.20.30.66:36071'],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

stdout, stderr = proc.communicate(input='976811\n', timeout=30)
print("STDOUT:", stdout)
print("STDERR:", stderr)