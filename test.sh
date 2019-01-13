#!/usr/bin/env bash

# TAP = Test Anything Protocol http://testanything.org/

TEST_INDEX="$1"
STATUS_EXIT=0
TMP=
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
  TODO_PATH="$TMP" $TODO $@
}

function cleanup {
  rm -rf "$TMP"
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

  TMP=$(mktemp -d -t todo-test-XXXXXXX)
  TMP_OUTPUT="$(mktemp -d -t todo-test-output-XXXXXXX)/output"
  CURRENT_TEST="$1"
  EXPECTED_OUTPUT="$TMP/test-$TEST_COUNTER-expected-output"
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

spec "uses alternate project with TODO_PROJECT"
expect << EOT
todo add foo
TODO_PROJECT=alternate-project todo add bar
TODO_PROJECT=alternate-project todo
EOT
to_output << EOT

# Project: alternate-project ~

     1	- [ ] bar
EOT

spec "deletes a project"
expect << EOT
TODO_PROJECT=alternate-project todo add bar
todo delete alternate-project
todo projects
EOT
to_output << EOT
default
EOT

spec "deletes a project doesn't fail if project doesn't exist"
expect << EOT
todo delete alternate-project
todo projects
EOT
to_output << EOT
default
EOT

spec "branch command shows To Do items for current branch"
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

finish
