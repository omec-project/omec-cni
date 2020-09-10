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

# Build sriov plugin
FROM golang:1.10 AS sriov-cni
RUN git clone -q -b dev/k8s-deviceid-model https://github.com/Intel-Corp/sriov-cni.git /go/src/github.com/intel-corp/sriov-cni
WORKDIR /go/src/github.com/intel-corp/sriov-cni
RUN ./build

# Build sriov device plugin
FROM golang:1.10 AS sriov-dp
RUN git clone -q https://github.com/intel/sriov-network-device-plugin.git /go/src/github.com/intel/sriov-network-device-plugin
WORKDIR /go/src/github.com/intel/sriov-network-device-plugin
RUN make

# Build centralip ipam plugin
FROM golang:1.10 AS centralip-ipam
RUN go get -u github.com/kardianos/govendor
RUN git clone -q https://github.com/John-Lin/ovs-cni.git /go/src/github.com/John-Lin/ovs-cni
WORKDIR /go/src/github.com/John-Lin/ovs-cni
RUN govendor sync && ./build.sh

# Build vfioveth plugin
FROM busybox as vfioveth
RUN wget -O /bin/vfioveth https://raw.githubusercontent.com/clearlinux/cloud-native-setup/master/clr-k8s-examples/9-multi-network/cni/vfioveth
RUN wget -O /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
RUN chmod +x /bin/vfioveth /bin/jq

# Copy static IPAM plugin
FROM busybox as static
RUN wget https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz
RUN tar xvfz cni-plugins-linux-amd64-v0.8.2.tgz
RUN cp ./static /bin/static

# Final image
FROM centos/systemd as omec-cni
WORKDIR /tmp/cni/bin
COPY --from=sriov-cni /go/src/github.com/intel-corp/sriov-cni/bin/sriov .
COPY --from=vfioveth /bin/vfioveth .
COPY --from=vfioveth /bin/jq .
COPY --from=static /bin/static .
WORKDIR /usr/bin
COPY --from=sriov-dp /go/src/github.com/intel/sriov-network-device-plugin/build/sriovdp .
