# k8s-devsecops-training
## Module-0: Environment Setup
### Cloud9 IDE
You will do majority of your work via AWS Cloud9, a cloud-based integrated development environment (IDE) that lets you write, run, and debug your code with just a browser.
1. Open the [AWS Cloud9 console](https://ap-southeast-1.console.aws.amazon.com/cloud9control/home?region=ap-southeast-1#/)
2. Click on **Create Environment** to create a new IDE
3. Give name to your Cloud9 IDE.
4. Pick **t3.small** for instance type
5. Click **Create**

You will need to give your IDE an IAM role to be able to provision resources in AWS
1. Open the [EC2 console](https://ap-southeast-1.console.aws.amazon.com/ec2/home?region=ap-southeast-1#Instances:instanceState=running)
2. Select the instance of you Cloud9 IDE, then pick **Actions**, **Security** then **Modify IAM role**
3. Select the IAM Role (will be giving during the training)

Disable Cloud9 temporary credential
1. Open the [AWS Cloud9 console](https://ap-southeast-1.console.aws.amazon.com/cloud9control/home?region=ap-southeast-1#/)
2. Click **Open** for your Cloud9 IDE 
3. Click **gear icon** on the top right of your IDE
4. Select **AWS Settings**
5. Disable AWS managed temporary credentials

### Clone Training Resources
```bash
git clone https://github.com/rimaulana/k8s-devsecops-training.git
```

### Swithing to stage1
```bash
git checkout stage1
```

### Configure dependencies
```bash
cd k8s-devsecops-training
chmod +x setup.sh
./setup.sh
```

### Provision AWS Resources
All resources will be provision in AWS us-east-1 region
```bash
terraform init
terraform apply
```

### Clone app and config repo
Two new CodeCommit repositories will be created, clone them
```bash
cd ~/environment/
git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/k8s-devsecops-training-app
git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/k8s-devsecops-training-config
```

### Create main branch on config repo
```bash
cd ~/environment/k8s-devsecops-training-config
git checkout -b main
cp -r ../k8s-devsecops-training/config/* .
git add .
git commit -m "initial commit"
git push origin main
```

### Create main and dev branches on app repo
```bash
cd ~/environment/k8s-devsecops-training-app
git checkout -b main
touch README.md
git add .
git commit -m "initial commit"
git push origin main

git checkout -b dev
cp -r ../k8s-devsecops-training/app/* .
git add .
git commit -m "initial commit"
git push origin dev
```

## Module-1: Dockerfile linting using Hadolint
Now that the pipeline is setup, it is time to start integrating security testing by doing Dockerfile linting using hadolint.

### Create buildspec file
1. Open **buildspec_dockerfile.yml** inside config repo
2. Make sure it has the following content
```yaml
version: 0.2

phases:
    pre_build:
        commands:
        - echo "Copying hadolint.yml to the application directory"
        - cp hadolint.yml $CODEBUILD_SRC_DIR_AppSource/hadolint.yml
        - echo "Switching to the application directory"
        - cd $CODEBUILD_SRC_DIR_AppSource
        - echo "Pulling the hadolint docker image"
        - docker pull public.ecr.aws/rimaulana/hadolint:v1.16.2
    build:
        commands:
        - echo "Build started on $(date)"
        - echo "Scanning with Hadolint..."        
        - result=`docker run --rm -i -v ${PWD}/hadolint.yml:/.hadolint.yaml public.ecr.aws/rimaulana/hadolint:v1.16.2 hadolint -f json - < Dockerfile`
    post_build:
        commands:
        - echo "Lint Results:"
        - echo $result | jq . 
        - aws ssm put-parameter --name "codebuild-dockerfile-results" --type "String" --value "$result" --overwrite
        - echo Build completed on `date`
```

### Add the Hadolint configuration
1. Open **hadolint.yml** inside config repo
2. Make sure it has the following content
```yaml
ignored: 
- DL3000 
- DL3025 

trustedRegistries: 
- public.ecr.aws
```

## Module-02: Secrets Scanning using Trufflehog
Next step is identifying whether there is any secrets leak within the code repository using trufflehog

### Create buildspec file
1. Open **buildspec_secrets.yml** inside config repo
2. Make sure it has the following content
```yaml
version: 0.2

phases:
  pre_build:
    commands:
    - echo "Setting CodeCommit Credentials"
    - git config --global credential.helper '!aws codecommit credential-helper $@'
    - git config --global credential.UseHttpPath true
    - echo "Copying secrets_config.json to the application directory"
    - cp secrets_config.json $CODEBUILD_SRC_DIR_AppSource/secrets_config.json
    - echo "Switching to the application directory"
    - echo "Installing truffleHog"
    - which pip3 && pip3 --version
    - which python3 && python3 --version
    - pip3 install 'truffleHog>=2.1.0,<3.0'
  build:
    commands:
    - echo "Build started on $(date)"
    - echo "Scanning with truffleHog..."
    - trufflehog --regex --rules secrets_config.json --entropy=False --max_depth 1 "$APP_REPO_URL"
  post_build:
    commands:
    - echo "Build completed on $(date)"
```

### Add the trufflehog regex configuration
1. Open **secrets_config.json** inside config repo
2. Make sure it has the following content
```json
{
    "Slack Token": "(xox[p|b|o|a]-[0-9]{12}-[0-9]{12}-[0-9]{12}-[a-z0-9]{32})",
    "RSA private key": "-----BEGIN RSA PRIVATE KEY-----",
    "SSH (OPENSSH) private key": "-----BEGIN OPENSSH PRIVATE KEY-----",
    "SSH (DSA) private key": "-----BEGIN DSA PRIVATE KEY-----",
    "SSH (EC) private key": "-----BEGIN EC PRIVATE KEY-----",
    "PGP private key block": "-----BEGIN PGP PRIVATE KEY BLOCK-----",
    "Facebook Oauth": "[f|F][a|A][c|C][e|E][b|B][o|O][o|O][k|K].*['|\"][0-9a-f]{32}['|\"]",
    "Twitter Oauth": "[t|T][w|W][i|I][t|T][t|T][e|E][r|R].*['|\"][0-9a-zA-Z]{35,44}['|\"]",
    "GitHub": "[g|G][i|I][t|T][h|H][u|U][b|B].*['|\"][0-9a-zA-Z]{35,40}['|\"]",
    "Google Oauth": "(\"client_secret\":\"[a-zA-Z0-9-_]{24}\")",
    "AWS API Key": "AKIA[0-9A-Z]{16}",
    "Heroku API Key": "[h|H][e|E][r|R][o|O][k|K][u|U].*[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}",
    "Generic Secret": "[s|S][e|E][c|C][r|R][e|E][t|T].*['|\"][0-9a-zA-Z]{32,45}['|\"]",
    "Generic API Key": "[a|A][p|P][i|I][_]?[k|K][e|E][y|Y].*['|\"][0-9a-zA-Z]{32,45}['|\"]",
    "Slack Webhook": "https://hooks.slack.com/services/T[a-zA-Z0-9_]{8}/B[a-zA-Z0-9_]{8}/[a-zA-Z0-9_]{24}",
    "Google (GCP) Service-account": "\"type\": \"service_account\"",
    "Twilio API Key": "SK[a-z0-9]{32}",
    "Password in URL": "[a-zA-Z]{3,10}://[^/\\s:@]{3,20}:[^/\\s:@]{3,20}@.{1,100}[\"'\\s]"
}
```

## Module-03: Container Image Scanning using ECR
Once a container is created, it needs to be scanned for possible vulnerability introduced via dependencies installed during container image build. We leverage ECR standard scanning to scan the container image

### Create buildspec file
1. Open **buildspec_vuln.yml** inside config repo
2. Make sure it has the following content
```yaml
version: 0.2

phases: 
  pre_build: 
    commands:
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - IMAGE_TAG=`aws ssm get-parameter --name "destinationCommit" --query "Parameter.Value" --output text`
  build: 
    commands:
      - IMAGE=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - docker build $CODEBUILD_SRC_DIR_AppSource -t $IMAGE
      - docker push $IMAGE
  post_build:
    commands:
      - aws ecr start-image-scan --repository-name $IMAGE_REPO_NAME --image-id imageTag=$IMAGE_TAG
      - sleep 5
      - |
        while true
        do
          stat=$(aws ecr describe-images --repository-name $IMAGE_REPO_NAME --image-ids imageTag=$IMAGE_TAG --query imageDetails[0].imageScanStatus.status --output text)
          if [ "$stat" = "COMPLETE" ]; then break; fi
          sleep 5
        done
      - aws ecr describe-image-scan-findings --repository-name $IMAGE_REPO_NAME --image-id imageTag=$IMAGE_TAG > scan_results.json
      - IMAGE_SHA=$(cat scan_results.json | jq -r '.imageId.imageDigest')
      - aws ssm put-parameter --name "imageSHA" --type "String" --value "$IMAGE_SHA" --overwrite
      - |
        stat=0;
        for Item in CRITICAL HIGH MEDIUM LOW INFORMATION UNDEFINED;
          do
            cat scan_results.json |  jq -r --arg threshold $Item '.imageScanFindings.findings[] | select(.severity==$threshold)'
            if cat scan_results.json |  jq -r --arg threshold $Item '.imageScanFindings.findings[] | (.severity==$threshold)' | grep -q true; then stat=$((stat+1)); fi
            if [ "$Item" = "$FAIL_WHEN" ]; then break; fi
          done
        if [ "$stat" -gt "0" ]; then echo "Vulnerabilties Found" && exit 1; fi
```

## Module-04: stage1 Pipeline Testing
### Create a pull reqeust
you can create a pull request via Console or AWS CLI
```bash
aws codecommit create-pull-request \
    --title "Stage1 Run" \
    --description "Please review these changes." \
    --targets repositoryName=k8s-devsecops-training-app,sourceReference=dev,destinationReference=main \
    --region us-east-1
```
OR
1. Open [app repository pull request](https://us-east-1.console.aws.amazon.com/codesuite/codecommit/repositories/k8s-devsecops-training-app/pull-requests?region=us-east-1)
2. Click **Create pull request**
3. Destination is **main** and Source is **dev**, then click **Compare**
4. Give Title and Description then click **Create pull request**

### Fix Dockerfile linting issues
1. Since under **hadolint.yml** we only allow image to be from **public.ecr.aws**  under trusted registry, we cannot image from other repository, by default if we did not define specific repo, it will be pulled from docker hub
2. To adhere the principals of least privileges, your containers should not be running as root. Most containerized processes are application services and therefore don’t require root access.
3. Latest is just a tag you add to an image and is no way dynamic. It can be overwritten and prove difficult to understand what version of the software is installed. Using the latest tag can effect the availability of your application and you should look at using a more explicit tag.
4. Fix your Dockerfile to looks like the following
```Dockerfile
FROM public.ecr.aws/docker/library/python:3.7-alpine

LABEL maintainer="Sasquatch"
RUN adduser sasquatch -D

COPY . /app

WORKDIR /app
RUN pip install -r requirements.txt

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 5000

USER sasquatch

CMD python ./index.py
```

Once changes are made, you will need to push this new changes into remote repository
```bash
cd ~/environment/k8s-devsecops-training-app/
git add Dockerfile
git commit -m "Fixed Dockerfile linting issues."
git push -u origin dev
```
New commit into the dev branch while having an open pull request will trigger the execution of your pipeline

### Remove secrets
Remove secrets that is accidentally added in app index.py, the commit the change into your code repo
```bash
cd ~/environment/k8s-devsecops-training-app/
git add Dockerfile
git commit -m "Removed secrets from index.py"
git push -u origin dev
```
You may notice that the pipeline still failed on secrets stage,  If you look at the commit that's being scanned you'll see that the access key still exists in that commit because it is part of the diff. Make one more commit and you'll see that your build passes the secret scanning stage successfully.

### Improve Pipeline
You notice that the pipeline took long since it is going in a serial manner. However, both Dockerfile linting and Secrets Scanning can go in paraller. To modify your pipeline, switch to stage1-complete branch
```bash
cd ~/environment/k8s-devsecops-training/
git checkout stage1-complete
terraform apply
```

## Module-05: Creating Kubernetes Cluster and the rest of the Pipeline
### Swithing to stage2 and apply terraform
```bash
cd ~/environment/k8s-devsecops-training/
git checkout stage2
terraform apply
```

### Updating kubeconfig
```bash
aws eks update-kubeconfig --name k8s-devsecops-training --region us-east-1
```

### Fixing external-dns
Once you have access to the cluster, make sure to restart exernal-dns pod for it to be able to use IAM Role for Service Account
```bash
kubectl delete pod -n external-dns -l app.kubernetes.io/name=external-dns
```

### Deploy ZAP
ZAP proxy will be deployed as a pod on your kubernetes cluster, we will use helm to deploy ZAP
```bash
cd ~/environment/k8s-devsecops-training/helm/
helm upgrade -i zapproxy -n zap --create-namespace zap/
```

### Configure SonarQube
This step only works on Chrome, You will need to create a project on SonarQube, since all application are exposed via internal load balancer you will need to access them via port-forward
```bash
kubectl port-forward -n sonarqube sonarqube-sonarqube-0 8080:9000
```
On Cloud9 on the top bar, click on **Preview** then **Preview Running Application**. It will give you a blank page, then pick **Pop Out Into New Window** on the right corner of the new blank page

The default username and password for SonarQube is **admin** you will be asked to change this password. Once you are in SonarQube
1. Go to top right on click on **A** symbol then **My Account**
2. Go to **Security** tab
3. Generate new Global Analysis Token
4. Copy the token
5. Open file ~/environment/k8s-devsecops-training/modules/pipeline/main.tf
6. Put the token as the value of **resource "aws_ssm_parameter" "sonar_token"**
7. On the left top of the page click on **Projects** then **Create project manually**
8. Put in **flask-app** as the name of the project then **next**
9. Select **Use the global setting** then **Create project**
10. Select **Locally**
11. Select **Use existing token** then past the global analysis token created on step 3. Click **Continue**
12. On the right click on **Project Settings** then **General Settings**
13. Go to **SCM** tab and slide **Disable the SCM Sensor**
14. Open file ~/environment/k8s-devsecops-training/modules/pipeline/main.tf
15. Put **flask-app** as the value of **resource "aws_ssm_parameter" "sonar_project_key"**
16. Save the file

### Configure ZAP token
1. Open file ~/environment/k8s-devsecops-training/modules/pipeline/main.tf
2. The value for **resource "aws_ssm_parameter" "zap_token"** will be given
3. Save the file

### Updating the Infrastructure
```bash
cd ~/environment/k8s-devsecops-training/
terraform apply
```

## Module-06: Kubernetes Manifest Scanning using kubesec
Now that we are integrating kubernetes deployment using Helm, we will need to make sure that there is no security issue with the Deployment template and ensure it follows best practices.

### Configure new Helm CodeCommit repository
A new Helm CodeCOmmit repository is created on stage2, this repository will be hosting application manifest and will be fed as input into CodeBuild for manifest vulnerability scan
```bash
cd ~/environment/
git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/k8s-devsecops-training-helm
```

### Create main branch for helm repo
```bash
cd ~/environment/k8s-devsecops-training-helm
git checkout -b main
cp -r ../k8s-devsecops-training/helm/* .
git add .
git commit -m "initial commit"
git push origin main
```

### Create buildspec file
1. Create **buildspec_kubesec.yml** inside config repo
2. Make sure it has the following content
```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Installing Helm
      - chmod 700 get_helm.sh
      - ./get_helm.sh --version v3.12.3
      - helm template -s templates/deployment.yaml $CODEBUILD_SRC_DIR_HelmSource/app/ > app.yaml
      - docker pull public.ecr.aws/rimaulana/kubesec:v2
  build:
    commands:
      - echo "Build started on $(date)"
      - echo "Scanning with kubesec..."  
      - result=`docker run --rm -i public.ecr.aws/rimaulana/kubesec:v2 scan /dev/stdin < app.yaml`
  post_build:
    commands:
      - echo "Lint Results:"
      - echo $result | jq . 
      - aws ssm put-parameter --name "codebuild-kubesec-results" --type "String" --value "$result" --overwrite
      - echo Build completed on `date`
```

## Module-07: Code Quality check using SonarQube
We will be using the default configuration for Code Quality in SonarQube, they are called Quality Gate. The default Quality Gate, Sonar Way, complies with the [Clean as You Code](https://docs.sonarsource.com/sonarqube/10.2/user-guide/clean-as-you-code/) methodology, so that you benefit from the most efficient approach to delivering Clean Code.

### Create buildspec file
1. Create **buildspec_sonar.yml** inside config repo
2. Make sure it has the following content
```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.7
  pre_build:
    commands:
      - echo Pulling image
      - docker pull public.ecr.aws/rimaulana/sonar-scanner-cli:v5.0.1
      - pip install -r $CODEBUILD_SRC_DIR_AppSource/requirements.txt
  build:
    commands:
      - aws ssm put-parameter --name "codebuild-sonar-link" --type "String" --value "$SONAR_URL/dashboard?id=$SONAR_PROJECT_KEY" --overwrite
      - |
        docker run \
            --rm \
            -e SONAR_HOST_URL="$SONAR_URL" \
            -e SONAR_SCANNER_OPTS="-Dsonar.projectKey=$SONAR_PROJECT_KEY -Dsonar.python.version=3.7 -Dsonar.qualitygate.wait=true -Dsonar.token=$SONAR_TOKEN" \
            -v "$CODEBUILD_SRC_DIR_AppSource:/usr/src" \
            public.ecr.aws/rimaulana/sonar-scanner-cli:v5.0.1 > scanreport.txt
  post_build:
    commands:
      - SCAN_STATUS=$(cat scanreport.txt | grep "QUALITY GATE STATUS:" | awk '{print $5}')
      - cat scanreport.txt
      - |
        if [ "$SCAN_STATUS" != "PASSED" ]; then
          echo "SonarQube task $SCAN_STATUS";
          exit 1;
        fi
      - echo Build completed on `date`
```

## Module-08: Deploying Helm into Kubernetes
Once container image are pushed into the scratch repository and pass the vulnerability scan, we want to ensure that container can run without any error on Kubernetes and later on can be assessed by ZAP.

### Create buildspec file
1. Create **buildspec_helm.yml** inside config repo
2. Make sure it has the following content
```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Installing Helm
      - chmod 700 get_helm.sh
      - ./get_helm.sh --version v3.12.3
      - echo Installing kubectl
      - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      - sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      - echo Updating kubeconfig
      - aws eks update-kubeconfig --name $K8S_CLUSTER_NAME --region $AWS_DEFAULT_REGION
      - IMAGE_TAG=`aws ssm get-parameter --name "destinationCommit" --query "Parameter.Value" --output text`
  build:
    commands:
      - NAMESPACE=$IMAGE_TAG
      - RELEASE_NAME=python-app
      - helm upgrade -i $RELEASE_NAME $CODEBUILD_SRC_DIR_HelmSource/app/ -n $NAMESPACE --create-namespace --set image.repository=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME --set image.tag=$IMAGE_TAG
      - REV=$(helm list -n $NAMESPACE | grep $RELEASE_NAME | awk '{print $3}')
      - REPLICA=$(cat $CODEBUILD_SRC_DIR_HelmSource/app/values.yaml | awk '/replicaCount:/ {print $2}' )
      - |
        stat=0
        while true
        do
          count=$(kubectl get pods -n $NAMESPACE -l release=$RELEASE_NAME,rev=$REV | grep Running | wc -l)
          if [ "$count" -eq "$REPLICA" ]; then echo "New deployment succeed" && break; fi
          if [ "$stat" -gt "36" ]; then echo "New deployment failed to be healthy, rolling back to previous version" && exit 1; fi
          stat=$((stat+1))
          sleep 5
        done
  post_build:
    commands:
      - echo Build completed on `date`
```

## Module-09: ZAP Vulnerability Scanning
Once application is deployed into kubernetes, it can be then scan by ZAP for known vulnerability. First ZAP will crawl the application endpoint using both standard and Ajax spider and then once completed. It will be attacked by an active scanning method.

## Create buildspec file
1. Create **buildspec_zap.yml** inside config repo
2. Make sure it has the following content
```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo prebuild
      - echo Installing kubectl
      - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      - sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      - echo Updating kubeconfig
      - aws eks update-kubeconfig --name $K8S_CLUSTER_NAME --region $AWS_DEFAULT_REGION
      - NAMESPACE=`aws ssm get-parameter --name "destinationCommit" --query "Parameter.Value" --output text`
      - BASE_APP_URL=`kubectl get ingress -n $NAMESPACE python-app-webapp --no-headers | awk '{print $3}'`
      - APP_URL="http://$BASE_APP_URL"
  build:
    commands:
      - echo "Spider"
      - spider=$(curl -s "$ZAP_URL/JSON/spider/action/scan/?apikey=$ZAP_TOKEN&url=$APP_URL&contextName=&recurse=" | jq -r '.scan')
      - |
        stat=50;
        while [ "$stat" != 100 ]; do
          stat=$(curl -s "$ZAP_URL/JSON/spider/view/status/?apikey=$ZAP_TOKEN&scanId=$spider" | jq -r '.status');
          echo "ZAP spider status is $stat";
          sleep 5;
        done
      - echo "Ajax Spider"
      - curl -s "$ZAP_URL/JSON/ajaxSpider/action/scan/?apikey=$ZAP_TOKEN&url=$APP_URL&inScope=&contextName=&subtreeOnly="
      - |
        stat="running"
        while [ "$stat" != "stopped" ]; do
          stat=$(curl -s "$ZAP_URL/JSON/ajaxSpider/view/status/?apikey=$ZAP_TOKEN" | jq -r '.status');
          echo "ZAP Ajax spider status is $stat";
          sleep 5;
        done
      - echo "ZAP Active scan started"
      - scanid=$(curl -s "$ZAP_URL/JSON/ascan/action/scan/?apikey=$ZAP_TOKEN&url=$APP_URL&recurse=true&inScopeOnly=&scanPolicyName=&method=&postData=&contextId=" | jq -r '.scan')
      - |
        stat=50;
        while [ "$stat" != 100 ]; do
          stat=$(curl -s "$ZAP_URL/JSON/ascan/view/status/?apikey=$ZAP_TOKEN&scanId=$scanid" | jq -r '.status');
          echo "OWASP ZAP scan status is $stat"
          echo "OWASP Zap analysis status is in progress...";
          sleep 5;
        done
        echo "OWASP Zap analysis status is completed..."; 
      - high_alerts=$( curl -s "$ZAP_URL/JSON/alert/view/alertsSummary/?apikey=$ZAP_TOKEN&baseurl=$APP_URL" | jq -r '.alertsSummary.High')
      - medium_alerts=$( curl -s "$ZAP_URL/JSON/alert/view/alertsSummary/?apikey=$ZAP_TOKEN&baseurl=$APP_URL" | jq -r '.alertsSummary.Medium')
      - echo "high alerts are $high_alerts"
  post_build:
    commands:
      - curl -s "$ZAP_URL/OTHER/core/other/jsonreport/?apikey=$ZAP_TOKEN" | jq . > zap-scan-results.json
      - | 
        jq "{ \"messageType\": \"CodeScanReport\", \"reportType\": \"OWASP-Zap\", \
        \"createdAt\": $(date +\"%Y-%m-%dT%H:%M:%S.%3NZ\"), \"source_repository\": env.CODEBUILD_SOURCE_REPO_URL_AppSource, \
        \"source_branch\": env.CODEBUILD_SOURCE_VERSION_AppSource, \
        \"build_id\": env.CODEBUILD_BUILD_ID, \
        \"source_commitid\": env.CODEBUILD_RESOLVED_SOURCE_VERSION, \
        \"report\": . }" zap-scan-results.json > payload.json
      - aws lambda invoke --function-name $LAMBDA_SECHUB_NAME --cli-binary-format raw-in-base64-out --payload file://payload.json owaspzap_scan_report.json && echo "LAMBDA_SUCCEDED" || echo "LAMBDA_FAILED";
      - if [ $high_alerts -gt 0 ]; then echo "there are high or medium alerts.. failing the build" && exit 1; else exit 0; fi

artifacts:
  files: '**/*'
```

## Module-10: Testing Pipeline stage2

### Make a new pull request from dev to main
you can make changes on the Dockerfile for example changing the maintainer 
```Dockerfile
LABEL maintainer="Rio Maulana"
```
the push it to remote dev branch
```bash
cd ~/environment/k8s-devsecops-training-app/
git add Dockerfile
git commit -m "change maintainer"
git push -u origin dev
```
Then create a pull request
```bash
aws codecommit create-pull-request \
    --title "Stage2 Run" \
    --description "Please review these changes." \
    --targets repositoryName=k8s-devsecops-training-app,sourceReference=dev,destinationReference=main \
    --region us-east-1
```

### Fix SonarQube Issues
#### Fix Flask Application
SonarQube reported that the app are vulnerable for CSRF and CORS attack and recommends fix to mitigate the issue change your index.app into something like the following
```python
from flask import Flask
from flask_cors import CORS
from flask_wtf import CSRFProtect

app = Flask(__name__)
csrf = CSRFProtect()
csrf.init_app(app)
CORS(app, origins=["http://localhost:5000","*.devsecops-training.com"])


@app.route("/")
def hello():
    return "Hello World!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int("5000"), debug=True)
```

#### Adding Coverage to Flask Application
Code coverage is important part of test driven development, as it make sure new code are behaving the way it was intended to run by giving it an input and its expected output
```bash
mkdir -p ~/environment/k8s-devsecops-training-app/test
touch ~/environment/k8s-devsecops-training-app/app/__init__.py
touch ~/environment/k8s-devsecops-training-app/test/__init__.py
touch ~/environment/k8s-devsecops-training-app/test/conftest.py
touch ~/environment/k8s-devsecops-training-app/test/test_app.py
```
Open conftest.py and put the following content
```python
import pytest

from app.index import app as flask_app


@pytest.fixture
def app():
    yield flask_app


@pytest.fixture
def client(app):
    return app.test_client()
```
Open test_app.py and put the following content
```python
def test_home_page(app, client):
    # Create a test client using the Flask application configured for testing
    del app
    response = client.get('/')
    assert response.status_code == 200
    assert b"Hello World!" in response.data
```

#### Add Gunicorn for production ready app
For Flask application to be production ready it needs to be run by WSGI server, we pick Gunicorn since it has simple configuration and support multipe worker.
Modify requirements.txt into
```text
flask
flask-cors <= 3.0.8
Flask-WTF <= 1.1.1
gunicorn <= 21.2.0
```
Create a start.sh file
```
cd ~/environment/k8s-devsecops-training-app
touch start.sh
chmod +x start.sh
```
Use the following as the content of start.sh
```bash
APP_PORT=${PORT:-5000}
ADDR_BIND=${ADDR:-0.0.0.0}
WORKER=${WORKER_COUNT:-4}

gunicorn -w $WORKER -b $ADDR_BIND:$APP_PORT --access-logfile=- 'index:app'
```
#### Test the new code
You can use docker to get a testing environment ready
```bash
cd ~/environment/k8s-devsecops-training-app
docker run -it --rm -p 8080:5000 -v $(pwd):/code public.ecr.aws/docker/library/python:3.7.9-alpine sh
cd code
pip install -r requirements.txt
pip install coverage
pip install pytest
coverage run -m pytest
./start.sh
```

#### Fix buildspec_sonar.yml
Now that coverage test is added into the application, it needs to be incorporated into buildspec, modify buildspec_sonar.yml into the following
```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.7
  pre_build:
    commands:
      - echo Pulling image
      - docker pull public.ecr.aws/rimaulana/sonar-scanner-cli:v5.0.1
      - pip install coverage
      - pip install pytest
      - pip install -r $CODEBUILD_SRC_DIR_AppSource/requirements.txt
      - cd $CODEBUILD_SRC_DIR_AppSource && coverage run -m pytest
      - cd $CODEBUILD_SRC_DIR_AppSource && coverage xml
  build:
    commands:
      - aws ssm put-parameter --name "codebuild-sonar-link" --type "String" --value "$SONAR_URL/dashboard?id=$SONAR_PROJECT_KEY" --overwrite
      - |
        docker run \
            --rm \
            -e SONAR_HOST_URL="$SONAR_URL" \
            -e SONAR_SCANNER_OPTS="-Dsonar.projectKey=$SONAR_PROJECT_KEY -Dsonar.python.version=3.7 -Dsonar.qualitygate.wait=true -Dsonar.token=$SONAR_TOKEN -Dsonar.python.coverage.reportPaths=coverage.xml" \
            -v "$CODEBUILD_SRC_DIR_AppSource:/usr/src" \
            public.ecr.aws/rimaulana/sonar-scanner-cli:v5.0.1 > scanreport.txt
  post_build:
    commands:
      - SCAN_STATUS=$(cat scanreport.txt | grep "QUALITY GATE STATUS:" | awk '{print $5}')
      - cat scanreport.txt
      - |
        if [ "$SCAN_STATUS" != "PASSED" ]; then
          echo "SonarQube task $SCAN_STATUS";
          exit 1;
        fi
      - echo Build completed on `date`
```
Once this done, push it into remote config repository
```bash
cd ~/environment/k8s-devsecops-training-config/
git add .
git commit -m "added coverage test"
git push origin main
```

#### Dockerfile
It is not safe to copy the whole context into container, we should define the only or folder that is necessary into the container, change the Dockerfile to like the following
```Dockerfile
FROM public.ecr.aws/docker/library/python:3.7-alpine

LABEL maintainer="Rio Maulana"
RUN adduser sasquatch -D

COPY requirements.txt start.sh app /app/

WORKDIR /app
RUN pip install -r requirements.txt

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 5000

USER sasquatch

CMD ./start.sh
```
Once this done, push the whole changes into app repository
```bash
cd ~/environment/k8s-devsecops-training-app/
git add .
git commit -m "added coverage test, fixed crsf and cors add gunicorn"
git push origin dev
```
This push should trigger the pipeline and it should be a successfull pipeline

## Module-11: Clean-up
### Delete all Kubernetes resources first by executing
```bash
kubectl delete namespace <your-app-namespace>
kubectl delete namespace sonarqube
kubectl delete namespace zap
kubectl delete namespace ingress-nginx
```
### Delete images from ECR repos
- scratch-k8s-devsecops-training
- prod-k8s-devsecops-training

### Clean up S3 bucket ```k8s-devsecops-training-<account_id>-<region>-artifacts```
### Delete AWS resources via Terraform
```bash
terraform destroy
```