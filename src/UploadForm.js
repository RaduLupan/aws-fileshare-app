import React, { useState } from 'react';

const UploadForm = () => {
  const [email, setEmail] = useState('');
  const [file, setFile] = useState(null);

  // Handle form submission
  const handleSubmit = (event) => {
    event.preventDefault();
    if(!email || !file) {
      alert('Please provide both email and file.');
      return;
    }
    console.log('Email:', email);
    console.log('File:', file);
    // Add logic here to handle file upload
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
      <button type="submit">Submit</button>
    </form>
  );
};

export default UploadForm;
