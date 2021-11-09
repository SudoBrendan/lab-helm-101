Congratulations, you've completed this workshop on Helm!

## Summary

You should now be able to:

1. Explain what Helm is, its objectives, a brief history, architecture, and limitations
1. Use the `helm` CLI to:
    - Install Helm charts and their dependencies
    - Manage Helm application life cycles in OpenShift, including installing, upgrading, and uninstalling
    - Query open source Helm charts online
1. Understand Helm chart basics, including:
    - What each file in a Helm chart does
    - How to develop and test changes in Helm charts
    - How to publish charts as artifacts in a Helm repository

## Continued Reading

While we hope this workshop was helpful in giving a hands-on experience with Helm, there's much more to learn. Here are a few links we'd recommend:

- [The official Helm documentation](https://helm.sh/docs/) is truly excellent, including its section on best practices.
- Check out some [Red Hat Helm charts](https://github.com/redhat-cop/helm-charts)!
- If Helm seems a bit too complex/heavy, you might try out [OpenShift Templates](https://docs.openshift.com/container-platform/4.8/openshift_images/using-templates.html), which provides a much lighter syntax for managing YAML. It does a lot less than Helm (no life cycle management, no helper functions or branching/looping logic in templates), but that simplicity makes Templates a lot easier to develop/manage over time compared to Helm charts. You also lose the repository aspect of Helm, since Templates are managed as CRDs in OpenShift.
- [Kustomize](https://kustomize.io/) is another alternative for YAML management, but it's "template free", and instead offers a standard syntax for patching in differences (e.g. dev vs prod environments have their own patches to apply to a standard, shared YAML). It's also natively supported in `kubectl` (and thus, `oc` - try `oc apply -k $KUSTOMIZATION_DIRECTORY`). Generally Kustomizations require copy-pasting more YAML, but if you like a what-you-see-is-what-you-get implementation, check out their [open source examples](https://github.com/kubernetes-sigs/kustomize/tree/master/examples).

## Closing

At Red Hat, we believe Open unlocks the world's potential - and that applies here too. If you have any feedback on this workshop, please share it with your Red Hat representative. You can also review this lab content at any time, it's completely [open source](https://github.com/SudoBrendan/lab-helm-101/tree/master/workshop)!

Feel free to keep this page open and explore the resources above or play around with `helm` in the terminal. Alternatively, click `Finish Workshop` below to tear down your lab environment.
