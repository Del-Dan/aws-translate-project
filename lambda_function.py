import json
import boto3
import os

s3 = boto3.client("s3")
translate = boto3.client("translate")

REQUEST_BUCKET = os.environ["REQUEST_BUCKET"]
RESPONSE_BUCKET = os.environ["RESPONSE_BUCKET"]

def lambda_handler(event, context):
    try:
        # Get the uploaded file name from S3 event
        for record in event["Records"]:
            file_key = record["s3"]["object"]["key"]

            # Download request file
            download_path = f"/tmp/{file_key}"
            s3.download_file(REQUEST_BUCKET, file_key, download_path)

            # Read JSON request
            with open(download_path, "r", encoding="utf-8") as f:
                request_data = json.load(f)

            source_lang = request_data.get("source_language", "auto")
            target_lang = request_data.get("target_language", "fr")  # default to French
            original_text = request_data["original_text"]

            # Call Translate API
            result = translate.translate_text(
                Text=original_text,
                SourceLanguageCode=source_lang,
                TargetLanguageCode=target_lang,
            )

            translated_text = result["TranslatedText"]

            # Save response
            response_data = {
                "source_language": source_lang,
                "target_language": target_lang,
                "original_text": original_text,
                "translated_text": translated_text
            }

            output_key = f"translated-{file_key}"
            upload_path = f"/tmp/{output_key}"
            with open(upload_path, "w", encoding="utf-8") as f:
                json.dump(response_data, f, ensure_ascii=False)

            s3.upload_file(upload_path, RESPONSE_BUCKET, output_key)

            print(f"✅ Translation complete. File saved as {output_key} in {RESPONSE_BUCKET}")

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        raise
