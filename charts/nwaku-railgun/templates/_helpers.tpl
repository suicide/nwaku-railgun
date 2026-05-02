{{- define "nwaku-railgun.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nwaku-railgun.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "nwaku-railgun.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nwaku-railgun.labels" -}}
helm.sh/chart: {{ include "nwaku-railgun.chart" . }}
app.kubernetes.io/name: {{ include "nwaku-railgun.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "nwaku-railgun.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nwaku-railgun.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "nwaku-railgun.configMapName" -}}
{{- printf "%s-config" (include "nwaku-railgun.fullname" .) -}}
{{- end -}}

{{- define "nwaku-railgun.rpcServiceName" -}}
{{- include "nwaku-railgun.fullname" . -}}
{{- end -}}

{{- define "nwaku-railgun.p2pServiceName" -}}
{{- printf "%s-p2p" (include "nwaku-railgun.fullname" .) -}}
{{- end -}}

{{- define "nwaku-railgun.websocketServiceName" -}}
{{- printf "%s-websocket" (include "nwaku-railgun.fullname" .) -}}
{{- end -}}

{{- define "nwaku-railgun.secretName" -}}
{{- if .Values.secrets.existingSecret -}}
{{- .Values.secrets.existingSecret -}}
{{- else -}}
{{- printf "%s-secrets" (include "nwaku-railgun.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "nwaku-railgun.pvcName" -}}
{{- if .Values.persistence.existingClaim -}}
{{- .Values.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-data" (include "nwaku-railgun.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "nwaku-railgun.websocketServiceNeeded" -}}
{{- if or .Values.service.websocket.enabled .Values.ingress.websocket.enabled -}}
true
{{- end -}}
{{- end -}}

{{- define "nwaku-railgun.validate" -}}
{{- if and .Values.secrets.create .Values.secrets.existingSecret -}}
{{- fail "set either secrets.create=true or secrets.existingSecret, but not both" -}}
{{- end -}}
{{- if and (not .Values.secrets.create) (not .Values.secrets.existingSecret) -}}
{{- fail "set one of secrets.create=true or secrets.existingSecret" -}}
{{- end -}}
{{- if and .Values.secrets.create (not .Values.secrets.data.nodekey) -}}
{{- fail "secrets.data.nodekey is required when secrets.create=true" -}}
{{- end -}}
{{- if and .Values.config.rlnRelay.enabled .Values.secrets.create (not .Values.secrets.data.rlnRelayCredPassword) -}}
{{- fail "secrets.data.rlnRelayCredPassword is required when config.rlnRelay.enabled=true and secrets.create=true" -}}
{{- end -}}
{{- if and .Values.config.rlnRelay.enabled .Values.secrets.create (not .Values.secrets.data.keystore) -}}
{{- fail "secrets.data.keystore is required when config.rlnRelay.enabled=true and secrets.create=true" -}}
{{- end -}}
{{- if and .Values.ingress.websocket.enabled (not (include "nwaku-railgun.websocketServiceNeeded" .)) -}}
{{- fail "websocket ingress requires service.websocket.enabled=true or ingress.websocket.enabled=true" -}}
{{- end -}}
{{- if and .Values.ingress.websocket.enabled (not .Values.ingress.websocket.host) -}}
{{- fail "ingress.websocket.host is required when ingress.websocket.enabled=true" -}}
{{- end -}}
{{- if and .Values.ingress.websocket.enabled .Values.ingress.websocket.tls.enabled (not .Values.ingress.websocket.tls.secretName) -}}
{{- fail "ingress.websocket.tls.secretName is required when ingress.websocket.tls.enabled=true" -}}
{{- end -}}
{{- if and .Values.config.network.advertise.enabled (eq (len .Values.config.network.advertise.extMultiaddrs) 0) -}}
{{- fail "config.network.advertise.extMultiaddrs must contain at least one address when config.network.advertise.enabled=true" -}}
{{- end -}}
{{- if and (eq .Values.service.p2p.type "NodePort") (not .Values.service.p2p.enabled) -}}
{{- /* no-op: valid, service is disabled */ -}}
{{- end -}}
{{- if and .Values.service.p2p.enabled (not (or (eq .Values.service.p2p.type "ClusterIP") (eq .Values.service.p2p.type "NodePort") (eq .Values.service.p2p.type "LoadBalancer"))) -}}
{{- fail "service.p2p.type must be one of ClusterIP, NodePort, or LoadBalancer" -}}
{{- end -}}
{{- if and .Values.service.p2p.enabled (eq .Values.service.p2p.type "NodePort") (not .Values.service.p2p.libp2p.nodePort) -}}
{{- fail "service.p2p.libp2p.nodePort is required when service.p2p.type=NodePort" -}}
{{- end -}}
{{- if and .Values.service.p2p.enabled (eq .Values.service.p2p.type "NodePort") (not .Values.service.p2p.discv5.nodePort) -}}
{{- fail "service.p2p.discv5.nodePort is required when service.p2p.type=NodePort" -}}
{{- end -}}
{{- if and (include "nwaku-railgun.websocketServiceNeeded" .) (not (or (eq .Values.service.websocket.type "ClusterIP") (eq .Values.service.websocket.type "NodePort") (eq .Values.service.websocket.type "LoadBalancer"))) -}}
{{- fail "service.websocket.type must be one of ClusterIP, NodePort, or LoadBalancer" -}}
{{- end -}}
{{- if and (include "nwaku-railgun.websocketServiceNeeded" .) (eq .Values.service.websocket.type "NodePort") (not .Values.service.websocket.nodePort) -}}
{{- fail "service.websocket.nodePort is required when service.websocket.type=NodePort" -}}
{{- end -}}
{{- if and .Values.service.rpc.enabled (not (or (eq .Values.service.rpc.type "ClusterIP") (eq .Values.service.rpc.type "LoadBalancer"))) -}}
{{- fail "service.rpc.type must be one of ClusterIP or LoadBalancer" -}}
{{- end -}}
{{- if and .Values.service.rpc.enabled (not .Values.config.rest.enabled) -}}
{{- fail "service.rpc.enabled requires config.rest.enabled=true" -}}
{{- end -}}
{{- end -}}
