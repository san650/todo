# todo

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

## Configuration options

Supported environment variables

`TODO_FILE` - database file to use
`TODO_FILTER` - default filter, e.g. `TODO_FILTER=PR-810 todo`

## License

`todo` is licensed under the MIT license.

See [LICENSE](./LICENSE) for the full license text.
