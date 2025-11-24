import json

def lambda_handler(event, context):
    # Work Simulation of Consolidation Logic
    print("Consolidation process started...")
    return {
        'statusCode': 200,
        'body': json.dumps('Consolidation over - Success !')
    }