#!/bin/sh

# Fix Qt applications
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_QUICK_CONTROLS_MOBILE=1

# Fix Firefox
export MOZ_ENABLE_WAYLAND=1
