from __future__ import print_function
import boto3
import os
import json

codecommit_client = boto3.client('codecommit')
ssm = boto3.client('ssm')
puproject = os.environ['CODEBUILDPUPROJECT']

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

  s3_prefix = 's3-{0}'.format(event['region']) if event['region'] != 'us-east-1' else 's3'
  sec_hub = 'https://%s.console.aws.amazon.com/securityhub/' % event['region'] 
  if event['detail']['project-name'] in [puproject]:
    errors = '## Image Build and Push\n'
    if event['detail']['build-status'] == 'SUCCEEDED':
      errors = errors + 'Image has successfully been published to the [AWS ECR repository](https://us-east-2.console.aws.amazon.com/ecr/repositories/container-devsecops-wksp-sample/).  The Pull Request has been merged and closed.'
    else:
      errors = errors + 'Image has failed to build.  Please review the logs'
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

  # Merge Pull Request
  codecommit_client.merge_pull_request_by_fast_forward(
    pullRequestId=pull_request_id['Parameter']['Value'],
    repositoryName=repository_name['Parameter']['Value']
  )

  # Delete pipeline parameters
  ssm.delete_parameters(
    Names=[
        'prid',
        'repo',
        'sourceCommit',
        'destinationCommit'
    ]
  )