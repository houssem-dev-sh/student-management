pipeline {
    agent any

    tools {
        maven 'maven3'
        jdk 'java21'
      
    }

    environment {
        SONAR_PROJECT_KEY = 'student-management'
        SONAR_TOKEN = credentials('sonar-token')
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
                    -DfailBuildOnCVSS=9 \
                    -Dformat=HTML \
                    || true'''
            }
        }

        stage('🔒 Trivy Scan') {
            steps {
                sh 'trivy fs --severity HIGH,CRITICAL --format table . > trivy-report.txt'
                sh 'cat trivy-report.txt'
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
    }
}
