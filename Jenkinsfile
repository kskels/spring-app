node ('maven') {

    stage('Clean Up') {
        sh 'oc delete all -l app=spring-app -n spring-apps-dev'
        sh 'oc delete all -l app=spring-app -n spring-apps-staging'
    }

    stage('Checkout') {
        git credentialsId: 'gitea-user-pass', branch: 'main',
          url: 'https://gitea.apps.ocp4.kskels.com/demos/spring-app.git'
    }

    stage('Package') {
        sh 'mvn package'
    }

    stage('Publish') {
        nexusPublisher nexusInstanceId: 'nexus',
            nexusRepositoryId: 'maven-releases',
            packages: [[$class: 'MavenPackage',
                        mavenAssetList: [[classifier: '', extension: '',
                                          filePath: 'target/spring-app-0.0.1-SNAPSHOT.jar']],
                        mavenCoordinate: [artifactId: 'spring-app',
                                          groupId: 'demos',
                                          packaging: 'jar',
                                          version: '0.0.1']]]
    }


    stage('Setup Build') {
        sh 'oc apply -f k8s/'
    }

    stage('Build') {
        sh 'oc start-build spring-app --from-file=target/spring-app-0.0.1-SNAPSHOT.jar --follow'
    }

    stage('Deploy') {
        sh 'oc tag devops-tools-jenkins/spring-app:latest spring-apps-dev/spring-app:latest'

        sh 'oc new-app spring-app -n spring-apps-dev'
        sh 'oc rollout status deploy/spring-app -n spring-apps-dev'
        sh 'oc create route edge spring-app --service spring-app -n spring-apps-dev'
    }

    stage('Tests') {
        // add simple curl tests
    }

    stage('Promote') {
        sh 'oc tag spring-apps-dev/spring-app:latest spring-apps-staging/spring-app:latest'

        sh 'oc new-app spring-app -n spring-apps-staging'
        sh 'oc rollout status deploy/spring-app -n spring-apps-staging'
        sh 'oc create route edge spring-app --service spring-app -n spring-apps-staging'
    }

}
