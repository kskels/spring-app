# Spring Boot Sample Application

This app is created to demonstrate various capabilities of Red Hat OpenShift
Container Platform.

Initial code generated using https://start.spring.io/ .

## Tekton Demo

Create `cicd` project

```bash
oc new-project spring-apps-cicd
```

Create and setup `dev` project

```bash
oc new-project spring-apps-dev

oc policy -n spring-apps-dev add-role-to-user edit \
  system:serviceaccount:spring-apps-cicd:pipeline
oc policy -n spring-apps-cicd add-role-to-group system:image-puller \
  system:serviceaccounts:spring-apps-dev
```

Create and setup `staging` project

```bash
oc new-project spring-apps-staging

oc policy -n spring-apps-staging add-role-to-user edit \
  system:serviceaccount:spring-apps-cicd:pipeline
oc policy -n spring-apps-cicd add-role-to-group system:image-puller \
  system:serviceaccounts:spring-apps-staging
```

Deploy pipeline manifests

```bash
oc project spring-apps-cicd

cd tekton/
oc apply -k .
```

Start the pipeline

```bash
./run-pipeline.sh
```
