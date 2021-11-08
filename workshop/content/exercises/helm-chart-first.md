
Helm charts are the way to bundle up YAML, templatize it, version it, and add dependencies to other YAML. In this lesson, you'll build your own Helm chart and review its structure.

## Create your first chart

`helm` exposes a command to build scaffolding for new charts that bake-in best practices and syntax:

```execute-1
mkdir ~/charts
cd ~/charts
helm create my-chart
```

## Explore the chart's files

Examine the directory structure of the chart you just made:

```execute-1
tree my-chart
```

Below, you'll dive a bit deeper on each file, so change directories there for a while:

```execute-1
cd ~/charts/my-chart
```

### Chart.yaml

Up first is the metadata file for the chart, `Chart.yaml`:

```execute-1
less Chart.yaml
```

> NOTE: in `less`, you can use either the up or down arrow keys (alternatively "j" or "k") to navigate the file. You can also start a search with "/" then press ENTER, (e.g. type "/description"), then use "n" to find the next result or "N" to find the previous result.

You'll notice the following fields:

- `apiVersion`: the Helm api version this chart conforms to (confusingly, "v2" means Helm 3.x compatible).
- `name`: the name of the chart.
- `description`: description of the chart.
- `type`: either "application" or "library". Application charts can be deployed to Kubernetes because they generate YAML. Library charts can provide templating functions or other information (maybe even just values to be exposed...), and cannot be `helm installed` by themselves.
- `version`: the semantic version of this chart (the YAML templates, default values, etc).
- `appVersion`: an optional field to specifically point out the version of the application being deployed by the default values.

There are other fields not present in this default file, but one really important one is:

- `dependencies`: a map of dependencies of this chart (other charts) and their versions - for example, you might put a PostgreSQL chart as a dependency of a web app.

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

`NOTES.txt` and all files that start with `_` are not rendered as YAML, but serve other purposes. All other files are templates that should generate YAML documents Kubernetes can understand and process.

#### YAML templates

Files that aren't in the exception list are all considered YAML templates that should be sent to Kubernetes when you create/modify a release (the `*.yaml` extension is only for clarity). To dive a bit deeper into a specific template, look at `deployment.yaml`:

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
yq eval --inplace '.replicaCount = 2' values.yaml
helm template . --show-only templates/deployment.yaml | less -N
```

Alternatively, instead of changing the default value for _all_ releases of this chart, you can use a custom values file for a specific release.

Exit `less`:

```execute-1
q
```

Go ahead and change back the default replicaCount:

```execute-1
yq eval --inplace '.replicaCount = 1' values.yaml
```

If desired, you can check out the other YAML templates in `templates/` as well (`hpa.yaml`, `ingress.yaml`, etc).

#### _helpers.tpl

You may have noticed on line 4 of `templates/deployment.yaml` that the chart injects information from a `"my-chart.fullname"` object. This object is defined in `_helpers.tpl`.

As mentioned before, files starting with `_` don't generate YAML. This file defines a few helper functions you can use throughout the rest of the chart's templates. Take a look:

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

Since your chart currently installs a web application, the notes tell a user how to get the URL for the app they just created.

When you're done, exit `less`:

```execute-1
q
```

#### tests/

The `tests` directory is here for convention, and has more YAML files, but these are generally short-lived Jobs or Pods that execute to completion to verify that the application came up as expected:

```execute-1
less -N templates/tests/test-connection.yaml
```

While this Pod lives in `test/` by convention, what really makes this Pod a "test" to Helm is the annotation `"helm.sh/hook": test`. You'll notice your Helm release is marked successful if `wget` returns a response when hitting your Service. More generally, test pods that exit `0` are considered successful, and mean a Helm release is also successful. Any non-zero exit status will be reflected in Helm as a failed release.

Exit `less`:

```execute-1
q
```

> NOTE: `helm install --atomic` and `helm upgrade --atomic` work really well when you configure tests! Check out `helm install -h` and `helm upgrade -h` for more information.

## Deploy a release from your local chart

To create a release from your local helm chart, run:

```execute-1
helm install my-release .
```

Then check on the resources:

```execute-1
oc get all -l app.kubernetes.io/instance=my-release
```

> QUIZ: Why was the label `app.kubernetes.io/instance` used to select your release's resources? Where is that label defined?
> 
> <details><summary>Answer</summary>
> This label is added to all (well, most) resources in the chart through the `"my-chart.labels"` function in `templates/_helpers.tpl`, which includes all the labels generated by the function `"my-chart.selectorLabels"` also defined in `templates/_helpers.tpl`.
> </details>

You'll notice the Pods are in a crash loop, similarly to ChartMuseum, because the default image defined in your chart (`nginx`) doesn't pass the minimum security requirements of OpenShift. You'll fix this in the next lesson. For now, uninstall the release:

```execute-1
helm uninstall my-release
```

## Summary

In this lesson, you:

1. Built your first helm chart with `helm create`
1. Explored the basic structure of a chart, including:
  - `Chart.yaml`
  - `values.yaml`
  - `charts/`
  - `templates/`, and its files:
    - YAML template files
    - helper functions
    - `NOTES.txt`
    - `tests/`
1. Deployed a release of your chart from the local filesystem
1. Uninstalled a release of your chart

## Up next

In the next lesson, you'll modify your chart to make it more OpenShift friendly and add additional features.
