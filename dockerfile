FROM alpine:3.19 AS base

ARG ANCHOR_PATH="/etc/unbound/root.key"
ARG USER_NAME="u_unbound"
ARG UID="1000"
ARG GID="1000"
ARG GROUP_NAME="g_unbound"

RUN apk update --no-cache unbound
RUN apk upgrade --no-cache unbound

RUN apk add --no-cache unbound

RUN echo "include: /etc/unbound/unbound.conf.d/myunbound.conf" | cat - /etc/unbound/unbound.conf > temp && mv temp /etc/unbound/unbound.conf
RUN sed -i 's|trust-anchor-file: /usr/share/dnssec-root/trusted-key.key|auto-trust-anchor-file: ${ANCHOR_PATH}|' /etc/unbound/unbound.conf
RUN sed -i '/control-enable: yes/d' /etc/unbound/unbound.conf
RUN sed -i '/control-interface: \/run\/unbound.control.sock/N; s/^.*\n//' /etc/unbound/unbound.conf
RUN sed -i "s/# username: \"unbound\"/username: \"u_unbound\"/" /etc/unbound/unbound.conf

RUN addgroup -S -g "${GID}" "${GROUP_NAME}" && adduser -S -h /usr/local/"${USER_NAME}" -u "${UID}" -g "${GID}" "${USER_NAME}"

RUN chown -Rh "${USER_NAME}":"${GROUP_NAME}" /etc/unbound
RUN chown -Rh "${USER_NAME}":"${GROUP_NAME}" /usr/share/dnssec-root/

RUN mkdir -p /etc/unbound/unbound.conf.d

RUN mkdir -p /etc/unbound/dev/log
RUN chown -Rh "${USER_NAME}":"${GROUP_NAME}" /etc/unbound/dev/log/

USER "${USER_NAME}"

RUN /usr/sbin/unbound-anchor -a ${ANCHOR_PATH} || true

ENTRYPOINT /usr/sbin/unbound-checkconf && /usr/sbin/unbound -d
