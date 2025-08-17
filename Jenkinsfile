pipeline {
    agent {
        kubernetes {
            label 'kaniko'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-admin
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: aws-secret
      mountPath: /kaniko/.aws/
  - name: git
    image: alpine/git:latest
    command:
    - cat
    tty: true
  volumes:
  - name: aws-secret
    secret:
      secretName: aws-credentials
"""
        }
    }
    
    environment {
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
        ECR_REPOSITORY = "lesson-7-django-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        AWS_DEFAULT_REGION = "us-east-1"
        GIT_REPO = "https://github.com/ViktorSvertoka/devops-ci-cd.git"
        GIT_BRANCH = "devops-ci-cd"
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                container('git') {
                    script {
                        sh """
                            git clone -b lesson-4 ${GIT_REPO} django-source
                            ls -la django-source/
                        """
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('kaniko') {
                    script {
                        sh """
                            echo "Building Docker image with tag: ${IMAGE_TAG}"
                            /kaniko/executor \\
                                --context=dir://django-source/ \\
                                --dockerfile=django-source/Dockerfile \\
                                --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \\
                                --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:latest \\
                                --cache=true \\
                                --cache-ttl=24h
                        """
                    }
                }
            }
        }
        
        stage('Update Helm Chart') {
            steps {
                container('git') {
                    script {
                        withCredentials([
                            string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')
                        ]) {
                            sh """
                                # Configure git
                                git config --global user.name "Jenkins CI"
                                git config --global user.email "jenkins@ci.com"
                                
                                # Clone the infrastructure repository
                                git clone https://\${GITHUB_TOKEN}@github.com/ViktorSvertoka/devops-ci-cd.git infra-repo
                                cd infra-repo
                                git checkout ${GIT_BRANCH}
                                
                                # Update image tag in values.yaml
                                sed -i 's|tag: ".*"|tag: "${IMAGE_TAG}"|g' charts/django-app/values.yaml
                                
                                # Verify the change
                                echo "Updated values.yaml:"
                                grep -A 5 -B 5 'tag:' charts/django-app/values.yaml
                                
                                # Commit and push changes
                                git add charts/django-app/values.yaml
                                git commit -m "Update Django image tag to ${IMAGE_TAG} [skip ci]"
                                git push origin ${GIT_BRANCH}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Trigger ArgoCD Sync') {
            steps {
                container('git') {
                    script {
                        sh """
                            echo "Image pushed successfully!"
                            echo "ECR Image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                            echo "Helm chart updated with new image tag: ${IMAGE_TAG}"
                            echo "ArgoCD will automatically sync the changes from Git repository"
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully!"
            echo "Docker image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
            echo "ArgoCD will deploy the updated application automatically"
        }
        failure {
            echo "Pipeline failed! Check the logs above."
        }
        always {
            cleanWs()
        }
    }
}