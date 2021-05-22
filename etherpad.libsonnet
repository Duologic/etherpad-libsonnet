local k = (import 'ksonnet-util/kausal.libsonnet');

{

  new(
    name,
    plugins=[
      'ep_headings2',
      'ep_markdown',
    ],
    replicas=1,
    image='etherpad/etherpad:1.8.13',
  ):: {
    name:: name,

    local install_plugins = [
      'npm install %s' % plugin
      for plugin in plugins
    ],

    local container = k.core.v1.container,
    local containerPort = k.core.v1.containerPort,
    local live = container.livenessProbe,
    local ready = container.readinessProbe,
    container::
      container.new('etherpad', [image])
      + container.withCommand([
        'sh',
        '-c',
        '%s && node node_modules/ep_etherpad-lite/node/server.js' % std.join(' && ', install_plugins),
      ])
      + k.util.resourcesLimits('150m', '30Mi')
      + container.withPorts([containerPort.newNamed('http', 9001)])
      + live.httpGet.withPath('/')
      + live.httpGet.withPort('http')
      + live.withFailureThreshold(10)
      + live.withInitialDelaySeconds(30)
      + ready.httpGet.withPath('/')
      + ready.httpGet.withPort('http')
      + ready.withFailureThreshold(10)
      + ready.withInitialDelaySeconds(30)
    ,

    local deployment = k.apps.v1.deployment,
    deployment:
      deployment.new(name, replicas, [self.container]),

    service: k.util.serviceFor(self.deployment),
  },

  withDatabaseSecret(
    user,
    pass,
    host,
    port=3306,
    type='mysql',
    name='etherpad',
    charset='utf8mb4',
  ):: {
    local secret = k.core.v1.secret,
    local envVar = k.core.v1.envVar,

    db_secret:
      secret.new(super.name + '-db', {
        DB_TYPE: std.base64(type),
        DB_HOST: std.base64(host),
        DB_PORT: std.base64(std.toString(port)),
        DB_NAME: std.base64(name),
        DB_USER: std.base64(user),
        DB_PASS: std.base64(pass),
        DB_CHARSET: std.base64(charset),
      }),

    container+::
      container.withEnvMixin([
        envVar.fromSecretRef(this.db_secret.metadata.name),
      ]),
  },
}
