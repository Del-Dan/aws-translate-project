import json
import boto3
import os
import tempfile

# Initialize AWS clients
s3 = boto3.client("s3")
translate = boto3.client("translate")

# Config: your buckets
REQUEST_BUCKET = "danue-request-bucket-123"
RESPONSE_BUCKET = "danue-response-bucket-123"

def handler(event=None, context=None):
    """
    Reads test-request.json from request bucket,
    translates text, uploads result to response bucket.
    """

    file_key = "test-request.json"

    # Use a cross-platform temp directory
    tmp_dir = tempfile.gettempdir()
    request_path = os.path.join(tmp_dir, "request.json")
    response_path = os.path.join(tmp_dir, "response.json")

    # 1. Download file from request bucket
    s3.download_file(REQUEST_BUCKET, file_key, request_path)

    # 2. Parse JSON
    with open(request_path, "r") as f:
        request_data = json.load(f)

    source_lang = request_data["source_language"]
    target_lang = request_data["target_language"]
    text = request_data["text"]

    # 3. Call AWS Translate
    result = translate.translate_text(
        Text=text,
        SourceLanguageCode=source_lang,
        TargetLanguageCode=target_lang
    )

    translated_text = result["TranslatedText"]

    # 4. Save response JSON
    response_data = {
        "source_language": source_lang,
        "target_language": target_lang,
        "original_text": text,
        "translated_text": translated_text
    }

    with open(response_path, "w") as f:
        json.dump(response_data, f, indent=4)

    # 5. Upload response to response bucket
    output_key = "translated-" + file_key
    s3.upload_file(response_path, RESPONSE_BUCKET, output_key)

    print(f"Translation complete. File uploaded as {output_key} in {RESPONSE_BUCKET}")

# Run locally
if __name__ == "__main__":
    handler()
