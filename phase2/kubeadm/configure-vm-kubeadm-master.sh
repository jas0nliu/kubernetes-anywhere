
# This is not meant to run on its own, but extends phase2/kubeadm/configure-vm-kubeadm.sh

KUBEADM_DIR=/etc/kubeadm
KUBEADM_CONFIG_FILE=$KUBEADM_DIR/kubeadm.yaml

#TODO: we should probably be able to configure POD_NETWORK_CIDR from `make config` in future
# and use the configured value by passing it on to CNI's. We resort to the below hard-coding
# since the current CNI's are not enabled to be configured with the user provided pod-network-cidr.
POD_NETWORK_CIDR=""
if [[ "$KUBEADM_CNI_PLUGIN" == "flannel" ]] || [[ "$KUBEADM_CNI_PLUGIN" == "calico" ]]; then
  POD_NETWORK_CIDR="10.244.0.0/16"
elif [[ "$KUBEADM_CNI_PLUGIN" == "weave" ]]; then
  POD_NETWORK_CIDR="10.32.0.0/12"
fi

mkdir -p $KUBEADM_DIR
cat <<EOF |tee $KUBEADM_CONFIG_FILE
kind: MasterConfiguration
apiVersion: kubeadm.k8s.io/v1alpha1
api:
  advertiseAddress: "$KUBEADM_ADVERTISE_ADDRESSES"
  bindPort: 443
networking:
  podSubnet: "$POD_NETWORK_CIDR"
kubernetesVersion: "$KUBEADM_KUBERNETES_VERSION"
token: "$KUBEADM_TOKEN"
EOF

if [[ "$KUBEADM_ENABLE_CLOUD_PROVIDER" == true ]]; then
  cat <<EOF |tee -a $KUBEADM_CONFIG_FILE
cloudProvider: "$CLOUD_PROVIDER"
EOF
fi


if [[ "$KUBEPROXY_MODE" == "ipvs" ]]; then
    cat <<EOF |tee -a $KUBEADM_CONFIG_FILE
kubeProxy:
  config:
    featureGates: SupportIPVSProxyMode=true
    mode: "$KUBEPROXY_MODE"
EOF
fi

kubeadm init --skip-preflight-checks --config $KUBEADM_CONFIG_FILE
