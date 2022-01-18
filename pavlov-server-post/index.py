import boto3

def lambda_handler(event, context):
    ddbClient = boto3.resource('dynamodb')
    ddbTable = ddbClient.Table('pavlov-servers')
    response = ddbTable.put_item(
        Item={
            'id': event['id'],
            'rcontxt': event['rcontxt'],
            'gameini': event['gameini'],
        }
    )
    return {
        'statusCode': response['ResponseMetadata']['HTTPStatusCode'],
        'body': 'Record ' + event['id'] + ' Added'
    }
