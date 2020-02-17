(function () {
  var ws = new WebSocket("ws://localhost:1338");

  var chatform = document.querySelector('.chat-form');
  var loginform = document.querySelector('.login-form');
  var registerform = document.querySelector('.register-form');
  document.querySelector('#chat').style.display = 'none';

  async function sendLogin(username, password) {
    const loginResponse = await fetch('http://localhost:1337/login', {
      method: 'POST',
      body:JSON.stringify({
        "username": username,
        "password": password
      }),
      headers: {
        'Content-Type': 'application/json'
      },
      credentials: 'include'
    });
    const loginResponseValue = await loginResponse.text();
    if (loginResponseValue != "OK") {
      document.querySelector('.error').textContent = loginResponseValue;
      return;
    }

    const ticketResponse = await fetch('http://localhost:1337/wsTicket', {
      method: 'GET'
    });

    const ticketResponseValue = await ticketResponse.text();
    if (loginResponse.ok) {
      ws.send(ticketResponseValue);
      document.querySelector('#login').style.display = 'none';
      document.querySelector('#register').style.display = 'none';
      document.querySelector('#chat').style.display = 'block';
      document.querySelector('input[name=message]').focus();

    } else {
      document.querySelector('.error').textContent = ticketResponseValue;
    }
  }

  async function sendRegister(username, password, email) {
    const registerResponse = await fetch('http://localhost:1337/subscribe', {
      method: 'POST',
      body: JSON.stringify({
        "username": username,
        "password": password,
        "email": email,
      }),
      headers: {
        'Content-Type': 'application/json'
      },
      credentials: 'include'
    });
    const registerResponseValue = await registerResponse.text();
    if (registerResponseValue.ok) {
      document.querySelector('.error').textContent = registerResponseValue;
      return;
    // } else {
    //   document.querySelector('.error').textContent = 'Le compte a été créé !';
    }
  }

  loginform.onsubmit = function (e) {
    e.preventDefault();
    var usernameInput = loginform.querySelector('input[name=username]');
    var passwordInput = loginform.querySelector('input[name=password]');
    var username = usernameInput.value;
    var password = passwordInput.value;
    sendLogin(username, password);
  }
  
  registerform.onsubmit = function (e) {
    e.preventDefault();
    var usernameInput = registerform.querySelector('input[name=username]');
    var passwordInput = registerform.querySelector('input[name=password]');
    var emailInput = registerform.querySelector('input[name=email]');
    sendRegister(usernameInput.value, passwordInput.value, emailInput.value);
  }

  chatform.onsubmit = function (e) {
    e.preventDefault();
    var input = document.querySelector('input[name=message]');
    var text = input.value;
    ws.send(text);
    input.value = '';
    input.focus();
    return false;
  }

  ws.onmessage = function (msg) {
    var response = msg.data;
    var messageList = document.querySelector('.messages');
    var li = document.createElement('li');
    li.textContent = response;
    messageList.appendChild(li);
  }

}());