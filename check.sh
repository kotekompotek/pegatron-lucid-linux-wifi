#!/bin/sh
# Read-only check: does this machine have the GPIO27 (WMHD) problem? Run as root.
python3 -c "import struct;f=open('/dev/port','rb');f.seek(0x48c);v=struct.unpack('<I',f.read(4))[0];print('GP18(WLAN)=%d GP27(WMHD)=%d'%(v>>18&1,v>>27&1))"
echo "Affected: GP18(WLAN)=0 GP27(WMHD)=1"
rfkill list
