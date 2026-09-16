{{/*
Resolve gateway from dataCenter unless overridden.
*/}}
{{- define "datastage.gateway" -}}
{{- if .Values.gateway -}}
  {{- .Values.gateway -}}
{{- else if .Values.zenUrl -}}
  {{- .Values.zenUrl | trimPrefix "https://" | trimPrefix "http://" | splitList "/" | first -}}
{{- else -}}
  {{- $dc := .Values.dataCenter -}}
  {{- if eq $dc "dallas" -}}api.dataplatform.cloud.ibm.com
  {{- else if eq $dc "frankfurt" -}}api.eu-de.dataplatform.cloud.ibm.com
  {{- else if eq $dc "sydney" -}}api.au-syd.dai.cloud.ibm.com
  {{- else if eq $dc "toronto" -}}api.ca-tor.dai.cloud.ibm.com
  {{- else if eq $dc "london" -}}api.eu-gb.dataplatform.cloud.ibm.com
  {{- else if eq $dc "ys1dev" -}}api.dataplatform.dev.cloud.ibm.com
  {{- else if eq $dc "ypqa" -}}api.dataplatform.test.cloud.ibm.com
  {{- else if eq $dc "awsdev" -}}api.dev.aws.data.ibm.com
  {{- else if eq $dc "awstest" -}}api.test.aws.data.ibm.com
  {{- else if eq $dc "awsprod-apsouth" -}}api.ap-south-1.aws.data.ibm.com
  {{- else if eq $dc "awsprod-useast" -}}api.us-east-1.aws.data.ibm.com
  {{- else if eq $dc "awsgovpreprod" -}}api.dai.prep.ibmforusgov.com
  {{- else if eq $dc "awsgovprod" -}}api.dai.ibmforusgov.com
  {{- else -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Resolve remoteControlplaneEnv.
*/}}
{{- define "datastage.controlplaneEnv" -}}
{{- if .Values.remoteControlplaneEnv -}}
  {{- .Values.remoteControlplaneEnv -}}
{{- else if .Values.zenUrl -}}
  icp4d
{{- else if hasPrefix "aws" .Values.dataCenter -}}
  aws
{{- else -}}
  cloud
{{- end -}}
{{- end -}}

{{/*
Operator registry - custom or default.
*/}}
{{- define "datastage.operatorRegistry" -}}
{{- if .Values.customDockerRegistry -}}
  {{- if .Values.operatorRegistrySuffix -}}
    {{- printf "%s/%s" .Values.customDockerRegistry .Values.operatorRegistrySuffix -}}
  {{- else -}}
    {{- printf .Values.customDockerRegistry -}}
  {{- end -}}
{{- else -}}
  {{- if .Values.operatorRegistrySuffix -}}
    {{- printf "%s/%s" .Values.operatorRegistry .Values.operatorRegistrySuffix -}}
  {{- else -}}
    {{- printf .Values.operatorRegistry -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Docker registry prefix for px images - custom or default.
*/}}
{{- define "datastage.dockerRegistryPrefix" -}}
{{- if .Values.customDockerRegistry -}}
  {{- if .Values.dockerRegistrySuffix -}}
    {{- printf "%s/%s" .Values.customDockerRegistry .Values.dockerRegistrySuffix -}}
  {{- else -}}
    {{- printf .Values.customDockerRegistry -}}
  {{- end -}}
{{- else -}}
  {{- if .Values.dockerRegistrySuffix -}}
    {{- printf "%s/%s" .Values.dockerRegistryPrefix .Values.dockerRegistrySuffix -}}
  {{- else -}}
    {{- printf .Values.dockerRegistryPrefix -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
API key secret name - always the engine name, matching launch.sh behavior.
*/}}
{{- define "datastage.apiKeySecret" -}}
{{- .Values.name -}}
{{- end -}}
