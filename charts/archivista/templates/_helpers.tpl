{{/*
Expand the name of the chart.
*/}}
{{- define "archivista.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "archivista.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "archivista.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Define the raw archivista.namespace template if set with forceNamespace or .Release.Namespace is set
*/}}
{{- define "archivista.rawnamespace" -}}
{{- if .Values.forceNamespace -}}
{{ print .Values.forceNamespace }}
{{- else -}}
{{ print .Release.Namespace }}
{{- end -}}
{{- end -}}

{{/*
Define the archivista.namespace template if set with forceNamespace or .Release.Namespace is set
*/}}
{{- define "archivista.namespace" -}}
{{ printf "namespace: %s" (include "archivista.rawnamespace" .) }}
{{- end -}}

{{/*
Create the image path for the passed in image field
*/}}
{{- define "archivista.image" -}}
{{- if eq (substr 0 7 .version) "sha256:" -}}
{{- printf "%s/%s@%s" .registry .repository .version -}}
{{- else -}}
{{- printf "%s/%s:%s" .registry .repository .version -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "archivista.labels" -}}
helm.sh/chart: {{ include "archivista.chart" . }}
{{ include "archivista.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "archivista.selectorLabels" -}}
app.kubernetes.io/name: {{ include "archivista.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "archivista.mysql.labels" -}}
{{ include "archivista.labels" . }}
{{- end -}}

{{- define "archivista.mysql.matchLabels" -}}
app.kubernetes.io/component: {{ .Values.mysql.name | quote }}
{{ include "archivista.selectorLabels" . }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "archivista.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "archivista.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for the mysql component
*/}}
{{- define "archivista.serviceAccountName.mysql" -}}
{{- if .Values.mysql.serviceAccount.create -}}
    {{ default (include "archivista.mysql.fullname" .) .Values.mysql.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.mysql.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the Archivista createdb job.
*/}}
{{- define "archivista.serviceAccountName.createdb" -}}
{{- if .Values.createdb.serviceAccount.create -}}
    {{ default (include "archivista.createdb.fullname" .) .Values.createdb.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.createdb.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the hostname for mysql
*/}}
{{- define "mysql.hostname" -}}
{{- default (include "archivista.mysql.fullname" .) .Values.mysql.hostname }}
{{- end -}}

{{/*
Return the database for mysql
*/}}
{{- define "mysql.database" -}}
{{- default (include "archivista.fullname" .) .Values.mysql.database }}
{{- end -}}

{{/*
Return the secret with MySQL credentials
*/}}
{{- define "mysql.secretName" -}}
{{- if .Values.mysql.auth.existingSecret -}}
{{- printf "%s" .Values.mysql.auth.existingSecret -}}
{{- else -}}
{{- printf "%s" (include "archivista.mysql.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified Mysql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "archivista.mysql.fullname" -}}
{{- if .Values.mysql.fullnameOverride -}}
{{- .Values.mysql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.mysql.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.mysql.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified createdb job name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "archivista.createdb.fullname" -}}
{{- if .Values.createdb.fullnameOverride -}}
{{- .Values.createdb.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.createdb.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.createdb.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return a random Secret value or the value of an exising Secret key value
*/}}
{{- define "archivista.randomSecret" -}}
{{- $randomSecret := (randAlphaNum 10) }}
{{- $secret := (lookup "v1" "Secret" .context.Release.Namespace .secretName) }}
{{- if $secret }}
{{- if hasKey $secret.data .key }}
{{- print (index $secret.data .key) | b64dec }}
{{- else }}
{{- print $randomSecret }}
{{- end }}
{{- else }}
{{- print $randomSecret }}
{{- end }}
{{- end -}}