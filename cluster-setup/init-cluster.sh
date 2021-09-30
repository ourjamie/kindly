#!/bin/bash

while getopts c: flag
do
    case "${flag}" in
        c) clustercreatedate=${OPTARG};;

    esac
done

if [ -z "$clustercreatedate" ]; then clustercreatedate=$(date +"%Y-%m-%d"); else echo $clustercreatedate; fi




clustername="cluster"-$clustercreatedate

echo $clustername

echo "============tooling============"
echo -e "\t $(which kubectl)"
echo -e "\t $(which istioctl)"
echo -e "\t $(which curl)"

if [ -d ./$clustername ] 
then
    echo "Directory $clustername exists." 
else
    echo "Error: Directory $clustername does not exist, creating."
    mkdir ./$clustername
fi

configpath=./$clustername/config
clustercontext="kind-"$clustername
# echo $(kind version)

# echo $(kind get clusters)

# kind create cluster --name $clustername --config ./cluster-config.yaml

# cp ~/.kube/config ./$clustername/config



# kubectl --kubeconfig=$configpath --context=$clustercontext cluster-info

# kubectl --kubeconfig=$configpath --context=$clustercontext get po -A

# ##apply metrics server - ensure kubelet-insecure-tls is in the container args and prefered addres types is
# ##set to InternalIP
# ##see https://gist.github.com/hjacobs/69b6844ba8442fcbc2007da316499eb4

# kubectl --kubeconfig=$configpath --context=$clustercontext apply -f ./manifests/metrics-server/components.yaml 

# ##metallb

# kubectl --kubeconfig=$configpath --context=$clustercontext apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml


# kubectl --kubeconfig=$configpath --context=$clustercontext create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 

# kubectl --kubeconfig=$configpath --context=$clustercontext apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml

# #https://www.baeldung.com/ops/docker-network-information
# #https://devops.stackexchange.com/questions/6241/how-do-i-use-docker-commands-format-option

# mtellbinital="$(docker network inspect -f '{{json .IPAM.Config}}' kind | jq '.[0].Subnet' |  grep -oP '[0-9]+\.[0-9]+\.')"

# metallbrange="${mtellbinital}0.100-${mtellbinital}0.200"
# echo "${metallbrange}"

# cat >./manifests/metallb/${clustername}-metallb-configmap.yaml <<EOL
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   namespace: metallb-system
#   name: config
# data:
#   config: |
#     address-pools:
#     - name: default
#       protocol: layer2
#       addresses:
#       - ${metallbrange}
# EOL

# kubectl --kubeconfig=$configpath --context=$clustercontext apply -n metallb-system -f ./manifests/metallb/${clustername}-metallb-configmap.yaml

# # deploy httpbin with altered service to use metallb
# kubectl --kubeconfig=$configpath --context=$clustercontext apply -n default -f ./manifests/metallb/test/httpbin.yaml

echo "path to kubeconfig=$configpath context=$clustercontext"

httpbintestip="$(kubectl --kubeconfig=$configpath --context=$clustercontext get svc httpbin -n default -o json | jq -r .status[].ingress[0].ip)"

httpbintestport="$(kubectl --kubeconfig=$configpath --context=$clustercontext get svc httpbin -n default -o json | jq -r  .spec.ports[0].port)"

httpbinstatus="$(curl -I http://$httpbintestip:$httpbintestport/get 2>/dev/null | head -n 1 | cut -d$' ' -f3)"

echo "service address of http://$httpbintestip:$httpbintestport/get status is $httpbinstatus"

# istioctl --kubeconfig=$configpath install
# istioctl --kubeconfig=$configpath verify-install

# # verify istio
# kubectl --kubeconfig=$configpath --context=$clustercontext create namespace istio-verify
# kubectl --kubeconfig=$configpath --context=$clustercontext label namespace istio-verify istio-injection=enabled --overwrite

# kubectl --kubeconfig=$configpath --context=$clustercontext get ns istio-verify --show-labels


# kubectl --kubeconfig=$configpath --context=$clustercontext apply -f ./manifests/istiotest/helloworld/helloworld.yaml -n istio-verify 

helloworldtestip="$(kubectl --kubeconfig=$configpath --context=$clustercontext get svc helloworld -n istio-verify -o json | jq -r .status[].ingress[0].ip)"

helloworldtestport="$(kubectl --kubeconfig=$configpath --context=$clustercontext get svc helloworld -n istio-verify -o json | jq -r  .spec.ports[0].port)"

helloworldstatus="$(curl -I http://$helloworldtestip:$helloworldtestport/hello 2>/dev/null | head -n 1 | cut -d$' ' -f3)"

echo "service address of http://$helloworldtestip:$helloworldtestport/hello status is $helloworldstatus"

# kubectl --kubeconfig=$configpath --context=$clustercontext apply -f ./manifests/istiotest/helloworld/helloworld-gateway.yaml -n istio-verify 

# kubectl --kubeconfig=$configpath --context=$clustercontext apply -f ./manifests/istiotest/helloworld/helloworld-destinationrule.yaml -n istio-verify 

ingressgatewayIP="$(kubectl --kubeconfig=$configpath --context=$clustercontext get svc istio-ingressgateway -n istio-system -o json | jq -r .status[].ingress[0].ip)"

ingressgatewaystatus="$(curl -I http://$ingressgatewayIP/hello 2>/dev/null | head -n 1 | cut -d$' ' -f3)"
echo "ingress gateway address of http://$ingressgatewayIP/hellostatus is $ingressgatewaystatus"