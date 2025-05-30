import os
import boto3
import logging
from flask import Flask, request, jsonify
from botocore.exceptions import BotoCoreError, NoCredentialsError, PartialCredentialsError, ClientError
from flask_cors import CORS

# Load environment variables
# S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME', 'my-wetransfer-clone-file-uploads-2c4b3d736300') # REMOVE THIS LINE
S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME') # Keep this line, it will now get the name from ECS

# Initialize the Flask application
app = Flask(__name__)

# This adds CORS support
# It's better to configure CORS more specifically in production
# For now, allowing all for testing, but tighten this up for production
CORS(app)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# It's good practice to ensure the bucket name is available at startup
# This check ensures the app doesn't start if the critical env var is missing
if not S3_BUCKET_NAME:
    logger.error("Environment variable S3_BUCKET_NAME is not set. Flask app cannot proceed.")
    # In a production ECS environment, this would cause the container to fail to start,
    # which is desirable if a critical configuration is missing.
    # For local dev, you'd need to export it: export S3_BUCKET_NAME="your-local-dev-bucket"
    exit(1) # Exit if critical config is missing

# Initialize S3 client once, as it's typically thread-safe and efficient
# Boto3 will automatically pick up region from AWS_REGION env var or EC2 instance profile/ECS task role.
s3_client = boto3.client('s3')

@app.route('/')
def index():
    # Prepare a simple welcome message
    welcome_message = {
        'message': 'Welcome to We Transfer Clone API',
        'description': 'This API allows you to upload files to S3.',
    }
    return jsonify(welcome_message), 200

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    try:
        # Use the initialized s3_client
        s3_client.upload_fileobj(file, S3_BUCKET_NAME, file.filename)
        # Return the file name for future use in generating download link
        return jsonify({'message': 'File successfully uploaded', 'file_name': file.filename}), 200
    except (BotoCoreError, NoCredentialsError, PartialCredentialsError, ClientError) as e:
        logger.error(f"S3 client error: {e}")
        return jsonify({'error': 'File upload failed', 'message': str(e)}), 500
    except Exception as e:
        logger.exception(f"Unhandled exception: {e}")
        return jsonify({'error': 'An unexpected error occurred', 'message': str(e)}), 500

def generate_presigned_url(file_name, expiration=3600):
    # Use the initialized s3_client
    try:
        response = s3_client.generate_presigned_url('get_object',
                                                    Params={'Bucket': S3_BUCKET_NAME,
                                                            'Key': file_name},
                                                    ExpiresIn=expiration)
    except ClientError as e:
        logger.error(e)
        return None

    return response

@app.route('/get-download-link', methods=['GET'])
def get_download_link():
    file_name = request.args.get('file_name')
    if not file_name:
        return jsonify({'error': 'File name not provided'}), 400

    url = generate_presigned_url(file_name)
    if url:
        return jsonify({'download_url': url}), 200
    else:
        return jsonify({'error': 'Failed to generate download link'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)