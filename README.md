# todo
[![Build Status](https://travis-ci.org/san650/todo.svg?branch=master)](https://travis-ci.org/san650/todo)

Simple bash to do app for keeping track of pending tasks.

## SYNOPSIS

```sh
$ todo
$ todo add 'solve rollup release'
$ todo add 'investigate if each package needs its own readme'
$ todo add 'test publishing'
$ todo

# Project: default ~

     1	- [ ] solve rollup release
     2	- [ ] investigate if each package needs its own readme
     3	- [ ] test publishing

$ todo done 2
$ todo

# Project: default ~

     1	- [ ] solve rollup release
     3	- [ ] test publishing

$
```

## Options

| Option               | Description                                               |
| -------------------- |-----------------------------------------------------------|
| (no option)          | Print pending ToDo items                                  |
| `add [message]`      | Add new ToDo item to the list                             |
| `all`                | Show all ToDo items for all projects (even the done ones) |
| `filter [keyword]`   | Filter the list of ToDo items by `keyword`                |
| `edit [n] [message]` | Change ToDo item number `n` message with `message`        |
| `done [n]`           | Mark ToDo item number `n` as done                         |
| `undone [n]`         | Mark ToDo item number `n` as pending                      |
| `projects`           | List all projects                                         |
| `delete [project]`   | Delete a project and all to do items it contains          |
| `raw`                | Prints current project file                               |
| `help`               | Show help                                                 |

## Configuration options

Supported environment variables

| Environment Variable | Description                                    |
| -------------------- | ---------------------------------------------- |
| `TODO_PATH`          | Store folder, default is ~/.todo/              |
| `TODO_FILTER`        | Default filter, e.g. `TODO_FILTER=PR-810 todo` |
| `TODO_PROJECT`       | Set project to use                             |

## Shell prompt

Adding current To Do project to bash prompt.

```sh
function __todo_project
{
  # Hackish way to check if TODO_PROJECT variable is exported
  if [ -n "$(compgen -e -X '!TODO_PROJECT')" ]; then
    echo "${TODO_PROJECT:-default}"
  else
    echo "default"
  fi
}

export PS1='[$(__todo_project)] $'
```

This will include the current project in the shell prompt

```
[default] $
[default] $ export TODO_PROJECT=my-awesome-project
[my-awesome-project] $
```

## License

`todo` is licensed under the MIT license.

See [LICENSE](./LICENSE) for the full license text.
