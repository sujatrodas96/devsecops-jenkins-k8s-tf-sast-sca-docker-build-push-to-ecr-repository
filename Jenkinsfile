pipeline {
    agent any

    tools { 
        maven 'Maven_3_8_4'  
    }

    environment {
        AWS_REGION = 'us-east-1'
        ECR_URL = '257278359774.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'asg'
        IMAGE_TAG = "${BUILD_NUMBER}"
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
                    kubectl delete deployment asgbuggy-deployment -n devsecops --ignore-not-found=true
                    
                    sleep 10
                    
                    kubectl apply -f deployment.yaml -n devsecops
                    
                    kubectl rollout status deployment/asgbuggy-deployment -n devsecops

                    kubectl get pods -n devsecops -l app=asgbuggy
                    """
                }
            }
        }

        stage('Wait for Application Startup') {
            steps {
                script {
                    echo 'Waiting for application to be fully ready...'
                    sh 'sleep 180'
                    echo 'Application has been deployed on K8S and should be ready'
                }
            }
        }
          
        stage('OWASP ZAP DAST Scan') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'kubelogin']) {
                        // Get the application URL
                        def appUrl = sh(
                            script: '''
                                kubectl get services/asgbuggy --namespace=devsecops -o json | \
                                jq -r '.status.loadBalancer.ingress[] | .hostname'
                            ''',
                            returnStdout: true
                        ).trim()
                        
                        echo "Running OWASP ZAP scan against: http://${appUrl}"
                        
                        sh """
                            # Create reports directory
                            mkdir -p ${WORKSPACE}/zap-reports
                            
                            # Set proper permissions
                            chmod 777 ${WORKSPACE}/zap-reports
                            
                            echo "Starting ZAP scan..."
                            
                            # Run ZAP baseline scan
                            docker run --rm \
                                -v ${WORKSPACE}/zap-reports:/zap/wrk:rw \
                                -u zap \
                                owasp/zap2docker-stable \
                                zap-baseline.py \
                                -t http://${appUrl} \
                                -r zap_report.html \
                                -w zap_report.md \
                                -I || true
                            
                            echo "ZAP scan completed"
                            
                            ls -lah ${WORKSPACE}/zap-reports/
                            
                            if [ -f ${WORKSPACE}/zap-reports/zap_report.html ]; then
                                cp ${WORKSPACE}/zap-reports/zap_report.html ${WORKSPACE}/
                                echo "HTML report copied successfully"
                            else
                                echo "Warning: HTML report not found"
                            fi
                            
                            if [ -f ${WORKSPACE}/zap-reports/zap_report.md ]; then
                                cp ${WORKSPACE}/zap-reports/zap_report.md ${WORKSPACE}/
                                echo "Markdown report copied successfully"
                            else
                                echo "Warning: Markdown report not found"
                            fi
                        """
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap_report.*', allowEmptyArchive: true
                    
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'zap_report.html',
                        reportName: 'ZAP Security Report'
                    ])
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'
            sh 'rm -rf ${WORKSPACE}/zap-reports || true'
        }
        success {
            echo 'Pipeline executed successfully!'
            echo 'DAST scan completed. Check the ZAP Security Report for vulnerabilities.'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}