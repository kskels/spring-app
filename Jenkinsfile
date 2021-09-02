// Jenkins CI/CD flow on OpenShift for Spring Boot Application.
// See following repo for more extensive and complete examples
// https://github.com/siamaksade/openshift-jenkins-demo

def CICD_PROJECT = 'spring-apps-cicd'
def DEV_PROJECT = 'spring-apps-dev'
def STAGING_PROJECT = 'spring-apps-staging'

def NEXUS_IMAGE_URL = 'docker.apps.ocp4.kskels.com/demos/spring-app'
def GITEA_REPO_URL = 'https://gitea.apps.ocp4.kskels.com/demos/spring-app.git'


node ('maven') {

    stage('Preamble') {
        sh "oc delete all -l app=spring-app -n ${DEV_PROJECT}"
        sh "oc delete all -l app=spring-app -n ${STAGING_PROJECT}"
    }

    stage('Checkout') {
        git credentialsId: 'gitea-creds', branch: 'main', url: GITEA_REPO_URL
    }

    stage('Build Maven Package') {
        sh 'mvn test package'
    }

    stage('Archive Artifacts in Nexus') {
        configFileProvider([configFile(fileId: 'maven-settings',
                                       variable: 'MAVEN_SETTINGS')]) {
            sh 'mvn -s $MAVEN_SETTINGS -DskipTests=true deploy'
        }
    }

    stage('SonarQube Analysis') {
        withSonarQubeEnv(credentialsId: 'sonarqube-token',
                         installationName: 'sonarqube') {
            sh 'mvn sonar:sonar'
        }
    }

    stage('Setup BuildConfig') {
        // Use binary s2i build to enable building from Java JAR
        // https://docs.openshift.com/container-platform/4.7/cicd/builds/understanding-image-builds.html

        // The build is configured to publish images to external registry
        // output:
        //   to:
        //     kind: DockerImage
        //     name: docker.apps.ocp4.kskels.com/spring-app:latest
        sh 'oc apply -f k8s/'
    }

    stage('Trigger Image Build') {

        def buildCmd = '''oc start-build spring-app -o name \
                              --from-file=target/spring-app-0.0.1-SNAPSHOT.jar'''

        def output = sh (script: buildCmd, returnStdout: true)
        sh "oc logs -f ${output}"

        sh "oc tag ${NEXUS_IMAGE_URL}:latest spring-app:latest"
    }

    stage('Deploy to Dev') {
        sh "oc tag spring-app:latest ${DEV_PROJECT}/spring-app:latest"

        sh "oc new-app spring-app -n ${DEV_PROJECT}"
        sh """oc set probe deploy/spring-app -n ${DEV_PROJECT} \
                  --readiness --get-url=http://:8080/"""

        sh "oc rollout status deploy/spring-app -n ${DEV_PROJECT}"
    }

    stage('Integration Tests') {

        sh 'sleep 4'
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
        sh "oc tag spring-app:latest ${STAGING_PROJECT}/spring-app:latest"

        sh "oc new-app spring-app -n ${STAGING_PROJECT}"
        sh "oc rollout status deploy/spring-app -n ${STAGING_PROJECT}"
        sh "oc create route edge spring-app --service spring-app -n ${STAGING_PROJECT}"

        sh "oc get route spring-app -n ${STAGING_PROJECT}"
    }

}
