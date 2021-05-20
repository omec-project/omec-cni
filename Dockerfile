#
# Copyright 2019-present Open Networking Foundation
# Copyright (c) 2019 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM busybox:1.33.0 as static
RUN wget https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz
RUN tar xvfz cni-plugins-linux-amd64-v0.9.1.tgz
RUN cp ./static /bin/static
RUN cp ./dhcp /bin/dhcp
RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
RUN cp ./jq-linux64 /bin/jq
RUN chmod +x /bin/static /bin/jq

FROM centos/systemd@sha256:09db0255d215ca33710cc42e1a91b9002637eeef71322ca641947e65b7d53b58 as omec-cni
WORKDIR /tmp/cni/bin
COPY vfioveth .
COPY --from=nfvpe/sriov-cni:v2.5 /usr/bin/sriov .
COPY --from=static /bin/jq .
COPY --from=static /bin/static .
COPY --from=static /bin/dhcp .
