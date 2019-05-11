#!/usr/bin/env bash

PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${PWD}/deps/bashtap/bashtap.bash"

TODO="$(pwd)/bin/todo"
TODO_DB_PATH=
TODO_PROJECT=
TODO_FILTER=

function before_test {
  TODO_DB_PATH=$(mktemp -d -t todo-test-XXXXXXX)
  TODO_PROJECT=
  TODO_FILTER=
}

function todo {
  TODO_PATH="$TODO_DB_PATH" $TODO $@
}

function cleanup {
  rm -rf "$TODO_DB_PATH"
}

trap cleanup EXIT

plan

spec "empty todo list"
expect << EOT
before_test
todo
EOT
to_output << EOT

# Project: default ~

EOT

spec "add command: adds one todo item"
expect << EOT
before_test
todo add foo
todo
EOT
to_output << EOT

# Project: default ~

     1	- [ ] foo
EOT

spec "add command: adds multiple items"
expect << EOT
before_test
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
before_test
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
before_test
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
before_test
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
before_test
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
before_test
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
before_test
todo filter
EOT
to_output << EOT
ERROR: expected filter param
e.g. todo filter foo
EOT

spec "TODO_FILTER env var: filters to do list "
expect << EOT
before_test
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
before_test
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
before_test
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
before_test
TODO_PROJECT=alternate-project todo add bar
todo delete alternate-project
todo projects
EOT
to_output << EOT
default
EOT

spec "delete command: deletes a project doesn't fail if project doesn't exist"
expect << EOT
before_test
todo delete alternate-project
todo projects
EOT
to_output << EOT
default
EOT

spec "--branch modifier: shows To Do items for current branch"
REPO=$(mktemp -d -t project-XXXXXXX)
expect << EOT
before_test
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
before_test
TODO_PROJECT=foo todo
[ -f "$TODO_DB_PATH/foo" ] && echo "file exist"
EOT
to_output << EOT

# Project: foo ~
EOT

spec "pending command: shows pending To Do items"
expect << EOT
before_test
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
before_test
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
