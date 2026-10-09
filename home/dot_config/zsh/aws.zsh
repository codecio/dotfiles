# aws.sh: AWS profile/region switching with fzf (works in zsh and bash)
# Add to ~/.zshrc or ~/.bashrc:   source ~/dotfiles/aws.sh
# Created using Anthropic Claude. Review before relying on it.
#
#   awsp [profile] [region]  pick/switch profile (fzf if no arg), SSO login if needed
#   awsr [region]            pick/switch region (fzf if no arg)
#   awsu                     clear all AWS env vars
#   awsw                     show current profile, region, account, ARN

_AWS_VARS=(AWS_PROFILE AWS_DEFAULT_PROFILE AWS_REGION AWS_DEFAULT_REGION
  AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  AWS_SESSION_EXPIRATION AWS_CREDENTIAL_EXPIRATION AWS_VAULT)

_AWS_REGIONS=(us-east-1 us-east-2 us-west-1 us-west-2 ca-central-1
  eu-west-1 eu-west-2 eu-west-3 eu-central-1 eu-north-1
  ap-south-1 ap-southeast-1 ap-southeast-2 ap-northeast-1 ap-northeast-2
  sa-east-1)

# Clear every AWS env var
awsu() {
  unset "${_AWS_VARS[@]}"
  echo "AWS env cleared"
}

# Switch profile
awsp() {
  local profile="$1" region="$2"

  if [ -z "$profile" ]; then
    # Preview shows the profile's block from ~/.aws/config
    local preview='awk -v p={} '\''$0=="[profile " p "]" || $0=="[" p "]" {f=1; print; next} /^\[/ {f=0} f'\'' ~/.aws/config'
    profile=$(aws configure list-profiles 2>/dev/null |
      fzf --prompt='AWS profile> ' --height=40% --reverse \
          --preview "$preview" --preview-window=right,60%)
  fi
  [ -z "$profile" ] && return 1

  unset "${_AWS_VARS[@]}"
  export AWS_PROFILE="$profile"
  [ -n "$region" ] && export AWS_REGION="$region" AWS_DEFAULT_REGION="$region"

  # If it's an SSO profile and the session is expired, log in
  if aws configure get sso_session >/dev/null 2>&1 ||
     aws configure get sso_start_url >/dev/null 2>&1; then
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
      echo "SSO session expired, logging in..."
      aws sso login || return 1
    fi
  fi

  echo "→ $AWS_PROFILE${AWS_REGION:+ ($AWS_REGION)}"
}

# Switch region
awsr() {
  local region="$1"
  if [ -z "$region" ]; then
    region=$(printf '%s\n' "${_AWS_REGIONS[@]}" |
      fzf --prompt='AWS region> ' --height=40% --reverse)
  fi
  [ -z "$region" ] && return 1
  export AWS_REGION="$region" AWS_DEFAULT_REGION="$region"
  echo "→ region $AWS_REGION"
}

# Who am I
awsw() {
  echo "profile: ${AWS_PROFILE:-<none>}"
  echo "region:  ${AWS_REGION:-$(aws configure get region 2>/dev/null)}"
  aws sts get-caller-identity --query '[Account, Arn]' --output text 2>/dev/null ||
    echo "not authenticated"
}

# Tab completion
if [ -n "$ZSH_VERSION" ]; then
  _awsp() { compadd -- $(aws configure list-profiles 2>/dev/null); }
  _awsr() { compadd -- "${_AWS_REGIONS[@]}"; }
  if (( $+functions[compdef] )); then
    compdef _awsp awsp
    compdef _awsr awsr
  fi
elif [ -n "$BASH_VERSION" ]; then
  _awsp() { COMPREPLY=($(compgen -W "$(aws configure list-profiles 2>/dev/null)" -- "${COMP_WORDS[COMP_CWORD]}")); }
  complete -F _awsp awsp
  complete -W "${_AWS_REGIONS[*]}" awsr
fi
