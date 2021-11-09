# Lab - Getting Started with Helm

* [Overview](#overview)
* [Deploying the Workshop](#deploying-the-workshop)
  * [Deploying to an OpenShift Cluster](#deploying-to-an-openshift-cluster)
* [Deleting the Workshop](#deleting-the-workshop)
* [Contribute](#contribute)

## Overview

| -- | -- |
| Audience Experience Level | Advanced |
| Supported Number of Users | 100 (on-demand) |
| Average Time to Complete | 90 minutes |

A workshop that introduces the basic concepts of Helm in OpenShift. A decent understanding of OpenShift/Kubernetes and primitives (Pods/Services/Deployments/etc) is required.

## Deploying the Workshop

This workshop is meant to be run using [Red Hat RHPDS](https://rhpds.redhat.com).

### Deploying to an OpenShift Cluster

Until this workshop is available natively in RHPDS, you need to deploy it manually as an administrator of an OpenShift cluster.

**Prerequisites**

* An OpenShift 4.8 Workshop cluster from [Red Hat Product Demo System (RHPDS)](https://rhpds.redhat.com). This cluster is available in the catalog in the **Workshops** folder and is named **OpenShift 4.8 Workshop**.

>NOTE: It can take upwards of 45 minutes to provision this cluster!

**Steps**

Once you have a cluster, deploy the workshop:

1. First, using the `oc login` command, log into the OpenShift cluster where you want to deploy the workshop. You need to log in with cluster admin permissions.
1. Create a project to deploy the workshop to:
    ```sh
    oc new-project lab-helm-101
    ```
1. Deploy all Workshop resources (see [settings](.workshop/settings.sh) for configuration details)
    ```sh
    .workshop/scripts/deploy-spawner.sh
    ```
1. Finally, get the URL of the workshop spawner
    ```sh
    oc get ingress/spawner --jsonpath='https://{.spec.host}{"\n"}'
    ```
1. By default, this Workshop runs in `learning-portal` mode, meaning all sessions are ephemeral and there's no specific users need to be created in the cluster, and sessions are deleted once the workshop completes or it times out.

## Deleting the Workshop

Run

```sh
.workshop/scripts/delete-spawner.sh
```

## Contribute

Want to make a change to this workshop? Excellent! If you're new to workshops, you might check out [this guide to getting started with Workshops](https://github.com/openshift-homeroom/lab-workshop-content).

### Pull

To make changes to this workshop, pull the repository and submodules

```sh
git clone --recurse-submodules <this repo url>
```

### Build/Deploy Dev Workshop

To deploy a new dev version of this workshop:

```sh
# create a new project
oc new-project my-workshop-demo

# deploy a single-instance workshop using dev settings
.workshop/scripts/deploy-personal.sh --settings=develop

# navigate to the route created
oc get route
```

Dev authentication settings can be found in `.workshop/develop-settings.sh`.

Once you make a local change in the workshop, you can build your local changes into a new image using OpenShift:

```sh
# trigger a build
.workshop/scripts/build-workshop.sh

# wait for DeploymentConfig to complete rolling out the new image
oc rollout status dc/lab-helm-101

# refresh the route page in your browser
```

### Spellcheck

It's easy to misspell words in markdown. I use `aspell` to validate before pushing:

```sh
find ./workshop/content/markdown -iname '*.md' -exec aspell --master=en_US --lang=en_US -c {} \;

# for the bold, or if you issue a commit before
find ./workshop/content/markdown -iname '*.md' -exec aspell --master=en_US --lang=en_US --dont-backup -c {} \;
```

### Publish New Workshop Image

When Workshops instantiate using the steps [above](#deploying-the-workshop), a [spawner](https://github.com/openshift-homeroom/workshop-spawner) is deployed that's configured by some [settings](.workshop/settings.sh). To have future workshops spawn the updated content, you'll want to push a new, versioned container image to a public registry, then update the settings to reflect that new, stable change.
