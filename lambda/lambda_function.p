import json
import os
import time
import boto3
from urllib.parse import unquote_plus


rekognition = boto3.client("rekognition")
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

TABLE_NAME = os.environ["TABLE_NAME"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):

    print(json.dumps({
        "event": "lambda_started",
        "request_id": context.aws_request_id,
        "record_count": len(event.get("Records", []))
    }))

    for record in event["Records"]:

        body = json.loads(record["body"])

        s3_record = body["Records"][0]

        bucket = s3_record["s3"]["bucket"]["name"]

        key = unquote_plus(
            s3_record["s3"]["object"]["key"]
        )

        image_id = f"{bucket}/{key}"

        print(json.dumps({
            "event": "processing_started",
            "image_id": image_id
        }))

        start_time = time.time()

        response = rekognition.detect_moderation_labels(
            Image={
                "S3Object": {
                    "Bucket": bucket,
                    "Name": key
                }
            },
            MinConfidence=50
        )

        rekognition_duration = time.time() - start_time

        labels = response.get(
            "ModerationLabels",
            []
        )

        flagged_labels = [
            {
                "name": label["Name"],
                "confidence": label["Confidence"]
            }
            for label in labels
        ]

        status = (
            "FLAGGED"
            if flagged_labels
            else "SAFE"
        )

        expires_at = int(time.time()) + (
            30 * 24 * 60 * 60
        )

        table.put_item(
            Item={
                "imageId": image_id,
                "status": status,
                "labels": json.dumps(
                    flagged_labels
                ),
                "expiresAt": expires_at
            }
        )

        print(json.dumps({
            "event": "moderation_completed",
            "image_id": image_id,
            "status": status,
            "label_count": len(flagged_labels),
            "rekognition_duration": rekognition_duration
        }))

        if status == "FLAGGED":

            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="Image Moderation Alert",
                Message=json.dumps({
                    "imageId": image_id,
                    "status": status,
                    "labels": flagged_labels
                })
            )

            print(json.dumps({
                "event": "notification_sent",
                "image_id": image_id
            }))

    print(json.dumps({
        "event": "lambda_completed"
    }))

    return {
        "statusCode": 200
    }
