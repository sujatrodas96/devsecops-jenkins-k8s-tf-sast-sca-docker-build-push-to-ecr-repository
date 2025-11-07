pipeline {
    agent any

    tools { 
        maven 'Maven_3_8_4'  
    }

    environment {
        AWS_REGION = 'us-east-1'
        ECR_URL = '257278359774.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'asg'
        IMAGE_TAG = "${BUILD_NUMBER}" // Use build number instead of 'latest'
    }

    stages {
        stage('Cleanup Old Builds') {
            steps {
                script {
                    echo 'Cleaning up old builds...'
                    sh '''
                    # Clean Maven
                    mvn clean
                    
                    # Remove old Docker images
                    docker rmi ${ECR_URL}/${IMAGE_NAME}:latest || true
                    docker system prune -f
                    '''
                }
            }
        }

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
                    echo "Building Docker image with tag: ${IMAGE_TAG}"
                    sh """
                    docker build --no-cache -t ${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG} ${ECR_URL}/${IMAGE_NAME}:latest
                    """
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
                    sh """
                    docker push ${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${ECR_URL}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withKubeConfig([credentialsId: 'kubelogin']) {
                    sh """
                    # Delete existing deployment to force fresh pull
                    kubectl delete deployment asgbuggy-deployment -n devsecops --ignore-not-found=true
                    
                    # Wait for deletion
                    sleep 10
                    
                    # Apply deployment with new image
                    kubectl apply -f deployment.yaml -n devsecops
                    
                    # Wait for rollout
                    kubectl rollout status deployment/asgbuggy-deployment -n devsecops
                    
                    # Verify pods are running
                    kubectl get pods -n devsecops -l app=asgbuggy
                    """
                }
            }
        }

        stage ('wait_for_testing'){
          steps {
            sh 'pwd; sleep 180; echo "Application Has been deployed on K8S"'
            }
          }
          
        stage('RunDASTUsingZAP') {
                steps {
              withKubeConfig([credentialsId: 'kubelogin']) {
              sh('zap.sh -cmd -quickurl http://$(kubectl get services/asgbuggy --namespace=devsecops -o json| jq -r ".status.loadBalancer.ingress[] | .hostname") -quickprogress -quickout ${WORKSPACE}/zap_report.html')
              archiveArtifacts artifacts: 'zap_report.html'
              }
            }
       } 
    }

    
    post {
        always {
            echo 'Pipeline execution completed'
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}