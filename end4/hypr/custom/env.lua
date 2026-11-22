-- X11/Wayland cursor
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")

-- NVIDIA / Wayland (RTX 5060, nvidia-open-dkms + linux-zen)
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
