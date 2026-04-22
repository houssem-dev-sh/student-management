pipeline {
    agent any

    tools {
        maven 'maven3'
        jdk 'java21'
      
    }

    environment {
        SONAR_PROJECT_KEY = 'student-management'
        SONAR_TOKEN = credentials('sonar-token')
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_USERNAME = 'sara3006lab'
        BACKEND_IMAGE = "${DOCKERHUB_USERNAME}/student-backend"
        FRONTEND_IMAGE = "${DOCKERHUB_USERNAME}/student-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('📥 Checkout') {
            steps {
                git credentialsId: 'github-credentials',
                    url: 'https://github.com/sara3006-lab/student-management',
                    branch: 'main'
            }
        }

        stage('🔨 Build Backend') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('🧪 Tests Backend') {
            steps {
                sh 'mvn test jacoco:report'
            }
        }

        stage('🔍 SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''mvn sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml'''
                }
            }
        }

        stage('⏳ Quality Gate') {
            steps {
                script {
                    sleep(time: 15, unit: 'SECONDS')
                    def qg = sh(
                        script: '''curl -s "http://localhost:9000/api/qualitygates/project_status?projectKey=student-management" \
                        -u admin:admin1 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['projectStatus']['status'])"''',
                        returnStdout: true
                    ).trim()
                    echo "Quality Gate: ${qg}"
                    if (qg == 'ERROR') {
                        error "Quality Gate failed: ${qg}"
                    } else {
                        echo "Quality Gate passed: ${qg}"
                    }
                }
            }
        }

        stage('🔨 Build Frontend') {
            steps {
                dir('student-frontend-react') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }

        stage('🧪 Tests Frontend') {
            steps {
                dir('student-frontend-react') {
                     sh 'npm install'
                     sh 'npm test -- --watchAll=false --passWithNoTests || true'
                }
            }
        }

        stage('🛡️ OWASP Dependency Check') {
            steps {
                dir('student-frontend-react') {
                     sh 'npm audit --json > npm-audit-report.json || true'
                     sh 'cat npm-audit-report.json'
            }
            sh '''mvn org.owasp:dependency-check-maven:check \
                -DnvdApiKey=53ae4c6f-a483-4aaf-89f3-b50c7d0cf896 \
                -DfailBuildOnCVSS=9 \
                -Dformat=HTML \
                || true'''
            }
        }
        stage('🐳 Docker Build Backend') {
            steps {
                sh "docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} ."
                sh "docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${BACKEND_IMAGE}:latest"
                echo "✅ Backend image built: ${BACKEND_IMAGE}:${IMAGE_TAG}"
            }
        }

        stage('🐳 Docker Build Frontend') {
            steps {
                dir('student-frontend-react') {
                    sh "docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} ."
                    sh "docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${FRONTEND_IMAGE}:latest"
                    echo "✅ Frontend image built: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                }
            }
        }

        stage('🔒 Trivy Scan Backend') {
            steps {
                sh """
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --format table \
                        --exit-code 0 \
                        ${BACKEND_IMAGE}:${IMAGE_TAG} \
                        > trivy-backend-report.txt 2>&1 || true
                    cat trivy-backend-report.txt
                """
            }
        }

        stage('🔒 Trivy Scan Frontend') {
            steps {
                sh """
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --format table \
                        --exit-code 0 \
                        ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                        > trivy-frontend-report.txt 2>&1 || true
                    cat trivy-frontend-report.txt
                """
            }
        }

        stage('📤 Push DockerHub') {
            steps {
                sh "echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin"
                sh "docker push ${BACKEND_IMAGE}:${IMAGE_TAG}"
                sh "docker push ${BACKEND_IMAGE}:latest"
                sh "docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                sh "docker push ${FRONTEND_IMAGE}:latest"
                echo "✅ Images pushed to DockerHub !"
            }
        }

    }


    post {
        success {
            echo '✅ Pipeline réussi !'
        }
        failure {
            echo '❌ Pipeline échoué !'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
