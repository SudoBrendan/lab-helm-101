
Helm charts are the way to bundle up YAML, templatize it, version it, and add dependencies to other YAML. In this lesson, you'll build and customize your own Helm chart, then publish it to the ChartMuseum instance you configured in the last lesson.

## Create your first chart

`helm` exposes a command to build scaffolding for new charts that bake-in best practices and syntax:

```execute-1
helm create my-chart
```

## Explore the chart's files

Examine the directory structure of the chart you just made:

```execute-1
tree my-chart
```

Below, you'll dive a bit deeper on each file, so change directories there for a while:

```execute-1
pushd my-chart
```

### Chart.yaml

Up first is the metadata file for the chart, `Chart.yaml`:

```execute-1
less Chart.yaml
```

> NOTE: in `less`, you can use either the up or down arrow keys (alternatively "j" or "k") to navigate the file. You can also start a search with "/" then press ENTER, (e.g. type "/description"), then use "n" to find the next result or "N" to find the previous result.

You'll notice the following fields:

- `apiVersion`: the Helm api version this chart conforms to (confusingly, "v2" means Helm 3.x compatible)
- `name`: the name of the chart
- `description`: description of the chart
- `type`: either "application" or "library". Application charts can be deployed to Kubernetes because they generate YAML. Library charts can provide templating functions or other information (maybe even just values to be exposed...), and cannot be `helm installed` by themselves.
- `version`: the semantic version of this chart (the YAML templates, default values, etc)
- `appVersion`: an optional field to specifically point out the version of the application being deployed by the default values.

There are other fields not present in this default file, but one really important one is:

- `dependencies`: a map of dependencies of this chart (other charts) and their versions

When you're done reading through the file, exit `less`:

```execute-1
q
```

### values.yaml

This is the API into the chart and its defaults. Generally, you'll want to include every option available in the templates in this file as well, even if it's just a comment.

```execute-1
less values.yaml
```

Take a few minutes to figure see what parameters are available in this chart, then exit `less`:

```execute-1
q
```

### charts/

This directory is empty to start, but eventually contains all the dependencies after you run `helm dependency update`. You'll want to add files in this directory to your `.gitignore`.

```execute-1
ls charts
```

### templates/

This directory contains the meat and potatoes of a chart: the templates used to render YAML documents, helper functions, tests, and other metadata.

```execute-1
ls templates
```

Files that start with `_` are not rendered as YAML, but serve other purposes. All other files are templates that should generate YAML documents Kubernetes can understand and process.

#### YAML templates

Files that aren't in the exception list are all considered YAML templates that should be sent to Kubernetes when we create/modify a release (the `*.yaml` extension is only for clarity). To dive a bit deeper into a specific template, look at `deployment.yaml`:

```execute-1
less -N templates/deployment.yaml
```

Templates in Helm charts use a combination of two different syntaxes:

1. [golang templating](https://pkg.go.dev/text/template), and
1. [sprig functions](https://masterminds.github.io/sprig/)

You can see golang templating everywhere in the file with the `{{ something }}`, `{{- something }}`, and `{{- something -}}` syntaxes (the `-` characters denote if you want to trim leading/trailing whitespace). On line 9, you can see how charts use `values.yaml` to inject information into a template through the `.Values` global object. `.Chart` and `.Release` objects are also available to access additional metadata. Remember when developing templates that YAML syntax relies heavily on whitespace characters, so "  {{ .Values.image.repository }}" is different from "{{ .Values.image.repository }}". The `nindent` sprig function is sometimes used to set a particular whitepsace prefix.

Take a few minutes to investigate this file and see how information from `Chart.yaml`, release metadata, and `values.yaml` information is injected into the Deployment object, then exit `less`:

```execute-1
q
```

`helm template` can be used during chart development to see how changes affect resulting YAML, see it in action:

```execute-1
helm template . --show-only templates/deployment.yaml | less -N
```

You'll notice `RELEASE-NAME` shows up a few times as a placeholder. On line 14, you see the default replicas from `values.yaml` made it into the YAML!

Exit `less`:

```execute-1
q
```

Change the default value of the chart to see this take effect in the resulting rendered YAML:

```execute-1
yq eval '.replicaCount = 2' values.yaml
helm template . --show-only templates/deployment.yaml | less -N
```

Alternatively, instead of changing the default value for _all_ releases of this chart, you can use a custom values file for a specific release.

Exit `less`:

```execute-1
q
```

If desired, you can check out the other YAML templates in `templates/` as well (`hpa.yaml`, `ingress.yaml`, etc).

#### _helpers.tpl

You may have noticed on line 4 of `templates/deployment.yaml` that we inject information from a `"my-chart.fullname"` object. This object is defined in `_helpers.tpl`.

As mentioned before, files starting with `_` don't generate YAML. This file defines a few helper functions we can use throughout the rest of the chart's templates. Take a look:

```execute-1
less -N templates/_helpers.tpl
```

Functions can be created using the `define` keyword. As a best practice, functions in a chart should be namespaced with the chart's name, so here you see function names like `"my-chart.fullname"` (line 13) instead of `"fullname"`. This makes name collisions less likely when implementing dependencies in charts. As you may have noticed, the functions you can write are very powerful - ranging from concatenating strings, to generating whole chunks of YAML that are reused multiple times by different manifests.

Exit `less`:

```execute-1
q
```

#### Notes.txt

`NOTES.txt` is another special file that isn't rendered as YAML to ship to Kubernetes. It's the text that is displayed by `helm` after a release install has completed, or when running `helm get notes [RELEASE]`:

```execute-1
less -N templates/NOTES.txt
```

Exit `less`:

```execute-1
q
```

#### tests/

The `tests` directory is here for convention, and has more YAML files, but these are generally short-lived Jobs or Pods that merely execute to completion to verify that the application came up as expected:

```execute-1
less -N templates/tests/test-connection.yaml
```

While this Pod lives in `test/` by convention, what really makes this Pod a "test" to Helm is the annotation `"helm.sh/hook": test`. You'll notice our Helm release is marked successful if `wget` returns a response when hitting our Service.

Exit `less`:

```execute-1
q
```

## Edit your chart

While OpenShift supports Ingress objects, it also supports Routes, which have more advanced features! In this exercise, you'll modify the Helm chart to use Routes instead of Ingresses.

### Step 1: Fix hard-coded port

The default chart that is generated has one major issue: the port number for containers managed by the Deployment is hard-coded to `80`, fix that to be more generic by modifying the template:

```execute-1
sed -i 's/containerPort: 80/containerPort: {{ .Values.deployment.httpContainerPort }}/g' templates/deployment.yaml
```

then add the required default value:

```execute-1
cat >> values.yaml <<EOF
deployment:
  httpContainerPort: 80
EOF
```

### Step 2: Add a Route template

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

### Step 3: Validate the updates

Now you can check that the manifests all look OK with `helm lint`:

```execute-1
helm lint .
```

You should see something like `0 chart(s) failed`. If linting passes, Helm doesn't see any issues with rendering YAML - however, this doesn't mean that the YAML will be acceptable to a Kubernetes cluster (it could still have syntax issues - like not having all the required fields, etc). To run a quick test, render the YAML locally:

```execute-1
helm template . --show-only templates/route.yaml
```

You should see a strange error:

```text
Error: could not find template templates/route.yaml in chart
```

While a little cryptic, Helm is saying there's no YAML to display because you specifically told it to show the YAML for the Route. Remember the default values above? Your Route is not rendered by default! Render the chart with the Route enabled:

```execute-1
helm template . --set route.enabled=true --show-only templates/route.yaml
```

Success! Our chart can render a Route manifest!

### Step 4: Remove Ingress resources

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
{{- end }}
```

Using either `vi` or `nano`, e.g.:

```execute-1
nano templates/NOTES.txt
```

### Step 5: Validate again

Just to be sure everything is valid, run `helm lint` again:

```execute-1
helm lint .
```

## Install your chart

To install your chart from the local filesystem and test out the Route feature, create a custom values file, and configure it to install [etherpad](https://github.com/ether/etherpad-lite):

```execute-1
cat > my-chart-custom-values.yaml <<EOF
image:
  repository: etherpad/etherpad
  tag: latest

deployment:
  httpContainerPort: 9001

service:
  port: 9001

route:
  enabled: true
  clusterDomainName: %cluster_subdomain%
EOF
```

Then run `helm install`, pointed to your local helm chart directory:

```execute-1
helm install etherpad . --values my-chart-custom-values.yaml
```
