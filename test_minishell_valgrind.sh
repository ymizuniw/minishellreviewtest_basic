#!/bin/bash

# ==== 設定セクション ====
MINISHELL=./minishell
TEST_DIR=test_outputs
VALGRIND_LOG=valgrind.log
mkdir -p "$TEST_DIR"

# ==== テストコマンド一覧 ====
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
)

# ==== テストループ ====
i=1
for cmd in "${TESTS[@]}"; do
  echo "===== Test $i ====="

  # 入力内容を一時ファイルに保存
  INPUT_FILE="$TEST_DIR/$i.input"
  echo -e "$cmd" > "$INPUT_FILE"

  # 通常実行
  echo "--- CMD: $cmd"
  cat "$INPUT_FILE" | bash > "$TEST_DIR/$i.bash" 2>&1
  cat "$INPUT_FILE" | $MINISHELL > "$TEST_DIR/$i.mini" 2>&1

  # 差分検出
  diff -u "$TEST_DIR/$i.bash" "$TEST_DIR/$i.mini" > "$TEST_DIR/$i.diff"
  if [ $? -eq 0 ]; then
    echo "✅ Output: Passed"
  else
    echo "❌ Output: Differs (see $TEST_DIR/$i.diff)"
  fi

  # Valgrindによるリークチェック
  cat "$INPUT_FILE" | valgrind --leak-check=full --errors-for-leak-kinds=all \
    --quiet --log-file="$TEST_DIR/$i.valgrind" $MINISHELL > /dev/null 2>&1

  if grep -q "definitely lost: 0 bytes" "$TEST_DIR/$i.valgrind"; then
    echo "✅ Valgrind: No leaks"
  else
    echo "❌ Valgrind: Leak detected (see $TEST_DIR/$i.valgrind)"
  fi

  ((i++))
done

# 最後にtest_fileを削除
rm -f test_file

echo "🎯 全テスト・リークチェック完了: $TEST_DIR に結果保存済み"
