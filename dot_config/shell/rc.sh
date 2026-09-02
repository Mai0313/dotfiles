# Shared by ~/.zshrc and ~/.bashrc, sourced from the end of both. The single
# copy of the aliases and environment they have in common. Keep it POSIX sh:
# no bash-only or zsh-only syntax, since both shells source this same file.

alias cc='claude'
alias cop='copilot'
alias cod='codex'
alias cu='chezmoi update --refresh-externals=always --force'

# Environment-specific settings, gated at runtime via FQDN.
# Work patterns mirror is_work in .chezmoi.toml.tmpl; cloudtop/roam split is runtime-only.
__fqdn=$(hostname -f 2>/dev/null || hostname)
case "$__fqdn" in
  *.c.googlers.com|*.corp.google.com|*.roam.internal)
    alias sshping='/google/src/files/head/depot/google3/experimental/users/jdpaul/bin/sshping'
    # Work (Cloudtop + Roam): ADB vendor keys, cloned by the adb-keys/security external.
    export ADB_VENDOR_KEYS="$HOME/adb-keys/security/adb"
    # adb server only reads ADB_VENDOR_KEYS at startup, so it has to be restarted.
    alias fixadb='export ADB_VENDOR_KEYS="$HOME/adb-keys/security/adb"; adb kill-server; adb devices'
    # ~/.local/bin/list_devices, a local adb/fastboot wrapper. Do not alias over
    # it: the flashstation original lives on binfs and can go quiet for minutes
    # while it fetches. Call that one directly for marketing names or its log.
    alias listd='list_devices'
    # https://yaqs.corp.google.com/eng/q/2346264355185623040
    export CORP_SSH_HELPER_OVERRIDES="relay=sup-ssh-relay.corp.google.com"
    ;;
esac
case "$__fqdn" in
  *.c.googlers.com)
    # Cloudtop VM only, not the corp desktop.
    # For getting 7 days auth, we can use these commands from b/540327136
    # `gcert --lifetime=168h --nocorpssh --noprodssh && gcert --noloas2 --reuse_sso_cookie`
    # `rw <hostname> --remote_gcert_args="--lifetime=168h --nocorpssh --noprodssh"`
    export AUTH_REMOTE_GCERT_ARGS="--lifetime=168h --nocorpssh --noprodssh"
    ;;
esac
case "$__fqdn" in
  *.roam.internal)
    # Roam-only aliases.
    alias agy='/usr/local/bin/jetski'
    alias jetski-cli='/usr/local/bin/jetski'
    ;;
esac
case "$__fqdn" in
  *.c.googlers.com|*.corp.google.com)
    # Cloudtop / Workstation Only aliases.
    source /etc/bash_completion.d/g4d
    source /etc/bash_completion.d/cogd
    # Device Cloud: adds dc_* tools to PATH, plus dc_envsetup / dc_tab_completion.
    source /google/bin/releases/si-sw-eng-prod-team/dc_checkout/dc_setup.sh
    # Dhub: go/dhub-host
    # We install dhub from gcloud instead; keep this line for an example only.
    # source /google/bin/releases/gchips-dta-tools-team/launcher/envsetup.sh
    alias gemini='/google/bin/releases/gemini-cli/tools/gemini'
    alias agy='/google/bin/releases/jetski-devs/tools/cli'
    alias jetski='/google/bin/releases/jetski-devs/tools/cli'
    alias jetski-cli='/google/bin/releases/jetski-devs/tools/cli'
    alias flash='/google/bin/releases/android/flashstation/cl_flashstation'
    alias recovery='/google/bin/releases/android/flashstation/cl_rom_recovery'
    alias cl_flashstation='/google/bin/releases/android/flashstation/cl_flashstation'
    alias cl_rom_recovery='/google/bin/releases/android/flashstation/cl_rom_recovery'
    alias fetch_artifact='/google/data/ro/projects/android/fetch_artifact'
    alias duckie='/google/bin/releases/gemini-agents-duckie/duckie_cli'
    alias issues='/google/bin/releases/issues-cli/issues'
    alias buganizer='/google/bin/releases/issues-cli/issues'
    # go/buganizer-admin
    alias buganizer_admin='/google/bin/releases/buganizer/public/buganizer_admin'
    alias gbrowser='/google/bin/releases/gemini-agents-gbrowser/gbrowser'
    alias gobcs='/google/bin/releases/gemini-agents-gob-code-search/gob_code_search_tool'
    ;;
esac
unset __fqdn
