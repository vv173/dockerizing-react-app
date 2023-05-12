import React, { useState, useEffect } from 'react';
import axios from 'axios';
import moment from 'moment-timezone';

function App() {
  const [ipAddress, setIpAddress] = useState('');
  const [dateTime, setDateTime] = useState('');

  useEffect(() => {
    axios.get('https://ipapi.co/json/').then((response) => {
      setIpAddress(response.data.ip);
      setDateTime(moment().tz(response.data.timezone).format('YYYY-MM-DD hh:mm:ss A z'));
    });
  }, []);

  return (
    <div className="App">
      <h1>Your IP Address: {ipAddress}</h1>
      <h2>Current Date and Time: {dateTime}</h2>
    </div>
  );
}

export default App;

