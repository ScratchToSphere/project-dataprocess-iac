import boto3
import os
import json

# Initialize S3 Client
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Get bucket name from environment variable
    bucket_name = os.environ['INPUT_BUCKET_NAME']
    
    # Filename to be uploaded - in real case, would come from event parameters event['queryStringParameters']['filename']
    object_name = "fichier-upload-test.json"
    
    try:
        # Generate presigned URL for PUT operation
        # URL allowing client to upload file directly to S3 for 5 minutes (300 seconds)
        response = s3_client.generate_presigned_url('put_object',
                                                    Params={'Bucket': bucket_name,
                                                            'Key': object_name},
                                                    ExpiresIn=300)
                                                    
        # Send back the presigned URL in the response
        return {
            'statusCode': 200,
            'body': json.dumps({
                'upload_url': response,
                'message': 'Utilisez cette URL avec une requete PUT pour uploader votre fichier.'
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"Erreur generation URL: {str(e)}")
        }