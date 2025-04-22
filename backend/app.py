import logging
import boto3
from flask import Flask, request, jsonify

logging.basicConfig(level=logging.DEBUG)

s3_client = boto3.client('s3')

app = Flask(__name__)

@app.route('/')
def index():
    return "Welcome to my Flask App!"

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    try:
        s3_client.upload_fileobj(file, "my-wetransfer-clone-bucket-0319cf63dee7", file.filename)
        return jsonify({'message': 'File successfully uploaded'}), 200
    except Exception as e:
        logging.exception("Exception during S3 upload")
        return jsonify({'error': 'File upload failed', 'detail': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)