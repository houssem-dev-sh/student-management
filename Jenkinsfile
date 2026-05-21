pipeline {
    agent any

    tools {
        maven 'maven3'
        jdk 'java21'
      
    }

    environment {
        SONAR_PROJECT_KEY = 'student-management'
        SONAR_TOKEN = credentials('sonar-token')
        DOCKERHUB_CREDENTIALS = credentials('dockerhub1')
        DOCKERHUB_USERNAME = 'houssem26102001'
        BACKEND_IMAGE = "${DOCKERHUB_USERNAME}/student-backend"
        FRONTEND_IMAGE = "${DOCKERHUB_USERNAME}/student-frontend"
    }

    stages {

        stage('📥 Checkout') {
            steps {
                git credentialsId: 'github-credentials',
                    url: 'https://github.com/houssem-dev-sh/student-management.git',
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
                withSonarQubeEnv('sonar') {
                    sh '''mvn sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml'''
                }
            }
        }
        
        stage('⏳ Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
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

       /* stage('🛡️ OWASP Dependency Check') {
            steps {
                dir('.') {
                    sh '''
                        mvn org.owasp:dependency-check-maven:check \
                        -DnvdApiKey=53ae4c6f-a483-4aaf-89f3-b50c7d0cf896 \
                        -DfailBuildOnCVSS=9 \
                        -Dformat=HTML || true
                    '''
                }
            }
        }*/
        stage('🐳 Docker Build Backend') {
            steps {
                sh "docker build -t ${BACKEND_IMAGE}:latest ."
                echo "✅ Backend image built: ${BACKEND_IMAGE}:latest"
            }
        }

        stage('🐳 Docker Build Frontend') {
            steps {
                dir('student-frontend-react') {
                    sh "docker build -t ${FRONTEND_IMAGE}:latest ."
                    echo "✅ Frontend image built: ${FRONTEND_IMAGE}:latest"
                }
            }
        }

        stage('🔒 Trivy Scan Backend') {
            steps {
                sh """
                    trivy image \
                        --severity LOW,MEDIUM,HIGH,CRITICAL \
                        --format table \
                        --exit-code 0 \
                        ${BACKEND_IMAGE}:latest \
                        > trivy-backend-report.txt 2>&1 || true
                    cat trivy-backend-report.txt
                """
            }
        }

        stage('🔒 Trivy Scan Frontend') {
            steps {
                sh """
                    trivy image \
                        --severity LOW,MEDIUM,HIGH,CRITICAL \
                        --format table \
                        --exit-code 0 \
                        ${FRONTEND_IMAGE}:latest \
                        > trivy-frontend-report.txt 2>&1 || true
                    cat trivy-frontend-report.txt
                """
            }
        }

        stage('📤 Push DockerHub') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login \
                        -u "$DOCKERHUB_CREDENTIALS_USR" \
                        --password-stdin

                    docker push ${BACKEND_IMAGE}:latest
                    docker push ${FRONTEND_IMAGE}:latest

                    docker logout
                '''

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
