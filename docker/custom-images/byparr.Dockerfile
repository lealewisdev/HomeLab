FROM dhi.io/alpine-base:3.24-dev@sha256:e8ea5cd1031f302d73920e38c0c9ff4090368f5ddbbfae519de9ea24865464bd AS builder
RUN apk add --no-cache openssh-client

FROM dhi.io/alpine-base:3.24@sha256:aa2aa13f40cfc9e17296ba19e64d9439f040fc5f01e4b29d81661ef7063e4e46
COPY --from=builder /usr/lib/           /usr/lib/
COPY --from=builder /usr/bin/ssh        /usr/bin/ssh
COPY --from=builder /etc/ssh/ssh_config /etc/ssh/ssh_config

RUN mkdir -p /home/nonroot/.ssh && chown -R nonroot:nonroot /home/nonroot/.ssh

ENTRYPOINT ["ssh", "-F", "/home/nonroot/.ssh/config", "-N", "server"]
