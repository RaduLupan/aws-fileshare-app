import boto3
from flask import Flask, request, jsonify

# Initialize the Flask application
app = Flask(__name__)

@app.route('/')
def index():
    # Initialize boto3 clients
    sts_client = boto3.client('sts')
    s3_client = boto3.client('s3')

    try:
        # Get the AWS STS caller identity
        caller_identity = sts_client.get_caller_identity()

        # List S3 buckets
        buckets = s3_client.list_buckets()

        # Prepare response data
        response_data = {
            'CallerIdentity': caller_identity,
            'Buckets': [bucket['Name'] for bucket in buckets['Buckets']]
        }

        return jsonify(response_data), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    try:
        # Using the boto3 client for S3
        s3_client = boto3.client('s3')
        s3_client.upload_fileobj(file, "my-wetransfer-clone-bucket-8863c3540f57", file.filename)
        return jsonify({'message': 'File successfully uploaded'}), 200
    except Exception as e:
        print(f"Upload failed: {e}")
        return jsonify({'error': 'File upload failed', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)