pipeline {
    agent any

    tools { 
        maven 'Maven_3_8_4'  
    }

    environment {
        AWS_REGION = 'us-east-1'
        ECR_URL = '257278359774.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'asg'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('SonarQube Analysis') {
            steps {	
                sh '''
                mvn clean verify sonar:sonar \
                -Dsonar.projectKey=testsonarcube123_testsonarcube123 \
                -Dsonar.organization=testsonarcube123 \
                -Dsonar.host.url=https://sonarcloud.io \
                -Dsonar.token=135c73e8365098d532c082bab56778fbd77ad07d
                '''
            }
        }

        stage('Build Docker Image') { 
            steps { 
                script {
                    sh "docker build -t ${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                script {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_URL}
                    """
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    sh "docker push ${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: 'kubelogin']) {
                    // Update image in deployment.yaml dynamically
                    sh """
                    kubectl set image deployment/asgbuggy-deployment \
                    asgbuggy=${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG} \
                    -n devsecops
                    kubectl rollout status deployment/asgbuggy-deployment -n devsecops
                    """
                }
            }
        }
    }
}
