FROM quay.io/openshifthomeroom/workshop-dashboard:5.0.0

USER root

# ref:  https://helm.sh/docs/intro/install/
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh --version v3.7.1 \
    && rm ./get_helm.sh \
    && yum install -y tree \
    && curl -fsSL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.14.1/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

COPY . /tmp/src

RUN rm -rf /tmp/src/.git* && \
    chown -R 1001 /tmp/src && \
    chgrp -R 0 /tmp/src && \
    chmod -R g+w /tmp/src

ENV TERMINAL_TAB=split

USER 1001

RUN /usr/libexec/s2i/assemble
