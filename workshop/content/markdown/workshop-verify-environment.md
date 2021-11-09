To guarantee your workshop environment was set up correctly, you'll want to run a few commands.

1. Make sure you've got the Helm CLI installed, and it's version 3.x:
    ```execute
    helm version
    ```
2. Under the hood, `helm` uses `kubectl` (similar to `oc`) to send commands to the Kubernetes API, verify that's there too:
    ```execute
    kubectl version
    ```
3. Make sure you can connect to the OpenShift cluster:
    ```execute
    oc whoami
    ```
    ```execute
    oc status
    ```

Did you type these commands into the terminal yourself? If you did, click on the command instead and you will find that it is executed for you! You can click on any command which has the <span class="fas fa-play-circle"></span> icon shown to the right of it, and it will be copied to the interactive terminal and run. If you would rather make a copy of the command so you can paste it to another window, hold down the shift key when you click on the command.
