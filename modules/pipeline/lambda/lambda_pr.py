from __future__ import print_function
import datetime
import boto3
import os

codecommit_client = boto3.client('codecommit')
ssm = boto3.client('ssm')
codepipeline = boto3.client('codepipeline')

# Pipeline Name
pipeline = '%s-pipeline' % os.environ['PREFIX']

def handler(event, context):
  # Log event
  print(event)

  # Pull request Event
  if event['detail']['event'] in ['pullRequestSourceBranchUpdated', 'pullRequestCreated']:
    
    # Set variables
    pull_request_id = event['detail']['pullRequestId']
    repository_name = event['detail']['repositoryNames'][0]
    source_commit = event['detail']['sourceCommit']
    destination_commit = event['detail']['destinationCommit']

    # Write commit details to SSM
    ssm.put_parameter(
      Name='prid',
      Description='Pull Request ID',
      Value=pull_request_id,
      Overwrite=True,
      Type='String'
    )

    ssm.put_parameter(
      Name='repo',
      Description='Repository Name',
      Value=repository_name,
      Overwrite=True,
      Type='String'
    )

    ssm.put_parameter(
      Name='sourceCommit',
      Description='Source Commit',
      Value=source_commit,
      Overwrite=True,
      Type='String'
    )

    ssm.put_parameter(
      Name='destinationCommit',
      Description='Destination Commit',
      Value=destination_commit,
      Overwrite=True,
      Type='String'
    )

    # Add comments to PR
    codecommit_client.post_comment_for_pull_request(
      pullRequestId = pull_request_id,
      repositoryName = repository_name,
      beforeCommitId = source_commit,
      afterCommitId = destination_commit,
      content = '**Build started at {}.  Starting security testing.**'.format(datetime.datetime.utcnow().time())
    )

    codepipeline.start_pipeline_execution(
      name=pipeline,
    )