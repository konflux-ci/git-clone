FROM registry.access.redhat.com/ubi9/go-toolset:1.21.9-1.1716478616 AS builder

COPY git-clone/image/git-init git-init
ENV GODEBUG="http2server=0"
RUN CGO_ENABLED=0 \
    cd git-init && go build -o /tmp/tektoncd-catalog-git-clone 


FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:ef6fb6b3b38ef6c85daebeabebc7ff3151b9dd1500056e6abc9c3295e4b78a51

ENV BINARY=git-init \
    APP=app 

RUN microdnf install -y openssh-clients git git-lfs shadow-utils

COPY --from=builder /tmp/tektoncd-catalog-git-clone ${APP}/${BINARY}

RUN chgrp -R 0 ${APP} && \
    chmod -R g+rwX ${APP}

LABEL \
    name="konflux-git-init" \
    summary="konflux-git-init" \
    description="konflux-git-init" \
    io.k8s.display-name="konflux-git-init"

# Adding the user to make sure git+ssh uses HOME to read client configuration
RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot -d /home/git -m nonroot
USER 65532

ENTRYPOINT ["/app/git-init"]
