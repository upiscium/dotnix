#!/usr/bin/env sh

: "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}"
STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"
TOUCHPAD_NAME="asue120d:00-04f3:31fb-touchpad"

set_touchpad() {
    enabled="$1"
    action="$2"

    if hyprctl eval "hl.device({ name = \"$TOUCHPAD_NAME\", enabled = $enabled })"; then
        if printf '%s' "$enabled" >"$STATUS_FILE"; then
            notify-send -u normal "$action touchpad"
        else
            notify-send -u critical "Touchpad changed but state could not be saved"
            return 1
        fi
    else
        notify-send -u critical "Failed to change touchpad state"
        return 1
    fi
}

case "$(cat "$STATUS_FILE" 2>/dev/null)" in
    false) set_touchpad true "Enabling" ;;
    *) set_touchpad false "Disabling" ;;
esac
