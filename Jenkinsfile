node ('maven') {

    stage('Preamble') {
        sh 'oc delete all -l app=spring-app -n spring-apps-dev'
        sh 'oc delete all -l app=spring-app -n spring-apps-staging'
    }

    stage('Checkout') {
        git credentialsId: 'gitea-creds', branch: 'main',
          url: 'https://gitea.apps.ocp4.kskels.com/demos/spring-app.git'
    }

    stage('Build Maven Package') {
        sh 'mvn test package'
    }

    stage('SonarQube Analysis') {
        withSonarQubeEnv(credentialsId: 'sonarqube-token',
                         installationName: 'sonarqube') {
            sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.7.0.1746:sonar'
        }
    }

    stage('Archive Artifacts in Nexus') {
        // See more details about the plugin at
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

    stage('Trigger Image Build') {
        openshift.withCluster() {
          openshift.withProject('spring-apps-dev') {
            openshift.selector("bc", "spring-app").startBuild("--from-file=target/spring-app-0.0.1-SNAPSHOT.jar", "--wait=true")
          }
        }

        sh 'oc tag docker.apps.ocp4.kskels.com/demos/spring-app:latest spring-app:latest'
    }

    stage('Deploy to Dev') {
        sh 'oc tag spring-app:latest spring-apps-dev/spring-app:latest'

        sh 'oc new-app spring-app -n spring-apps-dev'
        sh '''oc set probe deploy/spring-app -n spring-apps-dev \
                  --readiness --get-url=http://:8080/'''

        sh 'oc rollout status deploy/spring-app -n spring-apps-dev'
    }

    stage('Integration Tests') {

        def output = sh (
          script: 'curl http://spring-app.spring-apps-dev:8080/',
          returnStdout: true
        )

        assert output == 'Hello World!'
    }

    // stage('Approval for Staging') {
    //     timeout(time: 30, unit: 'DAYS') {
    //         input message: "Start deployment to Staging?"
    //     }
    // }

    stage('Promote to Staging') {
        sh 'oc tag spring-app:latest spring-apps-staging/spring-app:latest'

        sh 'oc new-app spring-app -n spring-apps-staging'
        sh 'oc rollout status deploy/spring-app -n spring-apps-staging'
        sh 'oc create route edge spring-app --service spring-app -n spring-apps-staging'

        sh 'oc get route spring-app -n spring-apps-staging'
    }

}
