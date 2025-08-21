FROM registry.access.redhat.com/ubi9/go-toolset:1.24.4-1753853351 AS builder


COPY git-clone/image/git-init git-init
ENV GODEBUG="http2server=0"
RUN CGO_ENABLED=0 \
    cd git-init && go build -o /tmp/tektoncd-catalog-git-clone


FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:2f06ae0e6d3d9c4f610d32c480338eef474867f435d8d28625f2985e8acde6e8

ENV BINARY=git-init \
    KO_APP=/ko-app

RUN microdnf install -y openssh-clients git git-lfs shadow-utils findutils

COPY --from=builder /tmp/tektoncd-catalog-git-clone ${KO_APP}/${BINARY}

RUN chgrp -R 0 ${KO_APP} && \
    chmod -R g+rwX ${KO_APP}

LABEL \
    name="konflux-git-init" \
    summary="konflux-git-init" \
    description="konflux-git-init" \
    io.k8s.display-name="konflux-git-init"

# Adding the user to make sure git+ssh uses HOME to read client configuration
RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/ko-app/git-init"]
