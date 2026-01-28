FROM registry.access.redhat.com/ubi9/go-toolset:1.25.5-1769430014 AS git-builder

COPY git-clone/image/git-init git-init
ENV GODEBUG="http2server=0"
RUN CGO_ENABLED=0 \
    cd git-init && go build -o /tmp/tektoncd-catalog-git-clone

FROM registry.access.redhat.com/ubi9/go-toolset:1.25.5-1769430014 AS slsa-builder

COPY source-tool source-tool
RUN CGO_ENABLED=0 \
    cd source-tool && go build -o /tmp/sourcetool


FROM quay.io/konflux-ci/buildah-task:latest@sha256:5c5eb4117983b324f932f144aa2c2df7ed508174928a423d8551c4e11f30fbd9 AS buildah-task-image
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
