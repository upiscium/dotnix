{ ... }: {
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    zsh-abbr = {
      enable = true;
      abbreviations = {
        grep = "rg";
        ip = "ip -a";
        ls = "ls --color=auto";
        ll = "ls --color=auto -l";
        la = "ls --color=auto -a";
        "-" = "cd -";
        t = "tmux new -s";
        tl = "tmux ls";
        tt = "tmux a -t";
        tr = "tmux rename -t";
      };
    };

    history = {
      size = 10000;
    };

    initContent = ''
      zstyle ':completion:*' completer _complete _correct
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      autoload -U compinit && compinit
      eval "$(direnv hook zsh)"

      function WOL() {
        echo -ne "\033[1;32mWake up '$1'? (Y/n)\033[0m";
        read answer;
        if [ "$answer" = "n" ]; then
          echo "Skipped wake up.";
        else
          local mac=$(arp -a | grep "$1" | awk '{print $4}');
          if [ -z "$mac" ]; then
            echo "Failed to get mac of '$1'.";
          else
            wol -i $1 $mac;
          fi
        fi
      }

      # function WithNVIDIA() {
      #   echo -ne "\033[1;32mRun '$1' with NVIDIA? (Y/n)\033[0m";
      #   read answer;
      #   if [ "$answer" = "n" ]; then
      #     echo "Skipped running with NVIDIA.";
      #   else
      #     export __NV_PRIME_RENDER_OFFLOAD=1;
      #     export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0;
      #     export __GLX_VENDOR_LIBRARY_NAME=nvidia;
      #     export __VK_LAYER_NV_optimus=NVIDIA_only;
      #     exec $1;
      #   fi
      # }

      if [ -n "$\{commands[fzf-share]\}" ]; then
        source "$(fzf-share)/key-bindings.zsh"
        source "$(fzf-share)/completion.zsh"
      fi

      export ZSH_CUSTOM="$HOME/.config/.zsh";
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH";

      if [ -d ~/secrets/private-key ]; then
        ssh-add ~/secrets/private-key/* > /dev/null;
      fi

      # Set the default directory for grim screenshots
      export GRIM_DEFAULT_DIR="$HOME/Pictures/screenshots";

      # Completion for git worktree
      _git-wb() {
        if type _git-checkout >/dev/null 2>&1; then
          _git-checkout "$@"
        fi
      }
      _git-wd() {
        if type _git-branch >/dev/null 2>&1; then
          _git-branch "$@"
        fi
      }
      _git-aa() {
        if type _git-add >/dev/null 2>&1; then
          _git-add "$@"
        fi
      }
      ssht() {
        TERM=xterm-256color ssh "$@"
      }
    '';
  };
}
