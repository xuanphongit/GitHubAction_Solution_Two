#!/bin/bash
set -e

# Step 1: Check required arguments
if [ $# -ne 4 ]; then
  echo "⚠️ Error: Missing arguments. Usage:"
  echo "Usage: ./replace.sh <ENVIRONMENT> <KEYVAULT_NAME> <WEB_CONFIG_PATH> <SECRETS_ENV_PATH>"
  exit 1
fi

ENVIRONMENT=$1
KEYVAULT_NAME=$2
WEB_CONFIG_PATH=$3
SECRETS_ENV_PATH=$4

# Step 2: Validate input paths
if [ ! -f "$WEB_CONFIG_PATH" ]; then
  echo "⚠️ Error: web.config file '$WEB_CONFIG_PATH' not found. Exiting."
  exit 1
fi


echo "🔵 Running replacement script..."
echo "Environment: $ENVIRONMENT"
echo "KeyVault: $KEYVAULT_NAME"
echo "Web Config Path: $WEB_CONFIG_PATH"
echo "Secrets ENV Path: $SECRETS_ENV_PATH"

# Step 3: Load secrets.env if it exists
echo "🟡 Loading secrets from $SECRETS_ENV_PATH..."
cat "$SECRETS_ENV_PATH"
set -o allexport
source "$SECRETS_ENV_PATH"
set +o allexport

# Step 4: Scan web.config for placeholders
echo "🟡 Scanning $WEB_CONFIG_PATH for placeholders..."
cat "$WEB_CONFIG_PATH"

placeholders=$(grep -o '#{[^}]\+}#' "$WEB_CONFIG_PATH" | sort | uniq || true)

if [ -z "$placeholders" ]; then
  echo "✅ No placeholders found in web.config. Exiting."
  exit 0
fi

echo "🟢 Found placeholders:"
echo "$placeholders"

# Step 5: Replace each placeholder
for placeholder in $placeholders; do
  echo "------------------------------------------"
  echo "🔵 Processing placeholder: $placeholder"
  key=$(echo "$placeholder" | sed -e 's/^#{//' -e 's/}#$//')
  echo "Key extracted: $key"

  value=""

  if [ "$key" = "Environment" ]; then
    value="$ENVIRONMENT"
    echo "Value for Environment: $value"
  else
    # Check env first
    value=$(printenv "$key")
    if [ -n "$value" ]; then
      echo "✅ Found value in environment for $key: $value"
    else
      # If not in env, check secrets.env
      value=$(eval "echo \${$key}")
      if [ -n "$value" ]; then
        echo "✅ Found value in secrets.env for $key: $value"
      else
        echo "⚠️ Warning: '$key' not found in environment variables or secrets.env. Skipping replace."
        continue
      fi
    fi
  fi

  # Escape value before replacing (to avoid sed errors)
  escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
  echo "🔵 Replacing $placeholder with $value"

  sed -i "s|$placeholder|$escaped_value|g" "$WEB_CONFIG_PATH"
done

echo "✅ Replacement done. Final $WEB_CONFIG_PATH content:"
cat "$WEB_CONFIG_PATH"
