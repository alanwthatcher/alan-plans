#!/bin/sh

set -x

kubectl apply -f habitat-updater-k8s-rbac/habitat-updater-k8s-rbac.yml

kubectl apply -f habitat-updater-k8s-rbac/habitat-updater-k8s.yml
