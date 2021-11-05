
Now that you're a little more familiar with Helm chart structure, you'll modify the chart you made to make it work out-of-box in OpenShift. You'll also learn how to package and publish your feature-complete chart.

## Modify the chart

The default chart you generated in the last lesson has a few issues when deploying in OpenShift. In this section you'll fix the chart.

### Step 1: Fix hard-coded port

To start, the port number for containers managed by the Deployment is hard-coded to `80`, meaning only containers that expose this port will work. Fix the chart to be more generic by modifying the template:

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

Whenever you make a change to a Helm chart, you should make sure everything still works with `helm lint`:

```execute-1
helm lint .
```

You should see something like `0 chart(s) failed`. If linting passes, Helm doesn't see any issues with rendering YAML - however, this doesn't mean that the YAML will be acceptable to a Kubernetes cluster (it could still have syntax issues - like not having all the required fields, etc). You can do a manual verification that the YAML looks like you expect with `helm template`:

```execute-1
helm template . --show-only templates/deployment.yaml
```

You should see that the default `containerPort` is still `80`. Now, you can test with a custom value:

```execute-1
helm template . --set deployment.httpContainerPort=9999 --show-only templates/deployment.yaml
```

> NOTE: recognize you used `deployment` instead of `.deployment` when using `--set`.

If the Deployment you see now uses port `9999`, you know the changes worked like you expect!

### Step 2: Fix default container

Next, we saw in the last lesson that the default container for the chart doesn't work with OpenShift's `restricted` SCCs. Setting a default container that works will make the chart easier to get started with. To do this, update `values.yaml` with a new default image and tag:

```execute-1
yq eval --inplace '.image.repository = "quay.io/bbergen/nginx"' values.yaml
yq eval --inplace '.image.tag = "1.18"' values.yaml
```

This new container serves traffic on port `8080`, so change that too:

```execute-1
yq eval --inplace '.deployment.httpContainerPort = 8080' values.yaml
```

...and for the sake of simplicity, make the Service also use that port:

```execute-1
yq eval --inplace '.service.port = 8080' values.yaml
```

Make sure linting still passes:

```execute-1
helm lint .
```

Verify the YAML uses the new default image, tag, and ports:

```execute-1
# -s is short for --show-only
helm template . -s templates/deployment.yaml -s templates/service.yaml
```

### Step 3: Validate the changes

Even though you've checked your work with `helm lint` and `helm template`, this doesn't mean that the OpenShift API will accept the YAML (it could be formatted improperly). To run a full test, you need to create a release of the local chart:

```execute-1
helm install my-release .
```

Then look at the resources created by the release:

```execute-1
oc get all -l app.kubernetes.io/instance=my-release
```

You should now have containers that don't crashloop! Create a proxy to test:

```execute-2
oc port-forward svc/my-release-my-chart 8080:8080
```

Then hit the Service through the proxy:

```execute-1
curl localhost:8080
```

You should see a `NGINX is working` message!

Stop the proxy:

```execute-2
<ctrl-c>
```

Uninstall your release:

```execute-1
helm uninstall my-release
```

## Package the chart and publish it to a repository

Now that you've got a stable Helm chart, you can package it up as a versioned artifact to share with others! There are lots of different ways to host Helm charts, but you'll use the ChartMuseum instance you deployed in the first lesson to distribute your chart.

### Step 1: Package your chart

Before you can publish your chart, you need to zip it into an archive:

```execute-1
helm package .
```

This will create a new file in your current directory:

```execute-1
ls -al my-chart-0.1.0.tgz
```

### Step 2: Upload to ChartMuseum

Since you'll be interacting with ChartMuseum's API, you'll need to start a proxy again:

```execute-2
oc port-forward svc/my-chartmuseum 8080:8080
```

To start, install the [Helm plugin for ChartMuseum](https://github.com/chartmuseum/helm-push#helm-cm-push-plugin):

```execute-1
helm plugin install https://github.com/chartmuseum/helm-push.git
```

Next, add ChartMuseum to your repositires:

```execute-1
helm repo add my-chartmuseum http://localhost:8080
```

Finally, publish your chart:

```execute-1
helm cm-push my-chart-0.1.0.tgz my-chartmuseum
```

### Step 3: Verify the chart was published correctly

To test your remote helm chart, you need to update your local repository cache:

```execute-1
helm repo update
```

Then you can try installing your chart from the remote repository:

```execute-1
helm install my-release my-chartmuseum/my-chart
```

If this works, your chart was published successfully! Feel free to test out the application deployed, or look at the OpenShift resources created. When you're finished, uninstall the release:

```execute-1
helm uninstall my-release
```

## Summary

TODO

## Up next

TODO
