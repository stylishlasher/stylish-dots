#!/usr/bin/env bash

action_install_mpv() { ensure_sudo || return 1; pkg_install mpv; ok "$(t mpv_installed)"; }
action_install_gsr() { ensure_sudo || return 1; pkg_install gpu-screen-recorder gpu-screen-recorder-ui || warn "$(t gsr_failed)"; }
action_install_archives() { ensure_sudo || return 1; pkg_install xarchiver tar zip unzip 7zip zstd xz-utils bzip2 || pkg_install xarchiver tar zip unzip p7zip zstd; ok "$(t archives_installed)"; }
