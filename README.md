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
    --title "Updated Maintainer" \
    --description "Please review these changes." \
    --targets repositoryName=k8s-devsecops-training-app,sourceReference=dev,destinationReference=main \
    --region us-east-1
```