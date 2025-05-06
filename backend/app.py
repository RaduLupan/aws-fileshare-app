import os
import boto3
import logging
from flask import Flask, request, jsonify
from botocore.exceptions import BotoCoreError, NoCredentialsError, PartialCredentialsError

# Load environment variables
S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME', 'my-wetransfer-clone-bucket-91c6fb37f8c2')

# Initialize the Flask application
app = Flask(__name__)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/')
def index():
    # Prepare a simple welcome message
    welcome_message = {
        'message': 'Welcome to We Transfer Clone. Use curl -X POST http://<IP>:5000/upload -F "file=<file_name>" to upload.'
    }
    return jsonify(welcome_message), 200

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    try:
        # Using the boto3 client for S3
        s3_client = boto3.client('s3')
        s3_client.upload_fileobj(file, S3_BUCKET_NAME, file.filename)
        return jsonify({'message': 'File successfully uploaded'}), 200
    except (BotoCoreError, NoCredentialsError, PartialCredentialsError) as e:
        logger.error(f"S3 client error: {e}")
        return jsonify({'error': 'File upload failed', 'message': str(e)}), 500
    except Exception as e:
        logger.exception(f"Unhandled exception: {e}")
        return jsonify({'error': 'An unexpected error occurred', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)