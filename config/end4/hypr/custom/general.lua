-- AOU B160UAN08.3 (eDP-2): 1920x1200 @ 180 Hz
hl.monitor({
    output   = "eDP-2",
    mode     = "1920x1200@180",
    position = "0x0",
    scale    = 1,
})

-- Russian layout: Alt+Shift switches us <-> ru
hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle",
    },
})
