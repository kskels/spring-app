# Spring Boot Sample Application

This app is created to demonstrate various capabilities of Red Hat OpenShift
Container Platform. 

Initial code generated using https://start.spring.io/ .

## Projects

Create CI/CD namespace

```bash
oc new-project spring-apps-cicd
```

Create and set permissions for development and staging namespaces

```bash
oc new-project spring-apps-staging

oc policy -n spring-apps-dev add-role-to-user edit \
  system:serviceaccount:spring-apps-cicd:pipeline
oc policy -n spring-apps-cicd add-role-to-group system:image-puller \
  system:serviceaccounts:spring-apps-dev

oc new-project spring-apps-staging

oc policy -n spring-apps-staging add-role-to-user edit \
  system:serviceaccount:spring-apps-cicd:pipeline
oc policy -n spring-apps-cicd add-role-to-group system:image-puller \
  system:serviceaccounts:spring-apps-staging
```
