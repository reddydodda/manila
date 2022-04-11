{{/*
Copyright 2017 The Openstack-Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

# This function creates a manifest for db migration and management.
# It can be used in charts dict created similar to the following:
# {- $dbSyncJob := dict "envAll" . "dbId" "db-id" "serviceName" "senlin"-}
# { $dbSyncJob | include "helm-toolkit.manifests.job_db_general" }

{{- define "helm-toolkit.manifests.job_db_general" -}}
{{- $envAll := index . "envAll" -}}
{{- $dbId := index . "dbId" -}}
{{- $serviceName := index . "serviceName" -}}
{{- $baseConfigFile := index . "baseConfigFile" | default $serviceName -}}
{{- $nodeSelector := index . "nodeSelector" | default ( dict $envAll.Values.labels.job.node_selector_key $envAll.Values.labels.job.node_selector_value ) -}}
{{- $configMapBin := index . "configMapBin" | default (printf "%s-%s" $serviceName "bin" ) -}}
{{- $configMapEtc := index . "configMapEtc" | default (printf "%s-%s" $serviceName "etc" ) -}}
{{- $podVolMounts := index . "podVolMounts" | default false -}}
{{- $podVols := index . "podVols" | default false -}}
{{- $podEnvVars := index . "podEnvVars" | default false -}}
{{- $scriptFile := index . "scriptFile" | default (printf "/tmp/%s.sh" $dbId) -}}
{{- $dbToSync := index . "dbToSync" | default ( dict "configFile" (printf "/etc/%s/%s.conf" $serviceName $baseConfigFile ) "logConfigFile" (printf "/etc/%s/logging.conf" $serviceName ) "image" ( index $envAll.Values.images.tags ( printf "%s_%s" $serviceName $dbId | replace "-" "_")) ) -}}

{{- $serviceNamePretty := $serviceName | replace "_" "-" -}}

{{- $serviceAccountName := printf "%s-%s" $serviceNamePretty $dbId }}
{{ tuple $envAll ($dbId | replace "-" "_") $serviceAccountName | include "helm-toolkit.snippets.kubernetes_pod_rbac_serviceaccount" }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "%s-%s" $serviceNamePretty $dbId | quote }}
spec:
  template:
    metadata:
      labels:
{{ tuple $envAll $serviceName $dbId | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 8 }}
    spec:
      serviceAccountName: {{ $serviceAccountName }}
      restartPolicy: OnFailure
      nodeSelector:
{{ toYaml $nodeSelector | indent 8 }}
      initContainers:
{{ tuple $envAll ($dbId | replace "-" "_") list | include "helm-toolkit.snippets.kubernetes_entrypoint_init_container" | indent 8 }}
      containers:
        - name: {{ printf "%s-%s" $serviceNamePretty $dbId | quote }}
          image: {{ $dbToSync.image | quote }}
          imagePullPolicy: {{ $envAll.Values.images.pull_policy | quote }}
{{ tuple $envAll $envAll.Values.pod.resources.jobs.db_general | include "helm-toolkit.snippets.kubernetes_resources" | indent 10 }}
{{- if $podEnvVars }}
          env:
{{ $podEnvVars | toYaml | indent 12 }}
{{- end }}
          command:
            - {{ $scriptFile | quote }}
          volumeMounts:
            - name: pod-tmp
              mountPath: /tmp
            - name: db-general-sh
              mountPath: {{ $scriptFile | quote }}
              subPath: {{ base $scriptFile | quote }}
              readOnly: true
            - name: etc-service
              mountPath: {{ dir $dbToSync.configFile | quote }}
            - name: db-general-conf
              mountPath: {{ $dbToSync.configFile | quote }}
              subPath: {{ base $dbToSync.configFile | quote }}
              readOnly: true
            - name: db-general-conf
              mountPath: {{ $dbToSync.logConfigFile | quote }}
              subPath: {{ base $dbToSync.logConfigFile | quote }}
              readOnly: true
{{- if $podVolMounts }}
{{ $podVolMounts | toYaml | indent 12 }}
{{- end }}
      volumes:
        - name: pod-tmp
          emptyDir: {}
        - name: db-general-sh
          configMap:
            name: {{ $configMapBin | quote }}
            defaultMode: 0555
        - name: etc-service
          emptyDir: {}
        - name: db-general-conf
          secret:
            secretName: {{ $configMapEtc | quote }}
            defaultMode: 0444
{{- if $podVols }}
{{ $podVols | toYaml | indent 8 }}
{{- end }}
{{- end }}
