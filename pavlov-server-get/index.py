import boto3

def lambda_handler(event, context):
    client = boto3.resource('dynamodb')
    table = client.Table('pavlov-servers')
    response = table.get_item(
        Key={
            'id': event['pathParameters']['id']
        }
    )
    if 'Item' in response:
        return response['Item']
    else:
        return {
            'statusCode': '404',
            'body': 'Not found'
        }
