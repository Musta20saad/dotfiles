#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
pkill -x autotiling
exec autotiling
