#!/usr/bin/env bash

# TAP = Test Anything Protocol http://testanything.org/

STATUS_EXIT=0
TMP=$(mktemp -d -t todo-test-XXXXXXX)
TODO="./bin/todo"
TEST_COUNTER=0
CURRENT_TEST=
CURRENT_EXPECTED_OUTPUT=
CURRENT_ACTUAL_OUTPUT=

function plan {
  # Count the numbers of `spec` calls in the file
  local TOTAL=$(grep --count "^spec " "$0")

  echo "1..${TOTAL}"
}

function todo {
  TODO_PATH="$TMP" $TODO $@
}

function cleanup {
  rm -rf $TMP
}

trap cleanup EXIT

function tap_ok()
{
  echo "ok $TEST_COUNTER $1"
}

function tap_not_ok()
{
  echo "not ok $TEST_COUNTER $1"

  # print diagnostics
  echo "#      EXPECTED:"
  echo "$2" | sed 's/^/#      /'
  echo "#"
  echo "#      ACTUAL:"
  echo "$3" | sed 's/^/#      /'

  STATUS_EXIT=1
}

function finish()
{
  exit $STATUS_EXIT
}

function spec {
  ((TEST_COUNTER++))

  TMP=$(mktemp -d -t todo-test-XXXXXXX)
  CURRENT_TEST="$1"
  CURRENT_EXPECTED_OUTPUT="$TMP/test-$TEST_COUNTER-expected-output"
  CURRENT_ACTUAL_OUTPUT="$TMP/test-$TEST_COUNTER-actual-output"
}

function expect {
  local TEST=()

  while read -r line; do
    TEST+="$line;"
  done

  eval ${TEST[@]} > $CURRENT_ACTUAL_OUTPUT
}

function to_output {
  local TEST_EXPECTED=$(cat)
  local TEST_ACTUAL=$(cat $CURRENT_ACTUAL_OUTPUT)

  if [ "$TEST_EXPECTED" == "$TEST_ACTUAL" ]; then
    tap_ok "$CURRENT_TEST"
  else
    tap_not_ok "$CURRENT_TEST" "$TEST_EXPECTED" "$TEST_ACTUAL"
  fi
}

plan

spec "empty todo list"
expect << EOT
todo
EOT
to_output <<EOT

# Project: default ~

EOT

spec "add one todo item"
expect << EOT
todo add foo
todo
EOT
to_output << EOT

# Project: default ~

     1	- [ ] foo
EOT

spec "add multiple items"
expect << EOT
todo add foo
todo add bar
todo add baz
todo
EOT
to_output << EOT

# Project: default ~

     1	- [ ] foo
     2	- [ ] bar
     3	- [ ] baz
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

# Project: default ~

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

# Project: default ~

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

# Project: default ~

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

# Project: default ~
# Filtering by: ba

     2	- [ ] bar
     3	- [ ] baz
EOT

spec "filter returns error when no param"
expect << EOT
todo filter
EOT
to_output << EOT
ERROR: expected filter param
e.g. todo filter foo
EOT

spec "filters to do list with TODO_FILTER env var"
expect << EOT
todo add foo
todo add bar
todo add baz
TODO_FILTER=ba todo
EOT
to_output << EOT

# Project: default ~
# Filtering by: ba

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

# Project: default ~

     1	- [ ] foo
     2	- [ ] qux
     3	- [ ] baz
EOT

finish
