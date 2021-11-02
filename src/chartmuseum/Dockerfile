ARG BASE_IMAGE_NAME="ghcr.io/helm/chartmuseum"
ARG BASE_IMAGE_TAG="v0.13.1"
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}
USER 0
RUN chgrp 0 /chartmuseum && chmod g=u /chartmuseum
USER 1001