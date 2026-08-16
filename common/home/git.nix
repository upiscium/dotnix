{ pkgs, ... }:
let
  git-wb = pkgs.writeShellApplication {
    name = "git-wb";
    runtimeInputs = [ pkgs.git pkgs.gnugrep pkgs.coreutils ];
    text = ''
      # 引数がない場合はヘルプを表示
      if [ "$#" -eq 0 ]; then
        echo "Usage: git wb <new-branch-name> [start-point]"
        exit 1
      fi

      BRANCH="$1"
      START_POINT="''${2:-}" # 2つ目の引数（派生元）があれば取得

      # Gitリポジトリのルートを取得
      REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo "Error: Not a git repository"
        exit 1
      }

      # ワークツリーの作成先を定義（例: リポジトリ直下の .worktrees/ブランチ名）
      WORKTREE_DIR="$REPO_ROOT/.worktrees/$BRANCH"

      # .worktrees ディレクトリを作成し、Git の管理から除外 (.git/info/exclude に追記)
      mkdir -p "$REPO_ROOT/.worktrees"
      EXCLUDE_FILE="$REPO_ROOT/.git/info/exclude"
      if [ -f "$EXCLUDE_FILE" ]; then
        grep -q "^.worktrees$" "$EXCLUDE_FILE" || echo ".worktrees" >> "$EXCLUDE_FILE"
      fi

      # worktree と branch を同時に作成
      if [ -n "$START_POINT" ]; then
        git worktree add -b "$BRANCH" "$WORKTREE_DIR" "$START_POINT"
      else
        git worktree add -b "$BRANCH" "$WORKTREE_DIR"
      fi
      
      echo -e "\n✅ ワークツリーを作成しました: $WORKTREE_DIR"

      git switch "$BRANCH" || {
        echo -e "\nError: ブランチ '$BRANCH' への切り替えに失敗しました。"
        exit 1
      }
    '';
  };
  git-wd = pkgs.writeShellApplication {
    name = "git-wd";
    runtimeInputs = [ pkgs.git pkgs.gnugrep pkgs.gnused ];
    text = ''
      if [ "$#" -eq 0 ]; then
        echo "Usage: git wd <branch-name>"
        exit 1
      fi

      BRANCH="$1"
      
      # Gitの内部情報(--porcelain)から、該当ブランチのワークツリーパスを正確に取得する
      WORKTREE_PATH=$(git worktree list --porcelain | grep -B 2 "branch refs/heads/$BRANCH$" | grep "^worktree " | sed 's/^worktree //')

      if [ -n "$WORKTREE_PATH" ]; then
        # 削除対象のワークツリーに現在自分がいる場合はエラーにして防ぐ
        if [[ "$(pwd)" == "$WORKTREE_PATH"* ]]; then
          echo "Error: 現在削除対象のワークツリー内にいます。"
          echo "メインリポジトリ等に移動(cd)してから再度実行してください。"
          exit 1
        fi
        
        echo "🗑️  ワークツリーを削除しています: $WORKTREE_PATH"
        # 未コミットのファイルがある場合はGitが安全のためにここで処理を停止(Fail)してくれます
        git worktree remove "$WORKTREE_PATH" || {
          echo -e "\nError: ワークツリーの削除を中断しました。未コミットの変更がある可能性があります。"
          exit 1
        }
      else
        echo "Note: ブランチ '$BRANCH' に紐づくワークツリーが見つかりませんでした。"
      fi

      echo "🗑️  ブランチを削除しています: $BRANCH"
      # 未マージのコミットがある場合はGitが安全のためにここで処理を停止(Fail)してくれます
      git branch -d "$BRANCH" || {
        echo -e "\nWarning: ブランチ '$BRANCH' の削除に失敗しました（未マージのコミットがある可能性があります）。"
        echo "強制削除する場合は手動で 'git branch -D $BRANCH' を実行してください。"
        exit 1
      }

      echo -e "\n🧹 ワークツリーとブランチのクリーンアップが完了しました！"

      git worktree prune || {
        echo -e "\nWarning: ワークツリーの prune に失敗しました。手動で 'git worktree prune' を実行して不要なワークツリーをクリーンアップしてください。"
        exit 1
      }
    '';
  };
  git-aa = pkgs.writeShellApplication {
    name = "git-aa";
    runtimeInputs = [ pkgs.git pkgs.findutils pkgs.coreutils ];
    text = ''
      printf "\033[1;32mAdd all files to git repository.\033[0m\n"
      printf "\033[1;32mChecking for files over 100M...\033[0m\n"

      # Gitリポジトリかどうかの確認
      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf "\033[1;31mError: Not a git repository.\033[0m\n"
        exit 1
      fi

      # 1. .gitignore の有無チェック
      if [ ! -f .gitignore ]; then
        printf "\033[1;31mNo .gitignore file found.\033[0m\n"
        printf "\033[1;32mProceed? (y/N) \033[0m"
        read -r answer
        if [[ "$answer" != [yY]* ]]; then
          exit 1
        fi
        printf "\033[1;32mSkipped .gitignore check.\033[0m\n"
      fi

      # 2. .gitディレクトリを除外し、100MB以上のファイルを検索
      LARGE_FILES=$(find . -type f -size +100M -not -path '*/.git/*' 2>/dev/null || true)
      
      TARGET_FILES=""
      
      if [ -n "$LARGE_FILES" ]; then
        # 3. 見つかったファイルが .gitignore で既に除外されているか正確に判定
        for file in $LARGE_FILES; do
          if ! git check-ignore -q "$file"; then
            # 除外されていない危険な巨大ファイルだけをリストアップ
            TARGET_FILES="$TARGET_FILES $file"
          fi
        done
      fi

      # 4. 危険なファイルがあった場合の処理
      if [ -n "$TARGET_FILES" ]; then
        printf "\033[1;31mOver 100M files detected (not ignored):\033[0m\n"
        for file in $TARGET_FILES; do
          printf "\033[1;31m  %s\033[0m\n" "$file"
        done
        
        printf "\033[1;32mAdd the files to .gitignore file? (y/N) \033[0m"
        read -r answer
        if [[ "$answer" == [yY]* ]]; then
          for file in $TARGET_FILES; do
            # ./ プレフィックスを取り除いて .gitignore に追記
            clean_name="''${file#./}"
            echo "$clean_name" >> .gitignore
          done
          git add --all
          printf "\033[1;32mAdded files to .gitignore and ran git add --all.\033[0m\n"
        else
          printf "\033[31mPlease remove or ignore the files and try again.\033[0m\n"
          exit 1
        fi
      else
        # 危険なファイルがない、または全てignore済みの場合はそのまま実行
        git add --all
        printf "\033[1;32mDone.\033[0m\n"
      fi
    '';
  };
in
{
  home.packages = with pkgs; [
    tig
    git-wb
    git-wd
    git-aa
  ];

  programs.zsh.zsh-abbr.abbreviations = {
    "g a" = "git add";
    "g aa" = "git aa";
    "g b" = "git branch -a";
    "g bd" = "git branch -D";
    "g rbd" = "git push origin --delete";
    "g c" = "git commit -m";
    "g cc" = "git rm -r --cached";
    "g l" = "git fetch -p && git pull";
    "g m" = "git merge";
    "g p" = "git push && git worktree prune";
    "g r" = "git reset --soft";
    "g rh" = "git reset --hard";
    "g s" = "git status";
    "g t" = "git tag";
    "g w" = "git switch";
    "g wc" = "git switch -c";
    "g wt" = "git worktree";
    "g wb" = "git wb";
    "g wd" = "git wd";
    "g wr" = "git worktree repair";
    "g wk" = "git worktree lock";
    "g wl" = "git worktree list";

    "gh rpc" = "gh repo clone";
    "gh rpr" = "gh repo create";
    "gh pc" = "gh pr create -B";
    "gh pm" = "gh pr merge";
    "gh rc" = "gh release create";
    "gh rl" = "gh release list";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "uPiscium";
        email = "upiscium@gmail.com";
      };

      push.autoSetupRemote = true;
      pull.rebase = false;
      credential.helper = "store";
      fetch.prune = true;
      submodule.recurse = true;
      init.defaultBranch = "main";
      ghq = {
        root = "~/src";
      };
      # signing = {
      #   signByDefault = true;
      #   format = "openpgp";
      #   key = "1B42AFA71A8CB553923473DF504D64B90F5356C1";
      # };
      # commit.gpgSign = true;
      # tag.gpgSign = true;
    };
  };

  programs.gh = {
    enable = true;

    extensions = with pkgs; [
      gh-markdown-preview
      gh-dash
    ];

    settings = {
      editor = "nvim";
    };
  };
}