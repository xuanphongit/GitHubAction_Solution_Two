#!/bin/bash
set -e

ENVIRONMENT=$1
KEYVAULT_NAME=$2
WEB_CONFIG_PATH=$3
SECRETS_ENV_PATH=$4

echo "Running replacement script..."
echo "Environment: $ENVIRONMENT"
echo "KeyVault: $KEYVAULT_NAME"
echo "Web Config Path: $WEB_CONFIG_PATH"
echo "Secrets ENV Path: $SECRETS_ENV_PATH"

# 1. Load secrets.env if it exists
if [ -f "$SECRETS_ENV_PATH" ]; then
  echo "Loading secrets from $SECRETS_ENV_PATH..."
  cat "$SECRETS_ENV_PATH"
  set -o allexport
  source "$SECRETS_ENV_PATH"
  set +o allexport
else
  echo "Secrets env file $SECRETS_ENV_PATH not found. Continuing without preloaded secrets."
fi

# 2. Scan web.config for placeholders
echo "Scanning $WEB_CONFIG_PATH for placeholders..."
cat "$WEB_CONFIG_PATH"
placeholders=$(grep -o '#{[^}]\+}#' "$WEB_CONFIG_PATH" | sort | uniq)

if [ -z "$placeholders" ]; then
  echo "No placeholders found in web.config. Exiting."
  exit 0
fi

echo "Found placeholders:"
echo "$placeholders"

# 3. Replace each placeholder
for placeholder in $placeholders; do
  echo "replace for $placeholders"
  key=$(echo "$placeholder" | sed -e 's/^#{//' -e 's/}#$//')
  echo "Key: $key"
  echo "Processing placeholder: $placeholder (key: $key)"

  if [ "$key" == "Environment" ]; then
    value="$ENVIRONMENT"
    echo "Value for Environment: $value"
  else
    # Check env first
    value=$(printenv "$key")
    echo "Value from environment for $key: $value"

    # If env not found, check secrets.env
    if [ -z "$value" ]; then
      value=$(eval "echo \${$key}")
      echo "Value from secrets.env for $key: $value"
    fi

    if [ -z "$value" ]; then
      echo "Warning: '$key' not found in environment variables or secrets.env. Skipping replace."
      continue
    fi
  fi

  escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
  echo "Replacing $placeholder with $value"
  sed -i "s|$placeholder|$escaped_value|g" "$WEB_CONFIG_PATH"
done

echo "Replacement done. Final $WEB_CONFIG_PATH content:"
cat "$WEB_CONFIG_PATH"