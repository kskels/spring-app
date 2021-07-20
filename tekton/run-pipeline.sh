tkn pipeline start build-and-deploy-spring-app \
    -w name=shared-workspace,volumeClaimTemplateFile=03_persistent_volume_claim.yaml \
    -w name=maven-settings,secret="maven-settings" \
    -p deployment-name=spring-app \
    -p git-url=https://gitea.apps.ocp4.kskels.com/demos/spring-app.git \
    -p IMAGE=docker.apps.ocp4.kskels.com/spring-app
