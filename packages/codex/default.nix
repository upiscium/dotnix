{ codex, writeShellApplication }:

writeShellApplication {
  name = "codex";

  text = ''
    model_set=0
    effort_set=0
    profile_set=0
    expect_model=0
    expect_config=0

    for arg in "$@"; do
      if [[ "$arg" == "--" ]]; then
        break
      fi

      if (( expect_model )); then
        model_set=1
        expect_model=0
        continue
      fi

      if (( expect_config )); then
        case "$arg" in
          model=*) model_set=1 ;;
          model_reasoning_effort=*) effort_set=1 ;;
        esac
        expect_config=0
        continue
      fi

      case "$arg" in
        -m|--model)
          expect_model=1
          ;;
        -m?*|--model=*)
          model_set=1
          ;;
        -c|--config)
          expect_config=1
          ;;
        --config=model=*)
          model_set=1
          ;;
        --config=model_reasoning_effort=*)
          effort_set=1
          ;;
        -p|--profile|-p?*|--profile=*)
          profile_set=1
          ;;
      esac
    done

    # An explicit profile owns its own model defaults.
    if (( profile_set )); then
      exec ${codex}/bin/codex "$@"
    fi

    defaults=()
    if (( ! model_set )); then
      defaults+=(--model gpt-5.6-luna)
    fi
    if (( ! effort_set )); then
      defaults+=(--config 'model_reasoning_effort="max"')
    fi

    exec ${codex}/bin/codex "''${defaults[@]}" "$@"
  '';
}
