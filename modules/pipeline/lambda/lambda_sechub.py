import os
import sys
import json
import logging
import boto3
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
sys.path.insert(0, "external")
securityhub = boto3.client('securityhub')

FINDING_TITLE = "CodeAnalysis"
FINDING_DESCRIPTION_TEMPLATE = "Summarized report of code scan with {0}"
FINDING_TYPE_TEMPLATE = "{0} code scan"
BEST_PRACTICES_OWASP = "https://owasp.org/www-project-top-ten/"
report_url = "https://aws.amazon.com"

# This function import agregated report findings to securityhub 
def import_finding_to_sh(count: int, account_id: str, region: str, created_at: str, source_repository: str, 
    source_branch: str, source_commitid: str, build_id: str, report_url: str, finding_id: str, generator_id: str,
                         normalized_severity: str, severity: str, finding_type: str, finding_title: str, finding_description: str, best_practices_cfn: str): 
    new_findings = []
    new_findings.append({
        "SchemaVersion": "2018-10-08",
        "Id": finding_id,
        "ProductArn": "arn:aws:securityhub:{0}:{1}:product/{1}/default".format(region, account_id),
        "GeneratorId": generator_id,
        "AwsAccountId": account_id,
        "Types": [
            "Software and Configuration Checks/AWS Security Best Practices/{0}".format(
                finding_type)
        ],
        "CreatedAt": created_at,
        "UpdatedAt": created_at,
        "Severity": {
            "Normalized": normalized_severity,
        },
        "Title":  f"{count}-{finding_title}",
        "Description": f"{finding_description}",
        'Remediation': {
            'Recommendation': {
                'Text': 'For directions on OWASP Best practices, please click this link',
                'Url': best_practices_cfn
            }
        },
        'SourceUrl': report_url,
        'Resources': [
            {
                'Id': build_id,
                'Type': "CodeBuild",
                'Partition': "aws",
                'Region': region
            }
        ],
    })
    ### post the security vulnerability findings to AWS SecurityHub
    response = securityhub.batch_import_findings(Findings=new_findings)
    if response['FailedCount'] > 0:
        logger.error("Error importing finding: " + response)
        raise Exception("Failed to import finding: {}".format(response['FailedCount']))
        
def process_message(event):
    """ Process Lambda Event """
    if event['messageType'] == 'CodeScanReport':
        account_id = os.environ['AWS_ACCOUNT_ID']
        region = os.environ['AWS_REGION']
        created_at = event['createdAt']
        source_repository = event['source_repository']
        source_branch = event['source_branch']
        source_commitid = event['source_commitid']
        build_id = event['build_id']
        report_type = event['reportType']
        finding_type = FINDING_TYPE_TEMPLATE.format(report_type)
        generator_id = f"{report_type.lower()}-{source_repository}-{source_branch}"
                
        ### OWASP Zap SAST scanning report parsing
        if event['reportType'] == 'OWASP-Zap':  
            severity = 50
            FINDING_TITLE = "OWASP ZAP Dynamic Code Analysis"
            alert_ct = event['report']['site'][0]['alerts']
            alert_count = len(alert_ct)
            for alertno in range(alert_count):
                risk_desc = event['report']['site'][0]['alerts'][alertno]['riskdesc']
                riskletters = risk_desc[0:3]
                ### find the vulnerability severity level
                if riskletters == 'Hig':
                    normalized_severity = 70
                elif riskletters == 'Med':
                    normalized_severity = 60
                elif riskletters == 'Low' or riskletters == 'Inf':  
                    normalized_severity = 30
                else:
                    normalized_severity = 90                                       
                instances = len(event['report']['site'][0]['alerts'][alertno]['instances'])
                finding_description = f"{alertno}-Vulerability:{event['report']['site'][0]['alerts'][alertno]['alert']}-Total occurances of this issue:{instances}"
                finding_id = f"{alertno}-{report_type.lower()}-{build_id}"
                created_at = datetime.now(timezone.utc).isoformat()
                ### Calling Securityhub function to post the findings
                import_finding_to_sh(alertno, account_id, region, created_at, source_repository, source_branch, source_commitid, build_id, report_url, finding_id, generator_id, normalized_severity, severity, finding_type, FINDING_TITLE, finding_description, BEST_PRACTICES_OWASP)
        else:
            print("Invalid report type was provided")                
    else:
        logger.error("Report type not supported:")

def handler(event, context):
    """ Lambda entrypoint """
    try:
        logger.info("Starting function")
        return process_message(event)
    except Exception as error:
        logger.error("Error {}".format(error))
        raise