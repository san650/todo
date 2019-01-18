#!/usr/bin/env bash

# TAP = Test Anything Protocol http://testanything.org/

TEST_INDEX="$1"
STATUS_EXIT=0
TODO_DB_PATH=
TMP_OUTPUT=
TODO="$(pwd)/bin/todo"
TEST_COUNTER=0
CURRENT_TEST=
EXPECTED_OUTPUT=
ACTUAL_OUTPUT_FILE_FILE=

function plan {
  # Count the numbers of `spec` calls in the file
  local TOTAL=$(grep --count "^spec " "$0")

  if [ -n "$TEST_INDEX" ]; then
    TOTAL=1
  fi

  echo "1..${TOTAL}"
}

function todo {
  TODO_PATH="$TODO_DB_PATH" $TODO $@
}

function cleanup {
  rm -rf "$TODO_DB_PATH"
  rm -rf "$TMP_OUTPUT"
}

trap cleanup EXIT

function tap_ok()
{
  echo "ok $1 $2"
}

function tap_not_ok()
{
  echo "not ok $1 $2"

  # print diagnostics
  echo "#      EXPECTED:"
  echo "$3" | sed 's/^/#      /'
  echo "#"
  echo "#      ACTUAL:"
  echo "$4" | sed 's/^/#      /'

  STATUS_EXIT=1
}

function finish()
{
  exit $STATUS_EXIT
}

function spec {
  ((TEST_COUNTER++))

  # If test index is set, skipt the test if it's not the right index
  # This allows to run one test at a time: `./test.sh 3`
  if [ -n "$TEST_INDEX" -a "$TEST_INDEX" != "$TEST_COUNTER" ]; then
    return
  fi

  TODO_DB_PATH=$(mktemp -d -t todo-test-XXXXXXX)
  TMP_OUTPUT="$(mktemp -d -t todo-test-output-XXXXXXX)/output"
  CURRENT_TEST="$1"
  EXPECTED_OUTPUT="$TODO_DB_PATH/test-$TEST_COUNTER-expected-output"
  ACTUAL_OUTPUT_FILE_FILE="$TMP_OUTPUT/test-$TEST_COUNTER-actual-output"
  mkdir -p "$TMP_OUTPUT"
}

function expect {
  local TEST=$(cat)

  # If test index is set, skipt the test if it's not the right index
  # This allows to run one test at a time: `./test.sh 3`
  if [ -n "$TEST_INDEX" -a "$TEST_INDEX" != "$TEST_COUNTER" ]; then
    return
  fi

  # Cleanup all variables before running a test
  TODO_PATH=
  TODO_PROJECT=
  TODO_FILTER=

  eval "$TEST" 2>&1 > $ACTUAL_OUTPUT_FILE_FILE
}

function to_output {
  local EXPECTED=$(cat)
  local ACTUAL=$(cat $ACTUAL_OUTPUT_FILE_FILE)
  local NUMBER=${TEST_COUNTER}

  # If test index is set, skipt the test if it's not the right index
  # This allows to run one test at a time: `./test.sh 3`
  if [ -n "$TEST_INDEX" ]; then
    if [ "$TEST_INDEX" != "$TEST_COUNTER" ]; then
      return
    fi

    # if test index is defined, only one test is going to run
    NUMBER=1
  fi

  if [ "$EXPECTED" == "$ACTUAL" ]; then
    tap_ok "$NUMBER" "$CURRENT_TEST"
  else
    tap_not_ok "$NUMBER" "$CURRENT_TEST" "$EXPECTED" "$ACTUAL"
  fi
}

plan

spec "empty todo list"
expect << EOT
todo
EOT
to_output << EOT

# Project: default ~

EOT

spec "add command: adds one todo item"
expect << EOT
todo add foo
todo
EOT
to_output << EOT

# Project: default ~

     1	- [ ] foo
EOT

spec "add command: adds multiple items"
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

spec "done command: can mark a todo as done"
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

spec "undone command: can undone a todo"
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

spec "all command: shows all todos"
expect << EOT
todo add foo
todo add bar
todo add baz
todo done 2
TODO_PROJECT=my-pet-project todo add foo
TODO_PROJECT=my-pet-project todo done 1
todo all
EOT
to_output << EOT

# Project: default ~

     1	- [ ] foo
     2	- [x] bar
     3	- [ ] baz

# Project: my-pet-project ~

     1	- [x] foo

EOT

spec "all command: filter To Do items with TODO_FILTER env var"
expect << EOT
todo add foo
todo add bar
todo done 2
TODO_PROJECT=my-pet-project todo add foo
TODO_PROJECT=my-pet-project todo add bar
TODO_PROJECT=my-pet-project todo done 1
TODO_FILTER=foo todo all
EOT
to_output << EOT

# Project: default ~
# Filtering by: foo

     1	- [ ] foo

# Project: my-pet-project ~
# Filtering by: foo

     1	- [x] foo

EOT

spec "filter command: filters to do list"
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

spec "filter command: filter returns error when no param"
expect << EOT
todo filter
EOT
to_output << EOT
ERROR: expected filter param
e.g. todo filter foo
EOT

spec "TODO_FILTER env var: filters to do list "
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

spec "edit command: edits todo inline"
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

spec "TODO_PROJECT env var: uses alternate project"
expect << EOT
todo add foo
TODO_PROJECT=alternate-project todo add bar
TODO_PROJECT=alternate-project todo
EOT
to_output << EOT

# Project: alternate-project ~

     1	- [ ] bar
EOT

spec "delete command: deletes a project"
expect << EOT
TODO_PROJECT=alternate-project todo add bar
todo delete alternate-project
todo projects
EOT
to_output << EOT
default
EOT

spec "delete command: deletes a project doesn't fail if project doesn't exist"
expect << EOT
todo delete alternate-project
todo projects
EOT
to_output << EOT
default
EOT

spec "--branch modifier: shows To Do items for current branch"
REPO=$(mktemp -d -t project-XXXXXXX)
expect << EOT
cd "$REPO" && git init --quiet
cd "$REPO" && git checkout -b another-branch --quiet
cd "$REPO" && todo --branch add 'foo'
cd "$REPO" && todo --branch
cd "$REPO" && todo -b
cd "$REPO" && todo
EOT
to_output << EOT

# Project: another-branch ~

     1	- [ ] foo


# Project: another-branch ~

     1	- [ ] foo


# Project: default ~
EOT

spec "cleanup empty files from the DB"
expect << EOT
TODO_PROJECT=foo todo
[ -f "$TODO_DB_PATH/foo" ] && echo "file exist"
EOT
to_output << EOT

# Project: foo ~
EOT

spec "pending command: shows pending To Do items"
expect << EOT
todo add foo
todo add bar
todo done 2
TODO_PROJECT=my-pet-project todo add foo
TODO_PROJECT=my-pet-project todo add bar
TODO_PROJECT=my-pet-project todo done 1
todo pending
EOT
to_output << EOT

# Project: default ~

     1	- [ ] foo

# Project: my-pet-project ~

     2	- [ ] bar

EOT

spec "pending command: filter pending To Do items with TODO_FILTER env var"
expect << EOT
todo add foo
todo add bar
todo done 2
TODO_PROJECT=my-pet-project todo add foo
TODO_PROJECT=my-pet-project todo add bar
TODO_PROJECT=my-pet-project todo done 1
TODO_FILTER=foo todo pending
EOT
to_output << EOT

# Project: default ~
# Filtering by: foo

     1	- [ ] foo

# Project: my-pet-project ~
# Filtering by: foo

EOT

finish
