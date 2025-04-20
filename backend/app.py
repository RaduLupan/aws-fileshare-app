from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    # Here you can add logic to process the file, e.g., save to S3

    return jsonify({'message': 'File successfully uploaded'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)