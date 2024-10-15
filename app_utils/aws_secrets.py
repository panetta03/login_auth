import boto3
import json
from botocore.exceptions import ClientError

def get_secrets(secret_name, region_name="us-east-2"):
    """
    Retrieve secrets from AWS Secrets Manager.
    
    secret_name: The name of the secret in AWS Secrets Manager.
    region_name: The AWS region where the secret is stored (default is 'us-east-1').
    
    Returns a dictionary of secrets.
    """
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        raise e

    # Decrypt the secret and return the secrets as a dictionary
    secret = get_secret_value_response.get("SecretString")
    if secret:
        return json.loads(secret)
    else:
        raise Exception(f"Secret {secret_name} not found.")