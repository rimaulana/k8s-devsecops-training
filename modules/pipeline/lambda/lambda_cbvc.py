from __future__ import print_function
import boto3
import os
import json

codecommit_client = boto3.client('codecommit')
ssm = boto3.client('ssm')
vcproject = os.environ['CODEBUILDVCPROJECT']
image_repo_name = os.environ['IMAGEREPONAME']

def handler(event, context):

  # Log event
  print(json.dumps(event))

  # Get PR Details
  pull_request_id = ssm.get_parameter(
    Name='prid'
  )

  repository_name = ssm.get_parameter(
    Name='repo'
  )

  source_commit = ssm.get_parameter(
    Name='sourceCommit'
  )

  destination_commit = ssm.get_parameter(
    Name='destinationCommit'
  )
  
  image_sha = ssm.get_parameter(
    Name='imageSHA'
  )
  
  scan_result_url = 'https://console.aws.amazon.com/ecr/repositories/private/{0}/{1}/_/image/{2}/scan-results?region={3}'.format(event['account'],image_repo_name,image_sha['Parameter']['Value'],event['region'])
  s3_prefix = 's3-{0}'.format(event['region']) if event['region'] != 'us-east-1' else 's3'
  if event['detail']['project-name'] in [vcproject]:
    # Add Errors
    errors = '## Vulnerability Scanning (using Anchore)\n'
    if event['detail']['build-status'] == 'SUCCEEDED':
      errors = errors + 'No vulnerabilities that meet or exceed the threshold!  You can review the findings in [ECR](%s).' % scan_result_url
    else:
      errors = errors + 'Findings found! Please review the findings in [ECR](%s).' % scan_result_url
    for phase in event['detail']['additional-information']['phases']:
      if phase.get('phase-status') == 'FAILED':
          badge = 'https://{0}.amazonaws.com/sa-security-specialist-workshops-{1}/devsecops/containers/badges/failing.svg'.format(s3_prefix, event['region'])
          content = '![Failing]({0} "Failing") - See the [Logs]({1})\n'.format(badge, event['detail']['additional-information']['logs']['deep-link'])
          content = content + errors
          break
      else:
          badge = 'https://{0}.amazonaws.com/sa-security-specialist-workshops-{1}/devsecops/containers/badges/passing.svg'.format(s3_prefix, event['region'])
          content = '![Passing]({0} "Passing") - See the [Logs]({1})\n'.format(badge, event['detail']['additional-information']['logs']['deep-link'])
          content = content + errors

  codecommit_client.post_comment_for_pull_request(
    pullRequestId = pull_request_id['Parameter']['Value'],
    repositoryName = repository_name['Parameter']['Value'],
    beforeCommitId = source_commit['Parameter']['Value'],
    afterCommitId = destination_commit['Parameter']['Value'],
    content = content
  )
  
  # Delete pipeline parameters
  ssm.delete_parameters(
    Names=[
        'ECRScanLink'
    ]
  )