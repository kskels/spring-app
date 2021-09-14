tkn pipeline start build-and-deploy-spring-app \
    -w name=shared-workspace,volumeClaimTemplateFile=persistent_volume_claim.yaml \
    -w name=maven-settings,secret="maven-settings" \
    -p deployment-name=spring-app \
    -p git-url=https://github.com/kskels/spring-app.git\
    -p IMAGE=image-registry.openshift-image-registry.svc:5000/spring-apps-cicd/spring-app
