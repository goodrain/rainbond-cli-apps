#!/bin/bash
set -e

base=${1:-./.release}
releasedir=$base
rm -fr $releasedir
mkdir -p $releasedir

program=cni:k8s
vers=5.0

download(){

    K8S_VER=v1.10.11
    ETCD_VER=v3.2.25
    DOCKER_VER=17.06.2-ce
    CNI_VER=v0.7.4
    CALICO=v3.3.1
    flannel=v0.10.0
    DOCKER_COMPOSE=1.23.2
    HARBOR=v1.5.2
    CFSSL_VERSION=R1.2
    ARCH=linux-amd64
    CTOP=0.7.2
    DRY=v0.9-beta.8
    REG_VER=v0.16.0
    IMG_VER=v0.5.6
    #kube-prompt=v1.0.5
    HELM_VER=v2.12.3
    DOWNLOAD_URL=https://pkg.cfssl.org
    CFSSL_PKG=(cfssl cfssljson cfssl-certinfo)
    pushd ./bin
    echo "download cfssl ..."
    [ ! -f "cfssl" ] && (
        for pkg in ${CFSSL_PKG[@]}
        do
        curl -s -L ${DOWNLOAD_URL}/${CFSSL_VERSION}/${pkg}_${ARCH} -o ./${pkg}
        chmod +x ./${pkg}
        done
    )
    echo "download k8s hyperkube binary"
    [ ! -f "hyperkube" ] && (
        curl -s -L https://storage.googleapis.com/kubernetes-release/release/${K8S_VER}/bin/linux/amd64/hyperkube -o ./hyperkube
        chmod +x ./hyperkube
    )
    echo "download helm"
    [ ! -f "helm" ] && (
        rm -rf /tmp/helm && mkdir -p /tmp/helm
        curl -s -L https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VER}-linux-amd64.tar.gz -o /tmp/helm-${HELM_VER}-linux-amd64.tar.gz
        tar xzf /tmp/helm-${HELM_VER}-linux-amd64.tar.gz -C /tmp/helm  --strip-components=1
        cp -a /tmp/helm/helm .
        cp -a /tmp/helm/tiller .
        chmod +x ./helm
        chmod +x ./tiller
    )
    echo "download etcd binary"
    [ ! -f "etcd" ] && (
        curl -s -L https://storage.googleapis.com/etcd/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
        tar xf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/
        mv  /tmp/etcd-${ETCD_VER}-linux-amd64/etcd* .
        chmod +x ./etcd*
    )
    echo "download docker-compose"
    [ ! -f "docker-compose" ] && (
        curl -s -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-Linux-x86_64 -o ./docker-compose
        chmod +x ./docker-compose
    )
    echo "download calicoctl"
    [ ! -f "calicoctl" ] && (
        curl -s -L https://github.com/projectcalico/calicoctl/releases/download/${CALICO}/calicoctl-linux-amd64 -o ./calicoctl
        chmod +x ./calicoctl
    )
    echo "download ctop"
    [ ! -f "ctop" ] && (
        curl -s -L https://github.com/bcicen/ctop/releases/download/v${CTOP}/ctop-${CTOP}-linux-amd64 -o ./ctop
        chmod +x ./ctop
    )
    echo "download dry"
    [ ! -f "dry" ] && (
        curl -s -L https://github.com/moncho/dry/releases/download/${DRY}/dry-linux-amd64 -o ./dry
        chmod +x ./dry
    )
    echo "download reg"
    [ ! -f "reg" ] && (
        curl -s -L https://github.com/genuinetools/reg/releases/download/${REG_VER}/reg-linux-amd64 -o ./reg
        curl -s -L https://github.com/genuinetools/img/releases/download/${IMG_VER}/img-linux-amd64 -o ./img
        chmod +x ./reg
        chmod +x ./img
    )
    echo "download kube-prompt"
    [ ! -f "kube-prompt" ] && (
        curl -s -L https://rainbond-pkg.oss-cn-shanghai.aliyuncs.com/util/kube-prompt -o ./kube-prompt
        chmod +x ./kube-prompt
    )
    popd
    pushd ./cni/bin
    echo "download cni plugins"
    [ ! -f "flannel" ] && (
        curl -s -L https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/cni-plugins-amd64-${CNI_VER}.tgz -o /tmp/cni-plugins-amd64-${CNI_VER}.tgz
        tar xf /tmp/cni-plugins-amd64-${CNI_VER}.tgz -C $PWD
    )
    [ ! -f "calico" ] && (
        curl -s -L https://github.com/projectcalico/cni-plugin/releases/download/${CALICO}/calico-amd64 -o ./calico
        curl -s -L https://github.com/projectcalico/cni-plugin/releases/download/${CALICO}/calico-ipam-amd64 -o ./calico-ipam
        chmod +x ./calico ./calico-ipam
    )
    [ ! -f "lanneld" ] && (
        curl -s -L https://github.com/coreos/flannel/releases/download/v0.10.0/flanneld-amd64 -o ./flanneld
        chmod +x ./flanneld
    )
    popd
}

build(){

    cp -a bin $releasedir
    cp -a cni $releasedir

    cd $base
    tar zcf pkg.tgz `find . -maxdepth 1|sed 1d`

cat >Dockerfile <<EOF
FROM alpine:3.6
COPY pkg.tgz /
EOF
    docker build -t rainbond/${program}_${vers} .

}

case $1 in
    prepare)
        download
        build
    ;;
    *)
        download
        build
        docker push rainbond/${program}_${vers}
        echo "run <docker run --rm -v /srv/salt/misc/file:/sysdir rainbond/${program}_${vers} tar zxf /pkg.tgz -C /sysdir> for install"
    ;;
esac

