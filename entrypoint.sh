#!/bin/bash

INPUT_CONFIG_PATH="$1"
CONFIG=" --config-path=/gitleaks.toml"

# generate empty report file with `null` content
echo null > $GITHUB_WORKSPACE/gitleaks-output.json

# check if a custom config have been provided
if [ -f "$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH" ]; then
  CONFIG="$CONFIG --additional-config=$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH"
fi

echo running gitleaks "$(gitleaks --version) with the following command👇"

if [ "$GITHUB_EVENT_NAME" = "pull_request" ]
then 
  git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF... > commit_list.txt
  echo gitleaks detect --source=$GITHUB_WORKSPACE --verbose --redact --log-opts="--git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF..." $CONFIG
  CAPTURE_OUTPUT=$(gitleaks detect --source=$GITHUB_WORKSPACE --verbose --redact --log-opts="--git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF..." $CONFIG)
else
  echo detect --sourc=$GITHUB_WORKSPACE --verbose --report=gitleaks-output.json --redact $CONFIG
  CAPTURE_OUTPUT=$(gitleaks detect --source=$GITHUB_WORKSPACE --verbose --report=gitleaks-output.json --redact $CONFIG)
fi

if [ $? -eq 1 ]
then
  GITLEAKS_RESULT=$(echo -e "\e[31m🛑 STOP! Gitleaks encountered leaks")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::1"
  echo "----------------------------------"
  echo "$CAPTURE_OUTPUT"
  echo "::set-output name=result::$CAPTURE_OUTPUT"
  echo "----------------------------------"
  exit 1
else
  GITLEAKS_RESULT=$(echo -e "\e[32m✅ SUCCESS! Your code is good to go!")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::0"
  echo "------------------------------------"
fi
