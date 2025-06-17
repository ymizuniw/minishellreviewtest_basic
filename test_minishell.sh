#!/bin/bash

MINISHELL=./minishell  # あなたのminishellの実行ファイルパス
LOG_BASH=bash_output.log
LOG_MINI=mini_output.log
TEST_DIR=test_outputs
mkdir -p "$TEST_DIR"

# テストコマンドリスト
TESTS=(
  'echo hello world'
  'pwd'
  'ls'
  'echo $HOME'
  'echo "$HOME"'
  'echo '\''$HOME'\'''
  'cd .. && pwd'
  'export TESTVAR=abc && echo $TESTVAR'
  'unset TESTVAR && echo $TESTVAR'
  'echo $?'
  'ls | wc -l'
  'cat < /etc/passwd | grep root | wc -l'
  'echo hello > test_file && cat test_file'
  'echo hi >> test_file && cat test_file'
  'cat << EOF\nhello\nEOF'
  'exit'
)

# 1テストずつ実行
i=1
for cmd in "${TESTS[@]}"; do
  echo "===== Test $i ====="

  # Bash側出力
  echo -e "$cmd" | bash > "$TEST_DIR/$i.bash" 2>&1

  # Minishell側出力
  echo -e "$cmd" | $MINISHELL > "$TEST_DIR/$i.mini" 2>&1

  # 差分表示
  echo "--- CMD: $cmd"
  diff -u "$TEST_DIR/$i.bash" "$TEST_DIR/$i.mini" > "$TEST_DIR/$i.diff"
  if [ $? -eq 0 ]; then
    echo "✅ Passed"
  else
    echo "❌ Output differs. See: $TEST_DIR/$i.diff"
  fi

  ((i++))
done

echo "すべてのテストが終了しました。"
