local grafana_host = 'grafana.yc.complife.ru';
local grafana_user = 'netology';
local grafana_pass = std.extVar('grafana_pass');
local grafana_home_dashboard = '/grafana-dashboard-definitions/0/nodes/nodes.json';

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
      },
      # grafana customizations
      grafana+:: {
        config+: {
          sections+: {
            # grafana access URL
            server+: {
              root_url: 'https://' + grafana_host + '/',
            },
            # default dashboard
            dashboards+: {
              default_home_dashboard_path: grafana_home_dashboard,
            },
            # predefined credentials
            security+: {
              admin_user: grafana_user,
              admin_password: grafana_pass,
            },
          },
        },
      },
    },
    # disable network policy for grafana to access it from external internet
    grafana+: {
        networkPolicy:: {},
    },
    # ingress for grafana
    ingress+:: {
      grafana: {
          apiVersion: 'networking.k8s.io/v1',
          kind: 'Ingress',
          metadata: {
            name: 'grafana',
            namespace: $.values.common.namespace,
          },
          spec: {
            tls: [{
              hosts: [
                grafana_host,
              ],
              secretName: 'grafana-certs',
            }],
            rules: [{
              host: grafana_host,
              http: {
                paths: [{
                  path: '/',
                  pathType: 'Prefix',
                  backend: {
                    service: {
                      name: 'grafana',
                      port: {
                        number: 3000,
                      },
                    },
                  },
                }],
              },
            }],
          },
      },
    },
  };

{ [name + '-ingress']: kp.ingress[name] for name in std.objectFields(kp.ingress) } +
{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
// { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }
