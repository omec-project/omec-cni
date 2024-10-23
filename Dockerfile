# Copyright 2019-present Open Networking Foundation
# Copyright (c) 2019-present Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

FROM busybox:1.37.0 as static
RUN wget https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz
RUN tar xvfz cni-plugins-linux-amd64-v0.9.1.tgz
RUN cp ./static /bin/static
RUN cp ./dhcp /bin/dhcp
RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
RUN cp ./jq-linux64 /bin/jq
RUN chmod +x /bin/static /bin/jq

FROM centos/systemd@sha256:09db0255d215ca33710cc42e1a91b9002637eeef71322ca641947e65b7d53b58 as aether-cni
WORKDIR /tmp/cni/bin
COPY vfioveth .
COPY --from=nfvpe/sriov-cni:v2.5 /usr/bin/sriov .
COPY --from=static /bin/jq .
COPY --from=static /bin/static .
COPY --from=static /bin/dhcp .
