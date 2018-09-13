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
     1	- [ ] solve rollup release
     2	- [ ] investigate if each package needs its own readme
     3	- [ ] test publishing
$ todo done 2
$ todo
     1	- [ ] solve rollup release
     3	- [ ] test publishing
```

## Options

| Option               | Description                                        |
| -------------------- |----------------------------------------------------|
| (no option)          | Print pending ToDo items                           |
| `add [message]`      | Add new ToDo item to the list                      |
| `all`                | Show all ToDo items (even the done ones)           |
| `filter [keyword]`   | Filter the list of ToDo items by `keyword`         |
| `edit [n] [message]` | Change ToDo item number `n` message with `message` |
| `done [n]`           | Marks ToDo item number `n` as done                 |
| `undone [n]`         | Marks ToDo item number `n` as pending              |

## Configuration options

Supported environment variables

| Environment Variable | Description                                    |
| -------------------- | ---------------------------------------------- |
| `TODO_FILE`          | Database file to use, default is ~/.todo       |
| `TODO_FILTER`        | Default filter, e.g. `TODO_FILTER=PR-810 todo` |

## License

`todo` is licensed under the MIT license.

See [LICENSE](./LICENSE) for the full license text.
