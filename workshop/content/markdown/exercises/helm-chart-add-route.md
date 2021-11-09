
In the last lesson, you modified existing resources in the chart to make it compatible with OpenShift. Now, you'll give it completely new features!

## Add supports for Routes

To start, modify the chart so it supports Routes instead of Ingresses.

### Step 1: Add a Route template

To start, add a file that defines the template for a Route manifest:

```execute-1
cat > templates/route.yaml <<EOF
{{- if .Values.route.enabled -}}
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
  {{- with .Values.route.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  host: {{ include "my-chart.fullname" . }}-{{ .Release.Namespace }}.{{ .Values.route.clusterDomainName }}
  port:
    targetPort: http
  tls:
  {{- toYaml .Values.route.tls | nindent 4 }}
  to:
    kind: Service
    name: {{ include "my-chart.fullname" . }}
    weight: 100
  wildcardPolicy: {{ .Values.route.wildcardPolicy }}
status: {}
{{- end }}
EOF
```

Next, append the required default values to `values.yaml`:

```execute-1
cat >> values.yaml <<EOF
route:
  enabled: false
  clusterDomainName: apps.example.com
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: edge
  wildcardPolicy: None
EOF
```

See the diff:

```execute-1
# add an "intent to add" for our new file, so we see the whole diff
git add -N templates/route.yaml
git diff
```

### Step 2: Validate the updates

Now you can check that the manifests all look OK with `helm lint`:

```execute-1
helm lint .
```

Take a look at the new YAML:

```execute-1
helm template . --show-only templates/route.yaml
```

You should see a strange error:

```text
Error: could not find template templates/route.yaml in chart
```

While a little cryptic, Helm is saying there's no YAML to display because you specifically told it to show the YAML for the Route. Remember the default values above - your Route is not rendered by default! Render the chart with the Route enabled:

```execute-1
helm template . --set route.enabled=true --show-only templates/route.yaml
```

Success! Your chart can render a Route manifest! Commit the change:

```execute-1
git add templates/route.yaml values.yaml
git commit -m "Added support for Routes"
```

### Step 3: Remove Ingress resources

Now that you've added support for Routes, it doesn't make much sense to keep the Ingress resources around, so delete them.

First, remove the Ingress template:

```execute-1
rm templates/ingress.yaml
```

and next, remove all the Ingress associated values:

```execute-1
yq eval --inplace 'del(."ingress")' ./values.yaml
```

There's also some references to the Ingress in `NOTES.txt`, so remove this section:

```text
{{- if .Values.ingress.enabled }}
{{- range $host := .Values.ingress.hosts }}
  {{- range .paths }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ $host.host }}{{ .path }}
  {{- end }}
{{- end }}
```

and replace it with this:

```copy
{{- if .Values.route.enabled }}
  oc get route {{ include "my-chart.fullname" . }} -o jsonpath='{"https://"}{.spec.host}{"\n"}'
```

> NOTE: the next line should be an `{{- else if ... }}` clause...

Using either `vi` or `nano`, e.g.:

```execute-1
nano templates/NOTES.txt
```

Check out the complete diff:

```execute-1
git diff
```

### Step 4: Validate again

Just to be sure everything is valid, run `helm lint` again:

```execute-1
helm lint .
```

### Step 5: Install your local changes

To install your chart from the local filesystem and test out the Route feature, create a custom values file:

```execute-1
cat > my-chart-custom-values.yaml <<EOF
route:
  enabled: true
  clusterDomainName: %cluster_subdomain%
EOF
```

Then run `helm install`, pointed to your local helm chart directory:

```execute-1
helm install my-release . --values my-chart-custom-values.yaml
```

You can follow the instructions at the end of the install to get the Route URL and test it. After you're done, uninstall the release:

```execute-1
helm uninstall my-release
```

Once this is done, commit the changes:

```execute-1
git add templates/NOTES.txt
git add --all templates/ingress.yaml
git add values.yaml
git commit -m "Removing Ingress support"
```

## Package and publish the new chart version

Your chart is stable again! Cut and publish a release.

### Step 1: Bump the version number

Before you package this chart, you should bump the version number:

```execute-1
yq eval --inplace '.version = "0.2.0"' Chart.yaml
```

See what changed:

```execute-1
git diff
```

Then commit:

```execute-1
git add Chart.yaml
git commit -m "Cutting a new release 0.2.0"
```

### Step 2: Package the chart

To package your chart:

```execute-1
helm package .
```

### Step 3: Publish the chart

To publish your chart:

> NOTE: Be sure your `port-forward` command for ChartMuseum is still active!

```execute-1
helm cm-push my-chart-0.2.0.tgz my-chartmuseum
```

### Step 4: Verify the published chart

First, update your local repositories:

```execute-1
helm repo update
```

Then install a release from the remote chart:

```execute-1
helm install my-release my-chartmuseum/my-chart --values ./my-chart-custom-values.yaml
```

To make sure you got the latest version, you can list the releases:

```execute-1
helm list
```

Once you're done exploring the install, uninstall the release:

```execute-1
helm uninstall my-release
```

Finally, remove the local package:

```execute-1
rm my-chart-0.2.0.tgz
```

## Summary

In this lesson, you solidified your understanding of developing Helm charts by:

1. Adding support for additional resources in your chart
1. Going through the process of pushing an updated version of a chart to your Helm repository

## Up next

In the next lesson, you'll review the content of the course and get access to a curated list of other online resources to explore Helm further.
