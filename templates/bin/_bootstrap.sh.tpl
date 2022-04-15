#!/bin/bash

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

set -ex
export HOME=/tmp

{{- if .Values.bootstrap.enabled | default "echo 'Not Enabled'" }}

  {{- /* Create share types defined in Values.bootstrap */}}
  {{- range $name, $properties := .Values.bootstrap.share_types }}
    {{- if $properties.share_backend_name }}
manila --endpoint-type internal type-create {{ $name }} \
  {{ $properties.driver_handles_share_servers }}

manila --endpoint-type internal type-key {{ $name }} \
  set share_backend_name={{ $properties.share_backend_name}}
    {{- end }}
  {{- end }}

  {{- /* Create shares defined in Values.conf.backends */}}
  {{- if .Values.bootstrap.bootstrap_conf_backends }}
    {{- range $name, $properties := .Values.conf.backends }}
      {{- if $properties }}
manila --endpoint-type internal type-create {{ $name }} \
  {{ $properties.driver_handles_share_servers }}

manila --endpoint-type internal type-key {{ $name }} \
  set share_backend_name={{ $properties.share_backend_name}}

      {{- end }}
    {{- end }}
  {{- end }}

{{- /* Check share type and properties were added */}}
manila --endpoint-type internal type-list

{{- end }}

exit 0
