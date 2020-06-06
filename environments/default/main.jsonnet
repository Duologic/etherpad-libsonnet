local etherpad = import 'etherpad/etherpad.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';
local mysql = import 'mysql/main.libsonnet';

{
  local container = k.core.v1.container,

  mysql: mysql.new(
           name='mysql',
           dbName='etherpad',
           username='etherpad',
           password='etherpad',
           rootPassword='etherpad'
         )
         + {
           local _containers = super.statefulset.spec.template.spec.containers,
           statefulset+: {
             spec+: {
               template+: {
                 spec+: {
                   containers: [
                     _container + container.withArgsMixin([
                       '--character-set-server=utf8mb4',
                       '--collation-server=utf8mb4_unicode_ci',
                     ])
                     for _container in _containers
                   ],
                 },
               },
             },
           },
         },

  local secret = k.core.v1.secret,
  local envFrom = container.envFromType,

  etherpad_db_secret: secret.new('etherpad-db', {
    DB_TYPE: std.base64('mysql'),
    DB_HOST: std.base64('mysql.default.svc.cluster.local'),
    DB_PORT: std.base64('3306'),
    DB_NAME: std.base64('etherpad'),
    DB_USER: std.base64('etherpad'),
    DB_PASS: std.base64('etherpad'),
    DB_CHARSET: std.base64('utf8mb4'),
  }),

  etherpad: etherpad {
    _config+:: {
      etherpad+: {
        name: 'play',
      },
    },
    container+::
      container.withEnvFrom(
        envFrom.new() +
        envFrom.mixin.secretRef.withName($.etherpad_db_secret.metadata.name),
      ),
  },

  local ingress = k.extensions.v1beta1.ingress,
  ingress: ingress.new() +
           ingress.mixin.metadata.withName('ingress')
           + ingress.mixin.metadata.withAnnotationsMixin({
             'ingress.kubernetes.io/ssl-redirect': 'false',
           })
           + ingress.mixin.spec.withRules([
             ingress.mixin.specType.rulesType.mixin.http.withPaths(
               ingress.mixin.spec.rulesType.mixin.httpType.pathsType.withPath('/') +
               ingress.mixin.specType.mixin.backend.withServiceName('etherpad-play') +
               ingress.mixin.specType.mixin.backend.withServicePort(9001)
             ),
           ]),

}
