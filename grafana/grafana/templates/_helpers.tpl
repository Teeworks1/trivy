{{- define "grafana.configData" -}}
{{- .Values.configData | toYaml -}}
{{- end -}}

{{- define "grafana.secretsData" -}}
admin-user: {{ .Values.admin.userKey | b64enc | quote }}
admin-password: {{ .Values.admin.passwordKey | b64enc | quote }}
{{- end -}}

{{- define "grafana.pod" -}}
containers:
  - name: grafana
    image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    ports:
      - containerPort: 3000
        name: grafana
      - containerPort: 9094
        name: gossip
    env:
      - name: GF_SECURITY_ADMIN_USER
        valueFrom:
          secretKeyRef:
            name: {{ .Values.admin.secretName }}
            key: admin-user
      - name: GF_SECURITY_ADMIN_PASSWORD
        valueFrom:
          secretKeyRef:
            name: {{ .Values.admin.secretName }}
            key: admin-password
    volumeMounts:
      - name: config-datasources
        mountPath: /etc/grafana/provisioning/datasources
        subPath: datasources.yaml
      {{- if .Values.persistence.enabled }}
      - name: grafana-persistence
        mountPath: /var/lib/grafana
      {{- end }}
volumes:
  - name: config-datasources
    configMap:
      name: {{ include "grafana.fullname" . }}-config-datasources
  {{- if .Values.persistence.enabled }}
  - name: grafana-persistence
    persistentVolumeClaim:
      claimName: {{ .Values.persistence.existingClaim | default (include "grafana.fullname" .) }}
  {{- end }}
{{- end -}}
{{- define "grafana.fullname" -}}
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

{{- define "grafana.labels" -}}
app.kubernetes.io/name: {{ include "grafana.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.labels }}
{{- toYaml .Values.labels | nindent 0 }}
{{- end }}
{{- end }}
{{- define "grafana.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grafana.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "grafana.namespace" -}}
{{- .Release.Namespace | default "default" -}}
{{- end -}}
{{- define "grafana.serviceAccountNameTest" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "grafana.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
{{- define "grafana.configDashboardProviderData" -}}
apiVersion: v1
providers:
- name: 'default'
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  updateIntervalSeconds: 10
  options:
    path: /var/lib/grafana/dashboards/default
{{- end -}}
{{- define "grafana.ingress.isStable" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.Version -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}
{{- define "grafana.ingress.supportsIngressClassName" -}}
{{- if semverCompare ">=1.18-0" .Capabilities.KubeVersion.Version -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}
{{- define "grafana.ingress.supportsPathType" -}}
{{- if semverCompare ">=1.18-0" .Capabilities.KubeVersion.Version -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}
{{- define "grafana.ingress.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1" -}}
networking.k8s.io/v1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end -}}