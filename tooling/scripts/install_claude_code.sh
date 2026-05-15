#!/usr/bin/env bash
set -euo pipefail

ACTION="install"
METHOD="auto"
FROM_METHOD="auto"
TARGET="latest"
FORCE=0
YES=0
DRY_RUN=0
SKIP_VERIFY=0
JSON=0
STATUS=0
FIX=0

get_action_display_name() {
  case "$1" in
    install) printf '%s\n' '安装' ;;
    update) printf '%s\n' '更新' ;;
    uninstall) printf '%s\n' '卸载' ;;
    status) printf '%s\n' '状态检查' ;;
    doctor) printf '%s\n' '环境诊断' ;;
    migrate) printf '%s\n' '安装来源迁移' ;;
    self-test) printf '%s\n' '脚本自检' ;;
    report) printf '%s\n' '环境报告' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

get_doctor_summary_display_name() {
  case "$1" in
    healthy) printf '%s\n' '正常' ;;
    warning) printf '%s\n' '需要关注' ;;
    not_installed) printf '%s\n' '未安装' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

get_self_test_check_display_name() {
  case "$1" in
    status\ --json|status-state) printf '%s\n' '状态信息检查' ;;
    doctor\ --json|doctor-state) printf '%s\n' '环境诊断检查' ;;
    doctor-fix-dryrun) printf '%s\n' '诊断修复预演检查' ;;
    update*) printf '%s\n' '更新计划预演检查' ;;
    uninstall*) printf '%s\n' '卸载计划预演检查' ;;
    install*) printf '%s\n' '安装计划预演检查' ;;
    plan-generation) printf '%s\n' '执行计划生成检查' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

ui_info() {
  [[ "$JSON" -eq 1 ]] && return 0
  printf '%s\n' "$1"
}

ui_warn() {
  [[ "$JSON" -eq 1 ]] && return 0
  printf '%s\n' "警告：$1"
}

ui_success() {
  [[ "$JSON" -eq 1 ]] && return 0
  printf '%s\n' "$1"
}

ui_progress() {
  local action_name="$1"
  local status_text="$2"
  local percent="$3"
  local width=20
  local filled=$(( percent * width / 100 ))
  local empty=$(( width - filled ))
  local bar_filled="" bar_empty=""

  [[ "$JSON" -eq 1 ]] && return 0
  if [[ ! -t 1 ]]; then
    printf '[%s] %s%% %s\n' "$(get_action_display_name "$action_name")" "$percent" "$status_text"
    return 0
  fi

  bar_filled="$(printf '%*s' "$filled" '' | tr ' ' '#')"
  bar_empty="$(printf '%*s' "$empty" '' | tr ' ' '-')"
  printf '\r[%s] [%s%s] %3s%% %s' "$(get_action_display_name "$action_name")" "$bar_filled" "$bar_empty" "$percent" "$status_text"
  if [[ "$percent" -ge 100 ]]; then
    printf '\n'
  fi
}

ui_progress_done() {
  local action_name="$1"
  [[ "$JSON" -eq 1 ]] && return 0
  ui_progress "$action_name" '已完成' 100
}

usage() {
  cat <<'EOF'
用法：
  ./install_claude_code.sh [install|update|uninstall|status|doctor|migrate|self-test] [options]

动作：
  install      安装 Claude Code
  update       更新 Claude Code
  uninstall    卸载 Claude Code
  status       查看当前安装状态
  doctor       诊断当前安装环境
  migrate      在不同安装方式之间迁移
  self-test    运行轻量级内置自检

参数：
  --method auto|native|homebrew|npm|apt|dnf|apk
  --from auto|native|homebrew|npm|apt|dnf|apk
  --target stable|latest|VERSION
  --force
  --yes
  --dry-run
  --skip-verify
  --json
  --fix
  --status
  --help
EOF
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    install|update|uninstall|status|doctor|migrate|self-test)
      ACTION="$1"
      shift
      ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --method)
      METHOD="${2:-}"
      shift 2
      ;;
    --from|--from-method)
      FROM_METHOD="${2:-}"
      shift 2
      ;;
    --target|--channel)
      TARGET="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --yes)
      YES=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --skip-verify)
      SKIP_VERIFY=1
      shift
      ;;
    --json)
      JSON=1
      shift
      ;;
    --fix)
      FIX=1
      shift
      ;;
    --status)
      STATUS=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "错误：不支持的参数：$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$STATUS" -eq 1 ]]; then
  ACTION="status"
fi

if [[ ! "$TARGET" =~ ^(stable|latest|[0-9]+\.[0-9]+\.[0-9]+([^[:space:]]+)?)$ ]]; then
  echo "错误：不支持的目标版本：$TARGET。请使用 stable、latest，或类似 2.1.89 的具体版本号。" >&2
  exit 1
fi

normalize_architecture() {
  case "$(uname -m | tr '[:upper:]' '[:lower:]')" in
    x86_64|amd64) echo "x64" ;;
    arm64|aarch64) echo "arm64" ;;
    *) uname -m | tr '[:upper:]' '[:lower:]' ;;
  esac
}

is_wsl() {
  if [[ -n "${WSL_INTEROP:-}" || -n "${WSL_DISTRO_NAME:-}" ]]; then
    return 0
  fi

  if [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease; then
    return 0
  fi

  return 1
}

detect_system() {
  local system_name
  system_name="$(uname -s | tr '[:upper:]' '[:lower:]')"

  case "$system_name" in
    darwin)
      echo "macos"
      ;;
    linux)
      if is_wsl; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_command() {
  local name="$1"
  if ! command_exists "$name"; then
    echo "错误：缺少必要命令：$name" >&2
    exit 1
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

get_native_command_path() {
  echo "$HOME/.local/bin/claude"
}

get_native_share_path() {
  echo "$HOME/.local/share/claude"
}

get_legacy_local_path() {
  echo "$HOME/.claude/local"
}

collect_claude_paths() {
  local candidate
  if command_exists claude; then
    candidate="$(command -v claude)"
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
    fi
  fi
}

detect_homebrew_cask() {
  if ! command_exists brew; then
    return 1
  fi

  if brew list --cask claude-code >/dev/null 2>&1; then
    printf 'claude-code\n'
    return 0
  fi

  if brew list --cask claude-code@latest >/dev/null 2>&1; then
    printf 'claude-code@latest\n'
    return 0
  fi

  return 1
}

detect_apt_install() {
  command_exists dpkg && dpkg -s claude-code >/dev/null 2>&1
}

detect_dnf_install() {
  command_exists rpm && rpm -q claude-code >/dev/null 2>&1
}

detect_apk_install() {
  command_exists apk && apk info -e claude-code >/dev/null 2>&1
}

append_unique() {
  local value="$1"
  local var_name="$2"
  local current
  eval "current=(\"\${${var_name}[@]:-}\")"
  local item
  for item in "${current[@]}"; do
    if [[ "$item" == "$value" ]]; then
      return 0
    fi
  done
  eval "${var_name}+=(\"\$value\")"
}

build_state() {
  local system="$1"
  STATE_NATIVE_PATH="$(get_native_command_path)"
  STATE_NATIVE_SHARE_PATH="$(get_native_share_path)"
  STATE_LEGACY_LOCAL_PATH="$(get_legacy_local_path)"
  STATE_NATIVE_INSTALLED=0
  STATE_NPM_INSTALLED=0
  STATE_HOMEBREW_CASK=""
  STATE_APT_INSTALLED=0
  STATE_DNF_INSTALLED=0
  STATE_APK_INSTALLED=0
  STATE_DETECTED_METHODS=()
  STATE_WARNINGS=()
  STATE_CLAUDE_PATHS=()

  if [[ -x "$STATE_NATIVE_PATH" ]]; then
    STATE_NATIVE_INSTALLED=1
    append_unique "native" STATE_DETECTED_METHODS
  fi

  if [[ "$system" == "macos" ]]; then
    STATE_HOMEBREW_CASK="$(detect_homebrew_cask || true)"
    if [[ -n "$STATE_HOMEBREW_CASK" ]]; then
      append_unique "homebrew" STATE_DETECTED_METHODS
    fi
  fi

  if [[ "$system" == "linux" ]]; then
    if detect_apt_install; then
      STATE_APT_INSTALLED=1
      append_unique "apt" STATE_DETECTED_METHODS
    fi
    if detect_dnf_install; then
      STATE_DNF_INSTALLED=1
      append_unique "dnf" STATE_DETECTED_METHODS
    fi
    if detect_apk_install; then
      STATE_APK_INSTALLED=1
      append_unique "apk" STATE_DETECTED_METHODS
    fi
  fi

  while IFS= read -r path_entry; do
    [[ -n "$path_entry" ]] || continue
    STATE_CLAUDE_PATHS+=("$path_entry")
    local resolved_path="$path_entry"
    if command_exists readlink; then
      resolved_path="$(readlink -f "$path_entry" 2>/dev/null || printf '%s' "$path_entry")"
    fi

    if [[ "$path_entry" == "$HOME/.claude/local/"* ]]; then
      append_unique "Detected legacy local files under .claude/local. Remove them if they are from an older install." STATE_WARNINGS
    fi
    if [[ "$system" == "wsl" && "$path_entry" == /mnt/[a-z]/Users/*/AppData/* ]]; then
      append_unique "Detected a Windows claude command on the WSL PATH. Use the Windows script if you want to manage that installation." STATE_WARNINGS
    fi

    if [[ "$resolved_path" == *"/node_modules/@anthropic-ai/claude-code/"* || "$resolved_path" == *"/node_modules/@anthropic-ai/claude-code" ]]; then
      STATE_NPM_INSTALLED=1
      append_unique "npm" STATE_DETECTED_METHODS
    fi
  done < <(collect_claude_paths)

  if [[ -d "$STATE_LEGACY_LOCAL_PATH" ]]; then
    append_unique "Detected legacy local files under .claude/local. Remove them if they are from an older install." STATE_WARNINGS
  fi

  if [[ ${#STATE_CLAUDE_PATHS[@]} -gt 1 ]]; then
    append_unique "Detected multiple claude commands on PATH. Keep only one installation method to avoid version mismatches." STATE_WARNINGS
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 1 ]]; then
    append_unique "Detected multiple install methods: ${STATE_DETECTED_METHODS[*]}" STATE_WARNINGS
  fi
}

native_supported() {
  command_exists bash && { command_exists curl || command_exists wget; }
}

get_supported_methods() {
  local system="$1"
  case "$system" in
    macos) printf '%s\n' native homebrew npm ;;
    linux|wsl) printf '%s\n' native npm apt dnf apk ;;
    *) return 1 ;;
  esac
}

get_available_install_methods() {
  local system="$1"
  local methods=()
  local candidate

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    case "$candidate" in
      native)
        if native_supported; then
          methods+=("native")
        fi
        ;;
      homebrew)
        if command_exists brew; then
          methods+=("homebrew")
        fi
        ;;
      npm)
        if command_exists npm; then
          methods+=("npm")
        fi
        ;;
      apt)
        if command_exists apt; then
          methods+=("apt")
        fi
        ;;
      dnf)
        if command_exists dnf; then
          methods+=("dnf")
        fi
        ;;
      apk)
        if command_exists apk; then
          methods+=("apk")
        fi
        ;;
    esac
  done < <(get_supported_methods "$system")

  printf '%s\n' "${methods[@]}"
}

get_entry_command() {
  printf '%s\n' 'bash ./install_claude_code.sh'
}

get_claude_version_text() {
  local candidate output

  if [[ -x "$STATE_NATIVE_PATH" ]]; then
    output="$("$STATE_NATIVE_PATH" --version 2>/dev/null || true)"
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output"
      return 0
    fi
  fi

  for candidate in "${STATE_CLAUDE_PATHS[@]}"; do
    case "$candidate" in
      /mnt/[a-z]/Users/*/AppData/Roaming/npm/claude|/mnt/[a-z]/Users/*/AppData/Roaming/npm/claude.cmd|/mnt/[a-z]/Users/*/AppData/Roaming/npm/claude.ps1)
        local package_json
        package_json="$(dirname "$candidate")/node_modules/@anthropic-ai/claude-code/package.json"
        if [[ -f "$package_json" ]]; then
          output="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$package_json" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
          if [[ -n "$output" ]]; then
            printf '%s\n' "$output"
            return 0
          fi
        fi
        ;;
      *)
        output="$("$candidate" --version 2>/dev/null || true)"
        if [[ -n "$output" ]]; then
          printf '%s\n' "$output"
          return 0
        fi
        ;;
    esac
  done

  return 1
}

get_doctor_summary() {
  if [[ ${#STATE_DETECTED_METHODS[@]} -eq 0 && ${#STATE_CLAUDE_PATHS[@]} -eq 0 ]]; then
    printf '%s\n' 'not_installed'
    return 0
  fi

  local version_output
  version_output="$(get_claude_version_text || true)"
  if [[ ( ${#STATE_DETECTED_METHODS[@]} -gt 0 || ${#STATE_CLAUDE_PATHS[@]} -gt 0 ) && -z "$version_output" ]]; then
    printf '%s\n' 'warning'
    return 0
  fi

  if [[ ${#STATE_WARNINGS[@]} -gt 0 ]]; then
    printf '%s\n' 'warning'
    return 0
  fi

  printf '%s\n' 'healthy'
}

get_doctor_recommendations() {
  local system="$1"
  local entry_command available_methods only_method
  entry_command="$(get_entry_command)"
  mapfile -t available_methods < <(get_available_install_methods "$system")

  if [[ ${#STATE_DETECTED_METHODS[@]} -eq 0 && ${#available_methods[@]} -gt 0 ]]; then
    printf '%s\n' "$entry_command install --yes"
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -eq 1 ]]; then
    only_method="${STATE_DETECTED_METHODS[0]}"
    printf '%s\n' "$entry_command update --method $only_method --dry-run --yes"

    if [[ "$only_method" == "npm" ]]; then
      local candidate
      for candidate in "${available_methods[@]}"; do
        if [[ "$candidate" == "native" ]]; then
          printf '%s\n' "$entry_command migrate --from npm --method native --dry-run --yes"
          break
        fi
      done
    fi
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 1 ]]; then
    printf '%s\n' "$entry_command migrate --from <source> --method native --dry-run --yes"
    printf '%s\n' "$entry_command uninstall --method <source> --dry-run --yes"
  fi

  if [[ -d "$STATE_LEGACY_LOCAL_PATH" ]]; then
    printf '%s\n' "确认旧文件不再需要后，删除 $STATE_LEGACY_LOCAL_PATH 下的遗留文件。"
  fi

  if [[ ${#STATE_CLAUDE_PATHS[@]} -gt 0 ]]; then
    printf '%s\n' '如果 Claude CLI 可以正常启动，建议继续执行 claude doctor 做更深一步的内建检查。'
  fi
}

resolve_method() {
  local system="$1"
  local requested="$2"
  local action="$3"

  local supported_methods=()
  mapfile -t supported_methods < <(get_supported_methods "$system")
  local method_is_supported=0
  local candidate
  if [[ "$requested" == "auto" ]]; then
    method_is_supported=1
  else
    for candidate in "${supported_methods[@]}"; do
      if [[ "$candidate" == "$requested" ]]; then
        method_is_supported=1
        break
      fi
    done
  fi

  if [[ "$method_is_supported" -ne 1 ]]; then
      echo "错误：$system 暂不支持安装方式：$requested" >&2
    exit 1
  fi

  if [[ "$requested" != "auto" ]]; then
    printf '%s\n' "$requested"
    return 0
  fi

  if [[ "$action" == "status" || "$action" == "doctor" ]]; then
    if [[ ${#STATE_DETECTED_METHODS[@]} -eq 1 ]]; then
      printf '%s\n' "${STATE_DETECTED_METHODS[0]}"
      return 0
    fi
  fi

  if [[ "$action" == "install" || "$action" == "status" || "$action" == "doctor" ]]; then
    local available_methods=()
    mapfile -t available_methods < <(get_available_install_methods "$system")
    if [[ ${#available_methods[@]} -gt 0 ]]; then
      printf '%s\n' "${available_methods[0]}"
      return 0
    fi
  fi

  if [[ "$action" == "status" && ${#STATE_DETECTED_METHODS[@]} -eq 1 ]]; then
    printf '%s\n' "${STATE_DETECTED_METHODS[0]}"
    return 0
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -eq 1 ]]; then
    printf '%s\n' "${STATE_DETECTED_METHODS[0]}"
    return 0
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 1 ]]; then
    echo "错误：检测到多个安装来源（${STATE_DETECTED_METHODS[*]}）。请重新执行并通过 --method 指定要管理的安装方式。" >&2
    exit 1
  fi

  echo "错误：未检测到受支持的 Claude Code 安装。" >&2
  exit 1
}

method_installed() {
  local method="$1"
  case "$method" in
    native) [[ "$STATE_NATIVE_INSTALLED" -eq 1 ]] ;;
    homebrew) [[ -n "$STATE_HOMEBREW_CASK" ]] ;;
    npm) [[ "$STATE_NPM_INSTALLED" -eq 1 ]] ;;
    apt) [[ "$STATE_APT_INSTALLED" -eq 1 ]] ;;
    dnf) [[ "$STATE_DNF_INSTALLED" -eq 1 ]] ;;
    apk) [[ "$STATE_APK_INSTALLED" -eq 1 ]] ;;
    *) return 1 ;;
  esac
}

print_json_status() {
  local system="$1"
  local arch="$2"
  local resolved_method="$3"
  local installed=false

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 0 || ${#STATE_CLAUDE_PATHS[@]} -gt 0 ]]; then
    installed=true
  fi

  printf '{'
  printf '"action":"%s",' "$(json_escape "$ACTION")"
  printf '"system":"%s",' "$(json_escape "$system")"
  printf '"architecture":"%s",' "$(json_escape "$arch")"
  printf '"requestedMethod":"%s",' "$(json_escape "$METHOD")"
  printf '"resolvedMethod":"%s",' "$(json_escape "$resolved_method")"
  printf '"target":"%s",' "$(json_escape "$TARGET")"
  printf '"installed":%s,' "$installed"

  printf '"detectedMethods":['
  local first=1 item
  for item in "${STATE_DETECTED_METHODS[@]}"; do
    [[ "$first" -eq 1 ]] || printf ','
    printf '"%s"' "$(json_escape "$item")"
    first=0
  done
  printf '],'

  printf '"claudePaths":['
  first=1
  for item in "${STATE_CLAUDE_PATHS[@]}"; do
    [[ "$first" -eq 1 ]] || printf ','
    printf '"%s"' "$(json_escape "$item")"
    first=0
  done
  printf '],'

  printf '"nativeInstalled":%s,' "$([[ "$STATE_NATIVE_INSTALLED" -eq 1 ]] && echo true || echo false)"
  printf '"homebrewCask":"%s",' "$(json_escape "$STATE_HOMEBREW_CASK")"
  printf '"npmInstalled":%s,' "$([[ "$STATE_NPM_INSTALLED" -eq 1 ]] && echo true || echo false)"
  printf '"aptInstalled":%s,' "$([[ "$STATE_APT_INSTALLED" -eq 1 ]] && echo true || echo false)"
  printf '"dnfInstalled":%s,' "$([[ "$STATE_DNF_INSTALLED" -eq 1 ]] && echo true || echo false)"
  printf '"apkInstalled":%s,' "$([[ "$STATE_APK_INSTALLED" -eq 1 ]] && echo true || echo false)"

  printf '"warnings":['
  first=1
  for item in "${STATE_WARNINGS[@]}"; do
    [[ "$first" -eq 1 ]] || printf ','
    printf '"%s"' "$(json_escape "$item")"
    first=0
  done
  printf '],'

  printf '"planNote":"%s",' "$(json_escape "${PLAN_NOTE:-}")"
  printf '"planCommand":"%s",' "$(json_escape "${PLAN_COMMAND:-}")"
  printf '"dryRun":%s' "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)"
  printf '}\n'
}

print_status() {
  local system="$1"
  local arch="$2"
  local resolved_method="$3"

  if [[ "$JSON" -eq 1 ]]; then
    print_json_status "$system" "$arch" "$resolved_method"
    return 0
  fi

  ui_info "当前动作：$(get_action_display_name "$ACTION")"
  ui_info "检测到的系统：$system"
  ui_info "检测到的架构：$arch"
  ui_info "请求的安装方式：$METHOD"
  ui_info "最终使用的安装方式：$resolved_method"
  ui_info "目标版本：$TARGET"

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 0 ]]; then
    ui_info "检测到的安装来源：${STATE_DETECTED_METHODS[*]}"
  else
    ui_info "检测到的安装来源：无"
  fi

  if [[ ${#STATE_CLAUDE_PATHS[@]} -gt 0 ]]; then
    ui_info "检测到的 Claude 路径："
    local item
    for item in "${STATE_CLAUDE_PATHS[@]}"; do
      ui_info "  $item"
    done
  else
    ui_info "检测到的 Claude 路径：无"
  fi

  if [[ -n "${PLAN_COMMAND:-}" ]]; then
    ui_info "计划执行命令：$PLAN_COMMAND"
  fi

  if [[ ${#STATE_WARNINGS[@]} -gt 0 ]]; then
    ui_warn "以下项目需要关注："
    local item
    for item in "${STATE_WARNINGS[@]}"; do
      ui_warn "  - $item"
    done
  fi
}

print_doctor() {
  local system="$1"
  local arch="$2"
  local resolved_method="$3"
  local summary version_output
  local available_methods=()
  local recommendations=()

  summary="$(get_doctor_summary)"
  version_output="$(get_claude_version_text || true)"
  mapfile -t available_methods < <(get_available_install_methods "$system")
  mapfile -t recommendations < <(get_doctor_recommendations "$system")

  if [[ "$JSON" -eq 1 ]]; then
    printf '{'
    printf '"action":"doctor",'
    printf '"system":"%s",' "$(json_escape "$system")"
    printf '"architecture":"%s",' "$(json_escape "$arch")"
    printf '"preferredInstallMethod":"%s",' "$(json_escape "$resolved_method")"
    printf '"summary":"%s",' "$(json_escape "$summary")"
    printf '"version":"%s",' "$(json_escape "$version_output")"

    printf '"availableInstallMethods":['
    local first=1 item
    for item in "${available_methods[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf '],'

    printf '"detectedMethods":['
    first=1
    for item in "${STATE_DETECTED_METHODS[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf '],'

    printf '"claudePaths":['
    first=1
    for item in "${STATE_CLAUDE_PATHS[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf '],'

    printf '"warnings":['
    first=1
    for item in "${STATE_WARNINGS[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf '],'

    printf '"recommendations":['
    first=1
    for item in "${recommendations[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf ']}\n'
    return 0
  fi

  ui_info "诊断结论：$(get_doctor_summary_display_name "$summary")"
  ui_info "检测到的系统：$system"
  ui_info "检测到的架构：$arch"
  ui_info "推荐安装方式：$resolved_method"
  if [[ -n "$version_output" ]]; then
    ui_info "检测到的版本：$version_output"
  else
    ui_info "检测到的版本：无法获取"
  fi

  if [[ ${#available_methods[@]} -gt 0 ]]; then
    ui_info "当前环境可用的安装方式：${available_methods[*]}"
  else
    ui_info "当前环境可用的安装方式：无"
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 0 ]]; then
    ui_info "检测到的安装来源：${STATE_DETECTED_METHODS[*]}"
  else
    ui_info "检测到的安装来源：无"
  fi

  if [[ ${#STATE_CLAUDE_PATHS[@]} -gt 0 ]]; then
    ui_info "检测到的 Claude 路径："
    local item
    for item in "${STATE_CLAUDE_PATHS[@]}"; do
      ui_info "  $item"
    done
  else
    ui_info "检测到的 Claude 路径：无"
  fi

  if [[ ${#STATE_WARNINGS[@]} -gt 0 ]]; then
    ui_warn "以下项目需要关注："
    local item
    for item in "${STATE_WARNINGS[@]}"; do
      ui_warn "  - $item"
    done
  fi

  if [[ ${#recommendations[@]} -gt 0 ]]; then
    ui_info "建议下一步执行："
    local item
    for item in "${recommendations[@]}"; do
      ui_info "  - $item"
    done
  fi
}

run_doctor_fix() {
  local system="$1"
  local arch="$2"
  local actions=()
  local warnings=()

  if [[ -d "$STATE_LEGACY_LOCAL_PATH" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      actions+=("将删除 $STATE_LEGACY_LOCAL_PATH")
    else
      confirm_or_exit "检测到 $STATE_LEGACY_LOCAL_PATH 下存在遗留文件，是否删除？"
      rm -rf "$STATE_LEGACY_LOCAL_PATH"
      actions+=("已删除 $STATE_LEGACY_LOCAL_PATH")
    fi
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 1 ]]; then
    warnings+=("检测到多个安装来源。请先查看诊断建议，再明确执行 migrate 或 uninstall。")
  elif [[ ${#STATE_DETECTED_METHODS[@]} -eq 1 && "${STATE_DETECTED_METHODS[0]}" == "npm" ]]; then
    local available_methods=()
    mapfile -t available_methods < <(get_available_install_methods "$system")
    local candidate
    for candidate in "${available_methods[@]}"; do
      if [[ "$candidate" == "native" ]]; then
        warnings+=("检测到 npm 安装，建议通过以下命令迁移到 native：$(get_entry_command) migrate --from npm --method native --dry-run --yes")
        break
      fi
    done
  fi

  build_state "$system"

  if [[ "$JSON" -eq 1 ]]; then
    printf '{'
    printf '"action":"doctor-fix",'
    printf '"system":"%s",' "$(json_escape "$system")"
    printf '"architecture":"%s",' "$(json_escape "$arch")"
    printf '"dryRun":%s,' "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)"
    printf '"actions":['
    local first=1 item
    for item in "${actions[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf '],'
    printf '"warnings":['
    first=1
    for item in "${warnings[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf '],'
    printf '"detectedMethods":['
    first=1
    for item in "${STATE_DETECTED_METHODS[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf ']}\n'
    return 0
  fi

  if [[ ${#actions[@]} -gt 0 ]]; then
    ui_info "诊断修复执行结果："
    local item
    for item in "${actions[@]}"; do
      ui_info "  - $item"
    done
  else
    ui_info "诊断修复执行结果：无变更"
  fi

  if [[ ${#warnings[@]} -gt 0 ]]; then
    ui_info "后续建议："
    local item
    for item in "${warnings[@]}"; do
      ui_info "  - $item"
    done
  fi
}

confirm_or_exit() {
  local prompt_text="$1"

  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    echo "错误：检测到当前环境为非交互模式。请重新执行并带上 --yes。" >&2
    exit 1
  fi

  read -r -p "$prompt_text [y/N] " answer
  case "${answer,,}" in
    y|yes) ;;
    *)
      echo "操作已取消。" >&2
      exit 1
      ;;
  esac
}

set_plan() {
  PLAN_NOTE="$1"
  PLAN_COMMAND="$2"
}

build_plan_for() {
  local action="$1"
  local method="$2"
  local saved_action="$ACTION"
  local saved_method="$RESOLVED_METHOD"

  ACTION="$action"
  RESOLVED_METHOD="$method"
  build_plan
  BUILT_PLAN_NOTE="$PLAN_NOTE"
  BUILT_PLAN_COMMAND="$PLAN_COMMAND"

  ACTION="$saved_action"
  RESOLVED_METHOD="$saved_method"
}

build_native_install_plan() {
  require_command bash
  if command_exists curl; then
    local base='curl -fsSL https://claude.ai/install.sh | bash'
    if [[ "$TARGET" == "latest" ]]; then
      set_plan "执行官方 native 安装脚本" "$base"
    else
      set_plan "执行指定版本的官方 native 安装脚本" "$base -s $TARGET"
    fi
    return 0
  fi

  require_command wget
  local base='wget -qO- https://claude.ai/install.sh | bash'
  if [[ "$TARGET" == "latest" ]]; then
    set_plan "执行官方 native 安装脚本" "$base"
  else
    set_plan "执行指定版本的官方 native 安装脚本" "$base -s $TARGET"
  fi
}

build_native_update_plan() {
  local runner="$STATE_NATIVE_PATH"
  if [[ ! -x "$runner" ]]; then
    runner="claude"
  fi

  if [[ "$TARGET" == "latest" ]]; then
    set_plan "更新 native 安装" "$runner update"
  else
    set_plan "把 native 安装切换到指定版本" "$runner install $TARGET"
  fi
}

build_native_uninstall_plan() {
  set_plan \
    "Remove the native binary and version files" \
    "rm -f \"$STATE_NATIVE_PATH\" && rm -rf \"$STATE_NATIVE_SHARE_PATH\""
}

build_homebrew_plan() {
  require_command brew
  local cask_name="$STATE_HOMEBREW_CASK"

  if [[ -z "$cask_name" ]]; then
    case "$TARGET" in
      stable) cask_name="claude-code" ;;
      latest) cask_name="claude-code@latest" ;;
      *)
        echo "错误：当前封装里的 Homebrew 仅支持 stable 或 latest。" >&2
        exit 1
        ;;
    esac
  fi

  case "$ACTION" in
    install) set_plan "使用 Homebrew 安装 Claude Code" "brew install --cask $cask_name" ;;
    update) set_plan "使用 Homebrew 更新 Claude Code" "brew upgrade $cask_name" ;;
    uninstall) set_plan "使用 Homebrew 卸载 Claude Code" "brew uninstall --cask $cask_name" ;;
    *) echo "错误：Homebrew 不支持当前动作：$ACTION" >&2; exit 1 ;;
  esac
}

build_npm_plan() {
  require_command npm
  if [[ "$TARGET" == "stable" ]]; then
    echo "错误：当前封装里的 npm 支持 latest 或具体版本号，不支持 stable。" >&2
    exit 1
  fi

  local package_spec
  case "$ACTION" in
    install)
      if [[ "$TARGET" == "latest" ]]; then
        package_spec="@anthropic-ai/claude-code"
      else
        package_spec="@anthropic-ai/claude-code@$TARGET"
      fi
      set_plan "使用 npm 安装 Claude Code" "npm install -g $package_spec"
      ;;
    update)
      if [[ "$TARGET" == "latest" ]]; then
        package_spec="@anthropic-ai/claude-code@latest"
      else
        package_spec="@anthropic-ai/claude-code@$TARGET"
      fi
      set_plan "使用 npm 更新 Claude Code" "npm install -g $package_spec"
      ;;
    uninstall)
      set_plan "使用 npm 卸载 Claude Code" "npm uninstall -g @anthropic-ai/claude-code"
      ;;
    *)
      echo "错误：npm 不支持当前动作：$ACTION" >&2
      exit 1
      ;;
  esac
}

build_apt_plan() {
  if [[ "$TARGET" != "stable" && "$TARGET" != "latest" ]]; then
    echo "错误：当前封装里的 apt 仅支持 stable 或 latest。" >&2
    exit 1
  fi

  case "$ACTION" in
    install)
      local key_download
      if command_exists curl; then
        key_download="sudo curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o /etc/apt/keyrings/claude-code.asc"
      elif command_exists wget; then
        key_download="sudo wget -qO /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc"
      else
        echo "错误：apt 安装需要 curl 或 wget。" >&2
        exit 1
      fi
      set_plan \
        "使用 apt 安装 Claude Code" \
        "sudo install -d -m 0755 /etc/apt/keyrings && $key_download && echo \"deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/$TARGET $TARGET main\" | sudo tee /etc/apt/sources.list.d/claude-code.list >/dev/null && sudo apt update && sudo apt install -y claude-code"
      ;;
    update)
      set_plan "使用 apt 更新 Claude Code" "sudo apt update && sudo apt install --only-upgrade -y claude-code"
      ;;
    uninstall)
      set_plan "使用 apt 卸载 Claude Code" "sudo apt remove -y claude-code && sudo rm -f /etc/apt/sources.list.d/claude-code.list /etc/apt/keyrings/claude-code.asc"
      ;;
    *)
      echo "错误：apt 不支持当前动作：$ACTION" >&2
      exit 1
      ;;
  esac
}

build_dnf_plan() {
  if [[ "$TARGET" != "stable" && "$TARGET" != "latest" ]]; then
    echo "错误：当前封装里的 dnf 仅支持 stable 或 latest。" >&2
    exit 1
  fi

  case "$ACTION" in
    install)
      set_plan \
        "使用 dnf 安装 Claude Code" \
        "printf '%s\n' '[claude-code]' 'name=Claude Code' 'baseurl=https://downloads.claude.ai/claude-code/rpm/$TARGET/\$basearch' 'enabled=1' 'gpgcheck=1' 'repo_gpgcheck=0' 'gpgkey=https://downloads.claude.ai/keys/claude-code.asc' | sudo tee /etc/yum.repos.d/claude-code.repo >/dev/null && sudo dnf install -y claude-code"
      ;;
    update)
      set_plan "使用 dnf 更新 Claude Code" "sudo dnf upgrade -y claude-code"
      ;;
    uninstall)
      set_plan "使用 dnf 卸载 Claude Code" "sudo dnf remove -y claude-code && sudo rm -f /etc/yum.repos.d/claude-code.repo"
      ;;
    *)
      echo "错误：dnf 不支持当前动作：$ACTION" >&2
      exit 1
      ;;
  esac
}

build_apk_plan() {
  if [[ "$TARGET" != "stable" && "$TARGET" != "latest" ]]; then
    echo "错误：当前封装里的 apk 仅支持 stable 或 latest。" >&2
    exit 1
  fi

  case "$ACTION" in
    install)
      local key_download
      if command_exists wget; then
        key_download="sudo wget -qO /etc/apk/keys/claude-code.rsa.pub https://downloads.claude.ai/keys/claude-code.rsa.pub"
      elif command_exists curl; then
        key_download="sudo curl -fsSL https://downloads.claude.ai/keys/claude-code.rsa.pub -o /etc/apk/keys/claude-code.rsa.pub"
      else
        echo "错误：apk 安装需要 wget 或 curl。" >&2
        exit 1
      fi
      set_plan \
        "使用 apk 安装 Claude Code" \
        "$key_download && echo \"https://downloads.claude.ai/claude-code/apk/$TARGET\" | sudo tee -a /etc/apk/repositories >/dev/null && sudo apk update && sudo apk add claude-code"
      ;;
    update)
      set_plan "使用 apk 更新 Claude Code" "sudo apk update && sudo apk upgrade claude-code"
      ;;
    uninstall)
      set_plan "使用 apk 卸载 Claude Code" "sudo apk del claude-code && sudo sed -i '\\|downloads.claude.ai/claude-code/apk|d' /etc/apk/repositories && sudo rm -f /etc/apk/keys/claude-code.rsa.pub"
      ;;
    *)
      echo "错误：apk 不支持当前动作：$ACTION" >&2
      exit 1
      ;;
  esac
}

build_plan() {
  PLAN_NOTE=""
  PLAN_COMMAND=""

  case "$RESOLVED_METHOD" in
    native)
      case "$ACTION" in
        install) build_native_install_plan ;;
        update) build_native_update_plan ;;
        uninstall) build_native_uninstall_plan ;;
        *) echo "错误：native 不支持当前动作：$ACTION" >&2; exit 1 ;;
      esac
      ;;
    homebrew) build_homebrew_plan ;;
    npm) build_npm_plan ;;
    apt) build_apt_plan ;;
    dnf) build_dnf_plan ;;
    apk) build_apk_plan ;;
    *)
      echo "错误：不支持的安装方式：$RESOLVED_METHOD" >&2
      exit 1
      ;;
  esac
}

verify_install() {
  local candidate
  if [[ -x "$STATE_NATIVE_PATH" ]]; then
    "$STATE_NATIVE_PATH" --version
    return 0
  fi

  for candidate in "${STATE_CLAUDE_PATHS[@]}"; do
    if "$candidate" --version >/dev/null 2>&1; then
      "$candidate" --version
      return 0
    fi
  done

  if command_exists claude; then
    claude --version
    return 0
  fi

  echo "错误：安装或更新已经完成，但版本校验失败。" >&2
  exit 1
}

show_remaining_install_hint() {
  local paths=()
  while IFS= read -r path_entry; do
    [[ -n "$path_entry" ]] || continue
    paths+=("$path_entry")
  done < <(collect_claude_paths)

  if [[ ${#paths[@]} -gt 0 ]]; then
    ui_info "卸载已完成，但 PATH 中仍然存在其他 claude 命令："
    local item
    for item in "${paths[@]}"; do
      ui_info "  $item"
    done
    ui_warn "如果这不是你预期的结果，请手动移除多余的安装。"
  else
    ui_success "卸载已完成。"
  fi
}

resolve_migration_source_method() {
  local system="$1"
  local requested="$2"
  local supported_methods=()
  local candidate
  local supported=0

  mapfile -t supported_methods < <(get_supported_methods "$system")
  if [[ "$requested" != "auto" ]]; then
    for candidate in "${supported_methods[@]}"; do
      if [[ "$candidate" == "$requested" ]]; then
        supported=1
        break
      fi
    done
    if [[ "$supported" -ne 1 ]]; then
      echo "错误：$system 暂不支持迁移来源方式：$requested" >&2
      exit 1
    fi
    if ! method_installed "$requested"; then
      echo "错误：当前机器上未检测到 $requested 安装。" >&2
      exit 1
    fi
    printf '%s\n' "$requested"
    return 0
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -eq 1 ]]; then
    printf '%s\n' "${STATE_DETECTED_METHODS[0]}"
    return 0
  fi

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 1 ]]; then
    echo "错误：检测到多个安装来源（${STATE_DETECTED_METHODS[*]}）。请重新执行并通过 --from 指定迁移来源。" >&2
    exit 1
  fi

  echo "错误：未检测到可用于迁移的受支持 Claude Code 安装。" >&2
  exit 1
}

resolve_migration_target_method() {
  local system="$1"
  local requested="$2"
  local source_method="$3"
  local supported_methods=()
  local available_methods=()
  local candidate

  mapfile -t supported_methods < <(get_supported_methods "$system")
  if [[ "$requested" != "auto" ]]; then
    local supported=0
    for candidate in "${supported_methods[@]}"; do
      if [[ "$candidate" == "$requested" ]]; then
        supported=1
        break
      fi
    done
    if [[ "$supported" -ne 1 ]]; then
      echo "错误：$system 暂不支持迁移目标方式：$requested" >&2
      exit 1
    fi
    if [[ "$requested" == "$source_method" ]]; then
      echo "错误：迁移目标方式与来源方式相同：$source_method" >&2
      exit 1
    fi
    printf '%s\n' "$requested"
    return 0
  fi

  mapfile -t available_methods < <(get_available_install_methods "$system")
  for candidate in "${available_methods[@]}"; do
    if [[ "$source_method" != "native" && "$candidate" == "native" ]]; then
      printf '%s\n' 'native'
      return 0
    fi
  done

  for candidate in "${available_methods[@]}"; do
    if [[ "$candidate" != "$source_method" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "错误：无法自动选择迁移目标。请重新执行并通过 --method 指定目标安装方式。" >&2
  exit 1
}

print_migration_plan() {
  local system="$1"
  local arch="$2"
  local source_method="$3"
  local target_method="$4"
  local target_already_installed="$5"
  local step_commands=("${@:6}")

  if [[ "$JSON" -eq 1 ]]; then
    printf '{'
    printf '"action":"migrate",'
    printf '"system":"%s",' "$(json_escape "$system")"
    printf '"architecture":"%s",' "$(json_escape "$arch")"
    printf '"sourceMethod":"%s",' "$(json_escape "$source_method")"
    printf '"targetMethod":"%s",' "$(json_escape "$target_method")"
    printf '"targetAlreadyInstalled":%s,' "$([[ "$target_already_installed" -eq 1 ]] && echo true || echo false)"
    printf '"steps":['
    local first=1 command_text
    for command_text in "${step_commands[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$command_text")"
      first=0
    done
    printf '],'
    printf '"warnings":['
    first=1
    local item
    for item in "${STATE_WARNINGS[@]}"; do
      [[ "$first" -eq 1 ]] || printf ','
      printf '"%s"' "$(json_escape "$item")"
      first=0
    done
    printf '],'
    printf '"dryRun":%s' "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)"
    printf '}\n'
    return 0
  fi

  ui_info "迁移来源方式：$source_method"
  ui_info "迁移目标方式：$target_method"
  if [[ "$target_already_installed" -eq 1 ]]; then
    ui_info "目标安装状态：已安装"
  else
    ui_info "目标安装状态：待安装"
  fi
  ui_info "迁移步骤："
  local step_index=1 command_text
  for command_text in "${step_commands[@]}"; do
    ui_info "  $step_index. $command_text"
    step_index=$((step_index + 1))
  done

  if [[ ${#STATE_WARNINGS[@]} -gt 0 ]]; then
    ui_warn "以下项目需要关注："
    local item
    for item in "${STATE_WARNINGS[@]}"; do
      ui_warn "  - $item"
    done
  fi
}

run_self_test() {
  local system="$1"
  local arch="$2"
  local checks=()
  local method_to_test=""
  local output status_code

  checks+=("status --json")
  checks+=("doctor --json")

  if [[ ${#STATE_DETECTED_METHODS[@]} -gt 0 ]]; then
    method_to_test="${STATE_DETECTED_METHODS[0]}"
    checks+=("update --method $method_to_test --dry-run --yes")
    checks+=("uninstall --method $method_to_test --dry-run --yes")
  else
    local available_methods=()
    mapfile -t available_methods < <(get_available_install_methods "$system")
    if [[ ${#available_methods[@]} -gt 0 ]]; then
      method_to_test="${available_methods[0]}"
      checks+=("install --method $method_to_test --dry-run --force --yes")
    fi
  fi

  local passed=1
  local results=()
  local check
  for check in "${checks[@]}"; do
    output="$(bash "$0" $check 2>&1 || true)"
    status_code=$?
    if [[ "$status_code" -ne 0 ]]; then
      passed=0
    fi
    results+=("$check|$status_code|$output")
  done

  if [[ "$JSON" -eq 1 ]]; then
    printf '{'
    printf '"action":"self-test",'
    printf '"system":"%s",' "$(json_escape "$system")"
    printf '"architecture":"%s",' "$(json_escape "$arch")"
    printf '"passed":%s,' "$([[ "$passed" -eq 1 ]] && echo true || echo false)"
    printf '"checks":['
    local first=1 result name exit_code result_output
    for result in "${results[@]}"; do
      name="${result%%|*}"
      local rest="${result#*|}"
      exit_code="${rest%%|*}"
      result_output="${rest#*|}"
      [[ "$first" -eq 1 ]] || printf ','
      printf '{"name":"%s","success":%s,"exitCode":%s,"output":"%s"}' \
        "$(json_escape "$name")" \
        "$([[ "$exit_code" -eq 0 ]] && echo true || echo false)" \
        "$exit_code" \
        "$(json_escape "$result_output")"
      first=0
    done
    printf ']}\n'
    return $([[ "$passed" -eq 1 ]] && echo 0 || echo 1)
  fi

  ui_info "自检结果：$([[ "$passed" -eq 1 ]] && echo 通过 || echo 失败)"
  local result name exit_code
  for result in "${results[@]}"; do
    name="${result%%|*}"
    local rest="${result#*|}"
    exit_code="${rest%%|*}"
    ui_info "  - $(get_self_test_check_display_name "$name")：$([[ "$exit_code" -eq 0 ]] && echo 通过 || echo 失败)"
  done

  return $([[ "$passed" -eq 1 ]] && echo 0 || echo 1)
}

main() {
  local system arch

  ui_progress "$ACTION" '正在收集运行环境信息' 5
  system="$(detect_system)"
  if [[ "$system" == "unsupported" ]]; then
    echo "错误：暂不支持当前系统。" >&2
    exit 1
  fi

  CURRENT_SYSTEM="$system"
  arch="$(normalize_architecture)"
  ui_progress "$ACTION" '正在检测当前安装状态' 15
  build_state "$system"

  if [[ "$ACTION" == "self-test" ]]; then
    ui_progress "$ACTION" '正在执行脚本自检' 40
    run_self_test "$system" "$arch"
    ui_progress_done "$ACTION"
    exit $?
  fi

  if [[ "$ACTION" == "doctor" ]]; then
    ui_progress "$ACTION" '正在分析环境并生成诊断结果' 45
    RESOLVED_METHOD="$(resolve_method "$system" "$METHOD" "$ACTION")"
    print_doctor "$system" "$arch" "$RESOLVED_METHOD"
    if [[ "$FIX" -eq 1 ]]; then
      ui_progress "$ACTION" '正在执行低风险修复' 75
      run_doctor_fix "$system" "$arch"
    fi
    ui_progress_done "$ACTION"
    exit 0
  fi

  if [[ "$ACTION" == "migrate" ]]; then
    local source_method target_method target_already_installed
    local step_commands=()

    ui_progress "$ACTION" '正在解析迁移来源和目标' 30
    source_method="$(resolve_migration_source_method "$system" "$FROM_METHOD")"
    target_method="$(resolve_migration_target_method "$system" "$METHOD" "$source_method")"
    target_already_installed=0
    if method_installed "$target_method"; then
      target_already_installed=1
    fi

    if [[ "$target_already_installed" -eq 0 ]]; then
      build_plan_for install "$target_method"
      local migrate_install_note="$BUILT_PLAN_NOTE"
      local migrate_install_command="$BUILT_PLAN_COMMAND"
      step_commands+=("$migrate_install_command")
    fi

    build_plan_for uninstall "$source_method"
    local migrate_remove_note="$BUILT_PLAN_NOTE"
    local migrate_remove_command="$BUILT_PLAN_COMMAND"
    step_commands+=("$migrate_remove_command")

    ui_progress "$ACTION" '正在生成迁移计划' 45
    print_migration_plan "$system" "$arch" "$source_method" "$target_method" "$target_already_installed" "${step_commands[@]}"

    if [[ "$DRY_RUN" -eq 1 ]]; then
      if [[ "$JSON" -ne 1 ]]; then
        ui_info "当前为预演模式，没有执行任何实际变更。"
      fi
      ui_progress_done "$ACTION"
      exit 0
    fi

    confirm_or_exit "即将把 Claude Code 从 $source_method 迁移到 $target_method，是否继续？"
    ui_progress "$ACTION" '正在执行迁移步骤' 70

    if [[ "$target_already_installed" -eq 0 ]]; then
      bash -lc "$migrate_install_command"
      build_state "$system"
      if ! method_installed "$target_method"; then
        echo "错误：迁移已中止，因为安装完成后没有检测到目标安装方式 $target_method。" >&2
        exit 1
      fi
    fi

    bash -lc "$migrate_remove_command"

    if [[ "$SKIP_VERIFY" -eq 1 ]]; then
      ui_success "迁移已完成，已按要求跳过校验。"
      show_remaining_install_hint
      ui_progress_done "$ACTION"
      exit 0
    fi

    ui_progress "$ACTION" '正在校验迁移结果' 90
    build_state "$system"
    if ! method_installed "$target_method"; then
      echo "错误：迁移已完成，但后续没有检测到目标安装方式 $target_method。" >&2
      exit 1
    fi

    local version_output
    version_output="$(verify_install)"
    if [[ -n "$version_output" ]]; then
      ui_success "迁移成功，当前版本：$version_output"
    else
      ui_success "迁移成功。"
    fi
    show_remaining_install_hint
    ui_progress_done "$ACTION"
    exit 0
  fi

  ui_progress "$ACTION" '正在解析安装方式与执行计划' 35
  RESOLVED_METHOD="$(resolve_method "$system" "$METHOD" "$ACTION")"

  if [[ "$ACTION" != "status" ]]; then
    build_plan
  fi

  print_status "$system" "$arch" "$RESOLVED_METHOD"

  if [[ "$ACTION" == "status" ]]; then
    ui_progress_done "$ACTION"
    exit 0
  fi

  if [[ "$ACTION" == "install" && ( ${#STATE_DETECTED_METHODS[@]} -gt 0 || ${#STATE_CLAUDE_PATHS[@]} -gt 0 ) && "$FORCE" -ne 1 ]]; then
    if [[ "$JSON" -ne 1 ]]; then
      ui_info "Claude Code 看起来已经安装。如需重新安装，请带上 --force。"
    fi
    ui_progress_done "$ACTION"
    exit 0
  fi

  if [[ "$ACTION" != "install" ]] && ! method_installed "$RESOLVED_METHOD"; then
    echo "错误：当前机器上未检测到 $RESOLVED_METHOD 安装。" >&2
    exit 1
  fi

  if [[ "$JSON" -eq 1 && "$DRY_RUN" -eq 1 ]]; then
    exit 0
  fi

  ui_info "执行说明：$PLAN_NOTE"
  ui_info "执行命令：$PLAN_COMMAND"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    ui_info "当前为预演模式，没有执行任何实际变更。"
    ui_progress_done "$ACTION"
    exit 0
  fi

  case "$ACTION" in
    install) confirm_or_exit "即将安装或重新安装 Claude Code，是否继续？" ;;
    update) confirm_or_exit "即将更新 Claude Code，是否继续？" ;;
    uninstall) confirm_or_exit "即将卸载 Claude Code，是否继续？" ;;
  esac

  ui_progress "$ACTION" '正在执行计划命令' 70
  bash -lc "$PLAN_COMMAND"

  if [[ "$ACTION" == "uninstall" ]]; then
    show_remaining_install_hint
    ui_progress_done "$ACTION"
    exit 0
  fi

  if [[ "$SKIP_VERIFY" -eq 1 ]]; then
    ui_success "$(get_action_display_name "$ACTION")已完成，已按要求跳过校验。"
    ui_progress_done "$ACTION"
    exit 0
  fi

  ui_progress "$ACTION" '正在校验执行结果' 90
  build_state "$system"
  local version_output
  version_output="$(verify_install)"
  if [[ -n "$version_output" ]]; then
    ui_success "$(get_action_display_name "$ACTION")成功，当前版本：$version_output"
  else
    ui_success "$(get_action_display_name "$ACTION")成功。"
  fi

  ui_progress_done "$ACTION"
}

PLAN_NOTE=""
PLAN_COMMAND=""
BUILT_PLAN_NOTE=""
BUILT_PLAN_COMMAND=""
RESOLVED_METHOD=""
STATE_DETECTED_METHODS=()
STATE_WARNINGS=()
STATE_CLAUDE_PATHS=()
CURRENT_SYSTEM=""
STATE_NATIVE_PATH=""
STATE_NATIVE_SHARE_PATH=""
STATE_LEGACY_LOCAL_PATH=""
STATE_NATIVE_INSTALLED=0
STATE_NPM_INSTALLED=0
STATE_HOMEBREW_CASK=""
STATE_APT_INSTALLED=0
STATE_DNF_INSTALLED=0
STATE_APK_INSTALLED=0

main
