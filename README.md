# Etherpad jsonnet library

Jsonnet library for https://etherpad.org/

## Usage

Install it with jsonnet-bundler:

```console
jb install https://github.com/Duologic/etherpad-libsonnet`
```

Import into your jsonnet:

```jsonnet
local etherpad = import 'github.com/Duologic/etherpad-libsonnet/main.libsonnet';

{
  etherpad:
    etherpad.new('etherpad-play')
    + etherpad.withDatabaseSecret(
      db_user='etherpad',
      db_pass='supersecretpassword',
      db_host='mysql.default.svc.cluster.local',
    ),
}
```
