#!/bin/bash
# legendary-uninstall must leave files under ~/.config/legendary-zsh/ alone.
# That directory is user-authored territory (local.zsh, paths) and legendary
# never wrote to it, so uninstall has no claim on it.
source "$(dirname "$0")/_lib.sh"

echo "== 17: Uninstall preserves ~/.config/legendary-zsh/ user files =="

# Install
run_setup

# Create user customization files that the framework should never touch
mkdir -p "$HOME/.config/legendary-zsh"
printf '# user local.zsh\nexport LOCAL_VAR=foo\n' > "$HOME/.config/legendary-zsh/local.zsh"
printf '# user paths\n$HOME/custom/bin\n' > "$HOME/.config/legendary-zsh/paths"

# Act
run_uninstall

# Assert: user files survived, unchanged
assert_file_exists "$HOME/.config/legendary-zsh/local.zsh"
assert_file_contains "$HOME/.config/legendary-zsh/local.zsh" "LOCAL_VAR=foo"
assert_file_exists "$HOME/.config/legendary-zsh/paths"
assert_file_contains "$HOME/.config/legendary-zsh/paths" "custom/bin"

test_done
