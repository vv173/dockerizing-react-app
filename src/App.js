import React, { useState, useEffect } from 'react';
import axios from 'axios';
// biblioteka do manipulowania datami i godzinami.
import moment from 'moment-timezone';

function App() {
  const [ipAddress, setIpAddress] = useState('');
  const [dateTime, setDateTime] = useState('');

  // API Request do https://ipapi.co/json/
  useEffect(() => {
    axios.get('https://ipapi.co/json/').then((response) => {
      // publiczny adres IP uzytkownika uzyskany z odpowiedzi
      setIpAddress(response.data.ip);
      // bieżącą datę i czas w strefie czasowej uzyskanej z odpowiedzi
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

