# AWS Translate Project

This project is all about building a serverless translation pipeline on AWS.  
We upload a request file into one S3 bucket → Lambda picks it up → Amazon Translate does the work → the translated result is dropped into another S3 bucket.  

It’s all automated, no manual steps after upload 

---

## Architecture

Here’s how everything connects together:

1. **Request Bucket** – You drop a request.json file here.
2. **Lambda Function** – Automatically triggered by the upload.
3. **Amazon Translate** – Does the actual language translation.
4. **Response Bucket** – Stores the translated output (translated-request.json).

  
Request Bucket → Lambda → Amazon Translate → Response Bucket  

---

## Setup

### 1. Requirements
- AWS account (with programmatic access / IAM user).
- Terraform installed.
- AWS CLI installed and configured.

### 2. Project Folder
Inside the repo you’ll see:

aws-translate-project/
│
├── main.tf                  # Terraform config for S3, Lambda, IAM  
├── lambda_function.py        # Lambda code for Translate  
├── request.json              # Example request  
├── translated-request.json   # Example response  
└── README.md                 # Documentation (this file!)  

---

## Step by Step Workflow

### Step 1: Deploy Infrastructure
Run:

terraform init  
terraform apply  

Terraform creates:
- Two S3 buckets  
- IAM role + permissions  
- Lambda function connected to S3  

  

---

### Step 2: Upload a Request File
Example request.json:

{  
    "source_language": "en",  
    "target_language": "fr",  
    "original_text": "Good morning"  
}  

Upload to request bucket:

aws s3 cp request.json s3://YOUR_REQUEST_BUCKET/  

 

---

### Step 3: Lambda is Triggered
- As soon as the file lands in the request bucket, Lambda runs.  
- It reads the request, calls Amazon Translate, and writes the result to the response bucket.  

  

---

### Step 4: Check Translated Output
Download result:

aws s3 cp s3://YOUR_RESPONSE_BUCKET/translated-request.json .  
cat translated-request.json  

Example output:

{  
    "source_language": "en",  
    "target_language": "fr",  
    "original_text": "Good morning",  
    "translated_text": "Bonjour"  
}  

  

---

## Example Files

request.json  
Defines what we want to translate:

{  
    "source_language": "en",  
    "target_language": "es",  
    "original_text": "Hello world"  
}  

translated-request.json  
Generated automatically:

{  
    "source_language": "en",  
    "target_language": "es",  
    "original_text": "Hello world",  
    "translated_text": "Hola mundo"  
}  

---

## Testing

1. Edit request.json and change target_language to any supported language code (es, fr, de, etc.).  
2. Upload again to request bucket.  
3. Grab the result from response bucket.  
4. Confirm translation.  

  

---

## Cleanup

When done, remove everything to avoid charges:

terraform destroy  

---

## Notes

- Lifecycle rules automatically clean up S3 buckets after a few days.  
- GitHub repo excludes big .terraform provider files (to stay under 100 MB limit).  
- Supported languages: see Amazon Translate docs (https://docs.aws.amazon.com/translate/latest/dg/what-is.html).  

---

## Final Thoughts

This project shows how easy it is to use AWS + Terraform to build a serverless workflow.  
It’s hands-off: drop a file in → translation comes out.  
Simple, scalable, and no servers to manage 🎉.
