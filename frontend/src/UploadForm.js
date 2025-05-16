import React, { useState } from 'react';

const UploadForm = () => {
  const [email, setEmail] = useState('');
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [responseMessage, setResponseMessage] = useState('');
  const [downloadUrl, setDownloadUrl] = useState('');

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!email || !file) {
      alert('Please provide both email and a file.');
      return;
    }

    // Create a FormData object
    const formData = new FormData();
    formData.append('email', email);
    formData.append('file', file);

    try {
      setLoading(true);
      setResponseMessage('');
      setDownloadUrl('');

      // Replace this URL with your backend API endpoint
      const response = await fetch('http://localhost:5000/upload', {
        method: 'POST',
        body: formData,
      });

      // Handle response
      if (response.ok) {
        const result = await response.json();
        setResponseMessage('File uploaded successfully!');

        // Fetch the download link using the returned file name
        const linkResponse = await fetch(`http://localhost:5000/get-download-link?file_name=${result.file_name}`);
        if (linkResponse.ok) {
          const linkResult = await linkResponse.json();
          setDownloadUrl(linkResult.download_url);
        } else {
          setResponseMessage('Failed to generate download link.');
        }
      } else {
        setResponseMessage('File upload failed.');
      }
    } catch (error) {
      console.error('Error uploading file:', error);
      setResponseMessage('An error occurred during file upload.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="email">Email:</label>
        <input
          type="email"
          id="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
      </div>
      <div>
        <label htmlFor="file">Upload File:</label>
        <input
          type="file"
          id="file"
          onChange={(e) => setFile(e.target.files[0])}
          required
        />
      </div>
      <button type="submit" disabled={loading}>
        {loading ? 'Uploading...' : 'Submit'}
      </button>
      {responseMessage && <p>{responseMessage}</p>}
      {downloadUrl && (
        <div>
          <p>Your download link:</p>
          <a href={downloadUrl} target="_blank" rel="noopener noreferrer">{downloadUrl}</a>
        </div>
      )}
    </form>
  );
};

export default UploadForm;