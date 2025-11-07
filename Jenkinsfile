pipeline 
{
    agent any

    tools 
    { 
        maven 'Maven_3_8_4'  
    }

    environment 
    {
        AWS_REGION = 'us-east-1'
        ECR_URL = '257278359774.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'asg'
    }

    stages 
    {
          stage('SonarQube Analysis') 
          {
              steps 
              {	
                  sh '''
                  mvn clean verify sonar:sonar \
                  -Dsonar.projectKey=testsonarcube123_testsonarcube123 \
                  -Dsonar.organization=testsonarcube123 \
                  -Dsonar.host.url=https://sonarcloud.io \
                  -Dsonar.token=135c73e8365098d532c082bab56778fbd77ad07d
                  '''
              }
          }

          stage('Build Docker Image') 
          { 
              steps { 
                  withDockerRegistry([credentialsId: 'dockerlogin', url: '']) {
                      script {
                          def app = docker.build("${ECR_URL}/${IMAGE_NAME}")
                      }
                  }
              }
          }

          stage('Push to AWS ECR') 
          {
              steps {
                  script {
                      docker.withRegistry("https://${ECR_URL}", 'ecr:us-east-1:aws-credentials') {
                          def app = docker.image("${ECR_URL}/${IMAGE_NAME}")
                          app.push("latest")
                      }
                  }
              }
          }

          stage('Kubernetes Deployment of ASG Bugg Web Application') 
          {
            steps 
            {
                withKubeConfig([credentialsId: 'kubelogin']) 
                {
                        sh('kubectl delete all --all -n devsecops')
                        sh ('kubectl apply -f deployment.yaml --namespace=devsecops')
                }
            }
          }
      }
  }
