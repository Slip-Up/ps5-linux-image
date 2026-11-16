#!/bin/sh
# HDR off on the desktop. FLAVA3 gets 10 bpc so game mode does not have to
# raise max bpc again on return (ps5-display-reset).
export KWIN_FORCE_ASSUME_HDR_SUPPORT=0
if journalctl -k -b -o cat --no-pager 2>/dev/null | grep -m1 -q 'HDMI IC Type \[FLAVA3\]'; then
    export KWIN_DRM_PREFER_COLOR_DEPTH=30
else
    export KWIN_DRM_PREFER_COLOR_DEPTH=24
fi
