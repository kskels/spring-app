// Jenkins CI/CD flow on OpenShift for Spring Boot Application.
// See following repo for more extensive and complete examples
// https://github.com/siamaksade/openshift-jenkins-demo
//
// The pipeline is using OpenShift client plugin, see documenation at
// https://github.com/jenkinsci/openshift-client-plugin

def CICD_PROJECT = 'spring-apps-cicd'
def DEV_PROJECT = 'spring-apps-dev'
def STAGING_PROJECT = 'spring-apps-staging'

def GITEA_REPO_URL = 'https://github.com/kskels/spring-app.git'
def MAVEN_SETTINGS = '/tmp/maven/settings.xml'

def APP_VERSION = ''

node ('maven-11') {

    print "My test value: ${params.TEST_PARAM}"

    stage('Preamble') {
        sh "oc delete deploy/spring-app -n ${DEV_PROJECT} || true"
        sh "oc delete service/spring-app -n ${DEV_PROJECT} || true"

        sh "oc delete deploy/spring-app -n ${STAGING_PROJECT} || true"
        sh "oc delete service/spring-app -n ${STAGING_PROJECT} || true"
        sh "oc delete route/spring-app -n ${STAGING_PROJECT} || true"
    }

    // Use specific image from Red Hat catalog
    // registry.redhat.io/ubi8/openjdk-11
    container('maven') {
        stage('Checkout') {
            git credentialsId: 'gitea-creds', branch: 'main', url: GITEA_REPO_URL
        }

        stage('Check Version') {
            APP_VERSION = sh script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout',
                             returnStdout: true
            print "Version of the Spring App -> ${APP_VERSION}"
        }

        stage('Build Maven Package') {
            sh 'mvn test package'
        }

        stage('Archive Artifacts in Nexus') {
            sh "mvn -s $MAVEN_SETTINGS -DskipTests=true deploy"
        }

        stage('SonarQube Analysis') {
            withSonarQubeEnv(credentialsId: 'sonarqube-token',
                             installationName: 'sonarqube') {
                sh 'mvn sonar:sonar'
            }
        }
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
            openshift.withProject(CICD_PROJECT) {

                openshift.selector("bc", "spring-app").startBuild(
                    "--from-file=target/spring-app-${APP_VERSION}.jar", "--wait=true")
            }
        }
    }

    stage('Deploy to Dev') {
        openshift.withCluster() {
            openshift.withProject(DEV_PROJECT) {

                openshift.tag("${CICD_PROJECT}/spring-app:latest",
                    "${DEV_PROJECT}/spring-app:latest")

                def app = openshift.newApp('spring-app:latest')

                // Setting up http://:8080/ readiness probe
                def dcpatch = [
                    "metadata":[
                        "name":"spring-app",
                        "namespace":"${DEV_PROJECT}"
                    ],
                    "apiVersion":"apps/v1",
                    "kind":"Deployment",
                    "spec":[
                        "template":[
                            "spec":[
                                "containers":[[
                                    "name":"spring-app",
                                    "readinessProbe":[
                                        "failureThreshold":3,
                                        "httpGet": [
                                            "path":"/",
                                            "port":8080,
                                            "scheme": "HTTP"
                                        ]
                                    ]
                                ]]
                            ]
                        ]
                    ]
                ]

                openshift.apply(dcpatch)
                openshift.selector("deploy", "spring-app").rollout().status()
            }
        }
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
        openshift.withCluster() {
            openshift.withProject(STAGING_PROJECT) {

                openshift.tag("${CICD_PROJECT}/spring-app:latest",
                    "${STAGING_PROJECT}/spring-app:staging")

                openshift.newApp('spring-app:staging')
                openshift.selector("deploy", "spring-app").rollout().status()
            }
        }

        sh 'oc create route edge spring-app --service spring-app -n spring-apps-staging'
        sh 'oc get route spring-app -n spring-apps-staging'
    }
}
