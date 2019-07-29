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

# Build multus plugin
FROM golang:1.10 AS multus
RUN git clone -q --depth 1 https://github.com/intel/multus-cni.git /go/src/github.com/intel/multus-cni
WORKDIR /go/src/github.com/intel/multus-cni
RUN ./build

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

# Final image
FROM centos/systemd as omec-cni
WORKDIR /tmp/cni/bin
COPY --from=multus /go/src/github.com/intel/multus-cni/bin/multus .
COPY --from=sriov-cni /go/src/github.com/intel-corp/sriov-cni/bin/sriov .
COPY --from=centralip-ipam /go/src/github.com/John-Lin/ovs-cni/bin/centralip .
COPY --from=vfioveth /bin/vfioveth .
COPY --from=vfioveth /bin/jq .
WORKDIR /usr/bin
COPY --from=sriov-dp /go/src/github.com/intel/sriov-network-device-plugin/build/sriovdp .

ARG org_label_schema_version=unknown
ARG org_label_schema_vcs_url=unknown
ARG org_label_schema_vcs_ref=unknown
ARG org_label_schema_build_date=unknown
ARG org_opencord_vcs_commit_date=unknown

LABEL org.label-schema.schema-version=1.0 \
      org.label-schema.name=omec-cni \
      org.label-schema.version=$org_label_schema_version \
      org.label-schema.vcs-url=$org_label_schema_vcs_url \
      org.label-schema.vcs-ref=$org_label_schema_vcs_ref \
      org.label-schema.build-date=$org_label_schema_build_date \
      org.opencord.vcs-commit-date=$org_opencord_vcs_commit_date
