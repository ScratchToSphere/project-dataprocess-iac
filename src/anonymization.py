import json

def lambda_handler(event, context):
    # Work Simulation of Anonymization Logic
    print("Anonymization process started...")
    return {
        'statusCode': 200,
        'body': json.dumps('Anonymization over - Success !')
    }