// Claude Enter Remap
//   Enter            -> newline
//   Shift/Alt+Enter  -> native behavior (newline)
//   Ctrl/Cmd+Enter   -> send
//   IME composition  -> never intercepted (Japanese conversion confirm stays safe)
(() => {
  "use strict";

  const FLAG = "__claudeEnterRemapSynthetic";
  const SEND_SELECTORS = [
    'button[aria-label="Send message"]',
    'button[aria-label="メッセージを送信"]',
  ].join(",");

  const isEditable = (el) =>
    el instanceof HTMLElement && (el.isContentEditable || el.tagName === "TEXTAREA");

  // Synthetic Enter keydown for the ProseMirror editor.
  // Marked with FLAG so our own listener lets it through.
  function dispatchEnter(target, shiftKey) {
    const ev = new KeyboardEvent("keydown", {
      key: "Enter",
      code: "Enter",
      keyCode: 13,
      which: 13,
      shiftKey,
      bubbles: true,
      cancelable: true,
    });
    ev[FLAG] = true;
    target.dispatchEvent(ev);
  }

  function findSendButton(from) {
    const scope = from.closest("fieldset") || from.closest("form");
    return (scope && scope.querySelector(SEND_SELECTORS)) || document.querySelector(SEND_SELECTORS);
  }

  function insertNewline(target) {
    if (target.tagName === "TEXTAREA") {
      document.execCommand("insertText", false, "\n");
    } else {
      dispatchEnter(target, true); // ProseMirror treats Shift+Enter as newline
    }
  }

  function send(target) {
    const btn = findSendButton(target);
    if (btn) {
      if (!btn.disabled) btn.click();
      return;
    }
    dispatchEnter(target, false); // fallback: plain Enter = native send
  }

  window.addEventListener(
    "keydown",
    (e) => {
      if (e[FLAG]) return;
      if (e.key !== "Enter") return;
      if (e.isComposing || e.keyCode === 229) return; // IME in progress
      if (!isEditable(e.target)) return;

      if (e.ctrlKey || e.metaKey) {
        e.preventDefault();
        e.stopImmediatePropagation();
        send(e.target);
        return;
      }

      if (e.shiftKey || e.altKey) return; // leave native newline as-is

      e.preventDefault();
      e.stopImmediatePropagation();
      insertNewline(e.target);
    },
    true // capture phase: runs before the editor's own handler
  );
})();
