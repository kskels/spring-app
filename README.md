# Spring Boot Sample Application

The app is created to demostrate Jenkins CI/CD flows on Red Hat OpenShift 
Container Platform. For more info see
https://www.openshift.com/blog/jenkins-pipelines .

Initial code generated using https://start.spring.io/ .

## Jenkins

Jenkins server is installed in `devops-tools-jenkins` namespace

```bash
oc get pods -n devops-tools-jenkins
NAME                 READY   STATUS      RESTARTS   AGE
jenkins-1-deploy     0/1     Completed   0          24h
jenkins-1-lrcgn      1/1     Running     0          24h
```

## Projects

Create and set permissions for development and staging namespaces

```bash
oc new-project spring-apps-dev

oc policy -n spring-apps-dev add-role-to-user edit \
  system:serviceaccount:devops-tools-jenkins:jenkins
oc policy -n devops-tools-jenkins add-role-to-group system:image-puller \
  system:serviceaccounts:spring-apps-dev

oc new-project spring-apps-staging

oc policy -n spring-apps-staging add-role-to-user edit \
  system:serviceaccount:devops-tools-jenkins:jenkins
oc policy -n devops-tools-jenkins add-role-to-group system:image-puller \
  system:serviceaccounts:spring-apps-staging
```
