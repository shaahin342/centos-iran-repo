#!/bin/bash

masters_count=3
workers_count=2
template_url="https://builds.coreos.fedoraproject.org/prod/streams/testing/builds/33.20210314.2.0/x86_64/fedora-coreos-33.20210314.2.0-vmware.x86_64.ova"
template_name="fedora-coreos-33.20210201.2.1-vmware.x86_64"
library="Linux ISOs"
cluster_name="mycluster"
cluster_folder="/MyVSPHERE/vm/Linux/OKD/mycluster"
network_name="VM Network"
install_folder=`pwd`

# Import the template
./oct.sh --import-template --library "${library}" --template-url "${template_url}"

# Install the desired OKD tools
oct.sh --install-tools --release 4.6

# Launch the prerun to generate and modify the ignition files
oct.sh --prerun --auto-secret

# Deploy the nodes for the cluster with the appropriate ignition data
oct.sh --build --template-name "${template_name}" --library "${library}" --cluster-name "${cluster_name}" --cluster-folder "${cluster_folder}" --network-name "${network_name}" --installation-folder "${install_folder}" --master-node-count ${masters_count} --worker-node-count ${workers_count}

# Turn on the cluster nodes
oct.sh --cluster-power on --cluster-name "${cluster_name}"  --master-node-count ${masters_count} --worker-node-count ${workers_count}

# Run the OpenShift installer
bin/openshift-install --dir=$(pwd) wait-for bootstrap-complete  --log-level=info