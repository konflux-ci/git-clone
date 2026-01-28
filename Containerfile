FROM registry.access.redhat.com/ubi9/go-toolset:1.25.3-1766449309 AS git-builder

COPY git-clone/image/git-init git-init
ENV GODEBUG="http2server=0"
RUN CGO_ENABLED=0 \
    cd git-init && go build -o /tmp/tektoncd-catalog-git-clone

FROM registry.access.redhat.com/ubi9/go-toolset:1.25.3-1766449309 AS slsa-builder

COPY source-tool source-tool
RUN CGO_ENABLED=0 \
    cd source-tool && go build -o /tmp/sourcetool


FROM quay.io/konflux-ci/buildah-task:latest@sha256:bfd26f371245bd229c7524670a13001eaf14ee1e8e887dbd948d35a2f781e41a AS buildah-task-image
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:6fc28bcb6776e387d7a35a2056d9d2b985dc4e26031e98a2bd35a7137cd6fd71

ENV BINARY=git-init \
    KO_APP=/ko-app

RUN microdnf install -y openssh-clients git git-lfs shadow-utils findutils

COPY --from=git-builder /tmp/tektoncd-catalog-git-clone ${KO_APP}/${BINARY}
COPY --from=slsa-builder /tmp/sourcetool /usr/local/bin/sourcetool

RUN chgrp -R 0 ${KO_APP} && \
    chmod -R g+rwX ${KO_APP}

COPY --from=buildah-task-image /usr/bin/retry /usr/bin/

LABEL \
    name="konflux-git-init" \
    summary="Tekton step image for Konflux git init task" \
    description="Tekton step image for Konflux git init task" \
    io.k8s.description="Tekton step image for Konflux git init task" \
    io.k8s.display-name="konflux-git-init" \
    io.openshift.tags="tekton git init" \
    com.redhat.component="konflux-git-init"

# Adding the user to make sure git+ssh uses HOME to read client configuration
RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/ko-app/git-init"]
