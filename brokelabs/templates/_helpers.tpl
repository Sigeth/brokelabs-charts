{{- define "brokelabs.labels" -}}
app.kubernetes.io/part-of: brokelabs
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "brokelabs.selector" -}}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/name: {{ .name }}
{{- end }}

{{/* Fully qualified image of a component: (dict "root" $ "name" "api").
     image.tag overrides every component; otherwise versions.<name>. */}}
{{- define "brokelabs.image" -}}
{{- $tag := .root.Values.image.tag | default (index .root.Values.versions .name) -}}
{{- if not $tag -}}{{- fail (printf "no image version for %s: set versions.%s" .name .name) -}}{{- end -}}
{{ .root.Values.image.registry }}/brokelabs-{{ .name }}:{{ $tag }}
{{- end }}

{{- define "brokelabs.replicas" -}}
{{ if eq .Values.profile "cluster" }}2{{ else }}1{{ end }}
{{- end }}

{{- define "brokelabs.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: 65532
runAsGroup: 65532
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "brokelabs.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: [ALL]
{{- end }}

{{/* Public URL of the gateway, for browsers. */}}
{{- define "brokelabs.gatewayURL" -}}
{{- if .Values.gateway.publicURL -}}
{{ .Values.gateway.publicURL }}
{{- else if .Values.httpRoute.gatewayHostname -}}
https://{{ .Values.httpRoute.gatewayHostname }}
{{- else -}}
http://localhost:8081
{{- end -}}
{{- end }}

{{/* Origins allowed to change state with the session cookie (CSRF). */}}
{{- define "brokelabs.allowedOrigins" -}}
{{- if .Values.api.allowedOrigins -}}
{{ join "," .Values.api.allowedOrigins }}
{{- else if .Values.api.publicURL -}}
{{ trimSuffix "/" .Values.api.publicURL }}
{{- else if .Values.httpRoute.hostname -}}
https://{{ .Values.httpRoute.hostname }}
{{- end -}}
{{- end }}

{{- /* Public URL of the platform, as browsers reach it. */}}
{{- define "brokelabs.publicURL" -}}
{{- if .Values.api.publicURL -}}
{{ trimSuffix "/" .Values.api.publicURL }}
{{- else if .Values.httpRoute.hostname -}}
https://{{ .Values.httpRoute.hostname }}
{{- else -}}
http://localhost:8080
{{- end -}}
{{- end }}

{{- /* Secret with the push credentials of the registry mirror. */}}
{{- define "brokelabs.mirrorSecret" -}}
{{- .Values.mirror.existingSecret | default "brokelabs-mirror-credentials" -}}
{{- end }}
