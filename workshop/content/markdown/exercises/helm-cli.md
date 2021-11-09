Alright, enough reading! Let's explore the `helm` CLI in action.

## Deploy your first Helm chart

Everything starts with a Helm **chart**. Charts can either be on the local filesystem, or hosted remotely and pulled (the process is very similar to container images). Similar to container images, there are myriad platforms hosting Helm charts that all follow the same standard protocols. To see how this works, you'll deploy an instance of [ChartMuseum](https://github.com/helm/chartmuseum) in OpenShift, which will allow you to self-host a Helm repository.

### Step 1: Search

There are thousands of open source charts available online. You can use the CLI to find a chart you want:

```execute-1
helm search hub "chartmuseum" -o yaml
```

The query will return a few results. When you use the `hub` subcommand, you're querying [Artifact Hub](https://artifacthub.io), a Helm-maintained list of repositories and charts in the open source community.

In this list, you should see a chart with the URL `https://artifacthub.io/packages/helm/chartmuseum/chartmuseum` (versions may vary):

```text
{...OUTPUT OMITTED...}
- app_version: 0.13.1
  description: Host your own Helm Chart Repository
  url: https://artifacthub.io/packages/helm/chartmuseum/chartmuseum
  version: 3.3.0
{...OUTPUT OMITTED...}
```

### Step 2: Add remote Helm repository

To deploy ChartMuseum, you'll need to add the Helm repository (server) where the chart is hosted from. By default, `helm` has no repositories configured:

```execute-1
helm repo list
```

So add one!

If you navigate to [the ChartMuseum Artifact Hub page](https://artifacthub.io/packages/helm/chartmuseum/chartmuseum), you'll see a big `Install` button on the top right that prints out the `helm` commands you need:

```execute-1
# this gives the repository URL an alias of "chartmuseum"
helm repo add chartmuseum https://chartmuseum.github.io/charts
```

Verify you got what you expected:

```execute-1
helm repo list
```

You should see something like:

```text
NAME            URL                                 
chartmuseum     https://chartmuseum.github.io/charts
```

### Step 3: Install a remote chart to OpenShift

Still following the `Install` tab in Artifact Hub, install your ChartMuseum instance with:

```execute-1
# helm install [RELEASE_NAME] [CHART_NAME]
helm install my-chartmuseum chartmuseum/chartmuseum --version 3.3.0
```

...then you can see the resources that were created:

```execute-1
oc get all --selector app.kubernetes.io/name=chartmuseum
```

You'll see something like:

```text
NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/my-chartmuseum   ClusterIP   172.30.74.22   <none>        8080/TCP   10m

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-chartmuseum   0/1     0            0           10m

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/my-chartmuseum-64d7fb7cff   1         0         0       4m55s
```

Well, you got a Service, a Deployment, a ReplicaSet... but no Pods? Check the Events to investigate:

```execute-1
oc get ev
```

There should be an error like:

```text
Error creating: pods "my-chartmuseum-586569b8d6-" is forbidden: unable to validate against any security context constraint: [provider restricted: .spec.securityContext.fsGroup: Invalid value: []int64{1000}: 1000 is not an allowed group]
```

This chart's defaults don't work on OpenShift! You can fix the YAML with custom **values**.

### Step 4: Set custom values

There are lots of values that you can modify in this Helm chart, you can check them with:

```execute-1
helm show values chartmuseum/chartmuseum
```

You can also query specific values using JSON paths:

```execute-1
helm show values chartmuseum/chartmuseum --jsonpath='{.image.repository}:{.image.tag}{"\n"}'
```

Everything you're looking at are the *default values* for this chart. If you want to override them, you need to tell Helm what you want changed. Given the error you saw, it looks like the user and filesystem permissions in the container image specified in the chart conflict with the Pod's `restricted` Security Context Constraints enforced by OpenShift. For this Workshop, a custom-built container image with correct permissions has been built and published. To use it, create a custom values file and add the specific options you need to get Helm to use the image. While you're at it, disable some unnecessary security features OpenShift can better manage for you, and enable the API (used later in the workshop):

```execute-1
cat > my-chartmuseum-values.yaml <<EOF
# instead of the default image, use one the author of this workshop published that has OpenShift-friendly permissions
image:
  repository: quay.io/bbergen/chartmuseum
  tag: v0.13.1

# disable the default security contexts set by the chart; let OpenShift do it's automatic (secure) thing!
securityContext:
  enabled: false

# set up configuration of the API for later...
env:
  open:
    DISABLE_API: false
EOF
```

You may have noticed that your custom values file didn't specify *all* the values available, only the ones you want to *change from the defaults*. When you use this custom values file, Helm will strategically merge in the default values with your custom ones.

To make this explicit - look at the exact YAML you expect to change in your Deployment when you upgrade the chart:

```execute-1
# old image
oc get deploy/my-chartmuseum -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

# old securityContext
oc get deploy/my-chartmuseum -o jsonpath='{.spec.template.spec.securityContext}{"\n"}'
```

Now, upgrade your stack with the changes:

```execute-1
helm upgrade my-chartmuseum chartmuseum/chartmuseum --version 3.3.0 --values ./my-chartmuseum-values.yaml
```

...and see that the YAML was updated:

```execute-1
# new image
oc get deploy/my-chartmuseum -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

# new securityContext
oc get deploy/my-chartmuseum -o jsonpath='{.spec.template.spec.securityContext}{"\n"}'
```

Check on the stack as it rolls out new Pods:

```execute-1
watch oc get all --selector app.kubernetes.io/name=chartmuseum
```

After a few seconds all the Pods should show READY and you can exit `watch`:

```execute-1
<ctrl-c>
```

### Step 5: Validate the application

By default, your Helm chart doesn't create an Ingress or Route, so the Helm repository server is only available inside the OpenShift Service network. There is a value to configure the chart to deploy an Ingress, but for simplicity/debugging you can create a proxy instead:

```execute-2
oc port-forward service/my-chartmuseum 8080:8080
```

Then retrieve the index from your repository:

```execute-1
curl http://localhost:8080/index.yaml
```

You should see a blank index, since you haven't uploaded any charts to your ChartMuseum instance yet:

```text
apiVersion: v1
entries: {}
generated: "2021-11-02T16:30:56Z"
serverInfo: {}
```

You can go ahead and kill the port-forward for now:

```execute-2
<ctrl-c>
```

### Step 6: Explore releases with `helm`

`helm` has a few more commands to help you explore releases. To start, you can always check the status of a release with:

```execute-1
helm status my-chartmuseum
```

...or retrieve specific information about a release:

```execute-1
# print the YAML
helm get manifest my-chartmuseum
```

```execute-1
# display the values used
helm get values my-chartmuseum
```

```execute-1
# or other information
helm get --help
```

```execute-1
# view history of releases
helm history my-chartmuseum
```

### Caveats

Alright - reflect on what just happened:

1. You queried thousands of charts online for an app you wanted (a Helm repository server called ChartMuseum)
1. You found a chart and investigated it a bit
1. You installed the default configuration of the chart into OpenShift
1. You hit a wall because the security setup of the chart's default container wasn't compatible with OpenShift
1. You fixed the issue by setting custom values

You may be wondering: "Does Red hat support this ChatMuseum app I just installed?" - the answer is "No", just like Red Hat doesn't support upstream bits for any other open source projects. Ultimately, if you decide to keep this chart installed, you'll be solely responsible for:

1. Understanding exactly what's in the chart and deploying upgrades over time to the chart/release in OpenShift
1. Understanding how to maintain day 1 and day 2 operations of the actual application deployed by the chart's YAML, including security, configuration, data disaster recovery, etc

**However**, Helm still gave you something incredibly valuable! You were able to test out a new application you knew nearly nothing about by deploying it into your environment in a few commands; this marketplace is a uniquely Helm/Kubernetes value-add. While you may want to eventually purchase a production grade and enterprise ready Helm repository (of course, we'll recommend **Quay** for its excellent integration with OpenShift), you could POC it for yourself to figure out if "this Helm repository thing" is even worth your time. The same goes for thousands of other applications you can find in Artifact Hub - you can POC them in minutes instead of weeks or months.

## Summary

In this section, you installed ChartMuseum to an OpenShift cluster through Helm without worrying too much about the specifics of the application by:

1. Querying open-source Helm charts using [Artifact Hub](artifacthub.io)
1. Installing a remote chart (`chartmuseum/chartmuseum`) to OpenShift with `helm install`
1. Upgrading your release (`my-chartmuseum`) in OpenShift with custom values (`./my-chartmuseum-values.yaml`) with `helm upgrade`

## Up next

Now that you've seen how to interact with open source Helm charts you can find online, you'll build your own chart from scratch!
