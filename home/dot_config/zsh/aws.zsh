_AWS_VARS=(AWS_PROFILE AWS_DEFAULT_PROFILE AWS_REGION AWS_DEFAULT_REGION
  AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
  AWS_SESSION_EXPIRATION AWS_CREDENTIAL_EXPIRATION AWS_VAULT)

_AWS_REGIONS=(us-east-1 us-east-2 us-west-1 us-west-2 ca-central-1
  eu-west-1 eu-west-2 eu-west-3 eu-central-1 eu-north-1
  ap-south-1 ap-southeast-1 ap-southeast-2 ap-northeast-1 ap-northeast-2
  sa-east-1)

_AWS_REGION_PATTERN='^[a-z]{2}(-[a-z]+)+-[0-9]+$'

_AWS_AWK_BLOCK_MATCH='($0=="[profile " p "]" || $0=="[" p "]")'

_aws_profiles() {
  local cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  local cred="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
  awk -v cf="$cred" '
    FNR==1 { incred = (FILENAME == cf) }
    /^[[:space:]]*\[/ {
      s=$0; sub(/^[[:space:]]*\[[[:space:]]*/, "", s); sub(/[[:space:]]*\].*$/, "", s)
      if (incred || s == "default") print s
      else if (s ~ /^profile[[:space:]]+/) { sub(/^profile[[:space:]]+/, "", s); print s }
    }' "$cfg" "$cred" 2>/dev/null | awk '!seen[$0]++'
}

_aws_profile_known() {
  local want="$1" p
  while IFS= read -r p; do
    [[ "$p" == "$want" ]] && return 0
  done < <(_aws_profiles)
  return 1
}

_aws_profile_is_sso() {
  local profile="$1"
  local cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  [[ -f "$cfg" ]] || return 1
  awk -v p="$profile" "${_AWS_AWK_BLOCK_MATCH} {f=1; next} /^\[/ {f=0} f && /^[[:space:]]*(sso_session|sso_start_url)[[:space:]]*=/{ s=1 } END{ exit s?0:1 }" "$cfg"
}

_aws_valid_region() {
  [[ "$1" =~ $_AWS_REGION_PATTERN ]]
}

awsu() {
  unset "${_AWS_VARS[@]}"
  echo "AWS env cleared"
}

awsp() {
  local profile="$1" region="$2"

  if [[ -z "$profile" ]]; then
    local cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
    local preview="awk -v p={} '${_AWS_AWK_BLOCK_MATCH} {f=1; print; next} /^\[/ {f=0} f' ${(q)cfg}"
    profile=$(_aws_profiles | fzf --prompt='AWS profile> ' --height=40% --reverse \
      --preview "$preview" --preview-window=right,60%)
  fi
  [[ -z "$profile" ]] && return 1

  if ! _aws_profile_known "$profile"; then
    print -u2 "awsp: unknown profile '$profile'"
    return 1
  fi

  if [[ -n "$region" ]] && ! _aws_valid_region "$region"; then
    print -u2 "awsp: invalid region '$region'"
    return 1
  fi

  if _aws_profile_is_sso "$profile"; then
    if ! aws sts get-caller-identity --profile "$profile" >/dev/null 2>&1; then
      print "SSO session expired, logging in..."
      aws sso login --profile "$profile" || return 1
    fi
  fi

  unset "${_AWS_VARS[@]}"
  export AWS_PROFILE="$profile"
  if [[ -n "$region" ]]; then
    export AWS_REGION="$region" AWS_DEFAULT_REGION="$region"
  fi

  echo "→ $AWS_PROFILE${AWS_REGION:+ ($AWS_REGION)}"
}

awsr() {
  local region="$1"
  if [[ -z "$region" ]]; then
    region=$(printf '%s\n' "${_AWS_REGIONS[@]}" |
      fzf --prompt='AWS region> ' --height=40% --reverse)
  fi
  [[ -z "$region" ]] && return 1
  if ! _aws_valid_region "$region"; then
    print -u2 "awsr: invalid region '$region'"
    return 1
  fi
  export AWS_REGION="$region" AWS_DEFAULT_REGION="$region"
  echo "→ region $AWS_REGION"
}

awsw() {
  echo "profile: ${AWS_PROFILE:-<none>}"
  echo "region:  ${AWS_REGION:-$(aws configure get region 2>/dev/null)}"
  aws sts get-caller-identity --query '[Account, Arn]' --output text 2>/dev/null ||
    echo "not authenticated"
}

_awsp() {
  local -a profiles=("${(@f)$(_aws_profiles)}")
  _arguments '1:profile:compadd -a profiles' '2:region:compadd -a _AWS_REGIONS'
}

_awsr() {
  _arguments '1:region:compadd -a _AWS_REGIONS'
}

if (( $+functions[compdef] )); then
  compdef _awsp awsp
  compdef _awsr awsr
fi
