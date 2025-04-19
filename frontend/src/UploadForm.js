import React, { useState } from 'react';

const UploadForm = () => {
  const [email, setEmail] = useState('');
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [responseMessage, setResponseMessage] = useState('');

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

      // Replace this URL with your backend API endpoint
      const response = await fetch('http://localhost:5000/upload', {
        method: 'POST',
        body: formData,
      });

      // Handle response
      if (response.ok) {
        const result = await response.json();
        setResponseMessage('File uploaded successfully!');
        // You might want to handle the result, for example, displaying a download link
        console.log(result); // Placeholder: show the result in the console
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
    </form>
  );
};

export default UploadForm;

/* Explanation of Added Code
FormData Object: This object is used to construct key/value pairs representing form fields and their values, allowing you to send them using the fetch API.

fetch API: Used to send a POST request. You can replace 'http://localhost:5000/upload' with your actual backend endpoint.

Response Handling: After the request completes, the code checks if it was successful (response.ok) and updates the user with a success or error message.

Loading State: A loading state is used to disable the button while the file is uploading, providing feedback to the user.

This setup should work well in connecting your form to your backend, allowing file uploads. Once your backend is operational, you’ll just need to point the POST request to the correct URL endpoint. */