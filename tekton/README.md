# Tekton - Spring Pipeline using Maven and S2I

This demo shows an example pipeline for maven and s2i-java-11 cluster tasks
to test, build and deploy java/spring application.

For more info on pipelines see pipelines-tutorial at
https://github.com/openshift/pipelines-tutorial

```bash
oc new-project tekton-spring-dev

git clone https://github.com/rh-telco-tigers/tekton-demos.git
cd tekton-demos/pipeline-spring/

oc create -f 01_deploy_rest_http_example.yaml
oc create -f 02_persistent_volume_claim.yaml
oc create -f 03_pipeline.yaml

./run-pipeline.sh
```
