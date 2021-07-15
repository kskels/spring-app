node ('maven') {

    stage('Preamble') {
        sh 'oc delete all -l app=spring-app -n spring-apps-dev'
        sh 'oc delete all -l app=spring-app -n spring-apps-staging'
    }

    stage('Checkout') {
        git credentialsId: 'gitea-user-pass', branch: 'main',
          url: 'https://gitea.apps.ocp4.kskels.com/demos/spring-app.git'
    }

    stage('Maven Goals') {
        sh 'mvn test package'
    }

    stage('SonarQube Analysis') {
        withSonarQubeEnv(credentialsId: 'sonarqube-token',
                         installationName: 'sonarqube') {
            sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.7.0.1746:sonar'
        }
    }

    stage('Publish') {
        // Archive artifacts in Nexus Repository Manager
        // https://www.jenkins.io/doc/pipeline/steps/nexus-jenkins-plugin/
        nexusPublisher nexusInstanceId: 'nexus',
          nexusRepositoryId: 'maven-releases',
          packages: [[
            $class: 'MavenPackage',
            mavenAssetList: [[
              classifier: '', extension: '',
              filePath: 'target/spring-app-0.0.1-SNAPSHOT.jar'
            ]],
            mavenCoordinate: [
              artifactId: 'spring-app',
              groupId: 'demos',
              packaging: 'jar',
              version: '0.0.1'
            ]
          ]]
    }

    stage('Setup BuildConfig') {
        // Use binary s2i build to enable building from Java JAR
        // https://docs.openshift.com/container-platform/4.7/cicd/builds/understanding-image-builds.html

        // The build is configured to publish images to external registry
        // output:
        //   to:
        //     kind: DockerImage
        //     name: docker.apps.ocp4.kskels.com/demos/spring-app:latest
        sh 'oc apply -f k8s/'
    }

    stage('Build Image') {
        sh '''oc start-build spring-app --follow \
                  --from-file=target/spring-app-0.0.1-SNAPSHOT.jar'''
    }

    stage('Deploy') {
        sh 'oc tag docker.apps.ocp4.kskels.com/demos/spring-app:latest spring-apps-dev/spring-app:latest'

        sh 'oc new-app spring-app -n spring-apps-dev'
        sh 'oc rollout status deploy/spring-app -n spring-apps-dev'
        sh 'oc create route edge spring-app --service spring-app -n spring-apps-dev'
    }

    stage('Integration Tests') {
        // add simple curl tests
    }

    stage('Promote') {
        sh 'oc tag docker.apps.ocp4.kskels.com/demos/spring-app:latest spring-apps-staging/spring-app:latest'

        sh 'oc new-app spring-app -n spring-apps-staging'
        sh 'oc rollout status deploy/spring-app -n spring-apps-staging'
        sh 'oc create route edge spring-app --service spring-app -n spring-apps-staging'
    }

}
