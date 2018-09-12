#!/usr/bin/env bash

TOTAL_TESTS=3
STATUS_EXIT=0
TMP=$(mktemp -d -t todo-test)
TODO="./bin/todo"
TEST_COUNTER=0
EXPECTED_OUTPUT_FILE="$TMP/test-expected"

function todo {
  TODO_FILE="$TMP/test-$TEST_COUNTER" $TODO $@
}

function cleanup {
  rm -rf $TMP
}

trap cleanup EXIT

function tap_ok()
{
  echo "ok $1"
}

function tap_not_ok()
{
  echo "not ok $1"

  # print diagnostics
  echo "# EXPECTED:"
  echo "#"
  echo "$2" | sed 's/^/#~~~/'

  echo "#"
  echo "# ACTUAL:"
  echo "# "
  echo "$3" | sed 's/^/#~~~/'

  STATUS_EXIT=1
}

function finish()
{
  exit $STATUS_EXIT
}



function write_expected_output {
  cat > $EXPECTED_OUTPUT_FILE
}

function do_test {
  local TEST_NAME="$1"
  local TEST=()

  TEST_COUNTER+=1

  while read -r line; do
    TEST+="$line;"
  done

  local TEST_ACTUAL=$(eval ${TEST[@]})
  local TEST_EXPECTED=$(cat $EXPECTED_OUTPUT_FILE)

  if [ "$TEST_EXPECTED" == "${TEST_ACTUAL[*]}" ]; then
    tap_ok "$TEST_NAME"
  else
    tap_not_ok "$TEST_NAME" "$TEST_EXPECTED" "$TEST_ACTUAL"
  fi
}

echo "1..${TOTAL_TESTS}"

write_expected_output << EOT
EOT
do_test "empty todo list" "" <<EOT
todo
EOT

write_expected_output << EOT
     1	- [ ] foo
EOT
do_test "add one todo item" "${EXPECTED[@]}" <<EOT
todo add foo
todo
EOT

write_expected_output << EOT
     1	- [ ] foo
     2	- [ ] bar
     3	- [ ] baz
EOT
do_test "add multiple items" << EOT
todo add foo
todo add bar
todo add baz
todo
EOT

spec "can mark a todo as done"
expect << EOT
todo add foo
todo add bar
todo add baz
todo done 2
todo
EOT
to_output << EOT
     1	- [ ] foo
     3	- [ ] baz
EOT

spec "can undone a todo"
expect << EOT
todo add foo
todo add bar
todo add baz
todo done 2
todo undone 2
todo
EOT
to_output << EOT
     1	- [ ] foo
     2	- [ ] bar
     3	- [ ] baz
EOT

spec "shows all todos"
expect << EOT
todo add foo
todo add bar
todo add baz
todo done 2
todo all
EOT
to_output << EOT
     1	- [ ] foo
     2	- [x] bar
     3	- [ ] baz
EOT

spec "filters to do list"
expect << EOT
todo add foo
todo add bar
todo add baz
todo filter ba
EOT
to_output << EOT
     2	- [ ] bar
     3	- [ ] baz
EOT

spec "filters to do list with TODO_FILTER env var"
expect << EOT
todo add foo
todo add bar
todo add baz
TODO_FILTER=ba todo filter
EOT
to_output << EOT
Filtering by: ba

     2	- [ ] bar
     3	- [ ] baz
EOT

spec "edit todo inline"
expect << EOT
todo add foo
todo add bar
todo add baz
todo edit 2 qux
todo
EOT
to_output << EOT
     1	- [ ] foo
     2	- [ ] qux
     3	- [ ] baz
EOT

finish
