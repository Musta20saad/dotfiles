#!/usr/bin/env python3
import i3ipc

N = 4  # how many workspace numbers to always show

i3 = i3ipc.Connection()

def render(*_):
    ws = {w.num: w for w in i3.get_workspaces()}
    out = []
    for n in range(1, N + 1):
        w = ws.get(n)
        if w and w.urgent:
            fmt = "%{F#F87171}"
        elif w and w.focused:
            fmt = "%{B#267DD3FC}%{F#7DD3FC}%{u#7DD3FC}%{+u}"
        elif w:
            fmt = "%{F#E6F1FF}"
        else:
            fmt = "%{F#7C93AD}"
        out.append("%{A1:i3-msg workspace number " + str(n) + ":}" + fmt + "  " + str(n) + "  %{-u}%{B-}%{F-}%{A}")
    print("".join(out), flush=True)

render()
i3.on("workspace", render)
i3.on("window", render)
i3.main()
