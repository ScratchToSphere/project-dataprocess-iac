import json

def lambda_handler(event, context):
    # Work Simulation of Enrichment Logic
    print("Enrichment process started...")
    return {
        'statusCode': 200,
        'body': json.dumps('Enrichment over - Success !')
    }