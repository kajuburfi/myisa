// Generated with the assistance of AI

#include <WiFi.h>
#include <WebServer.h>
#include "driver/uart.h"

// WiFi credentials
// Need to add SSID and a password. Currently designed to make it work as a hard point service
// i.e. we need to give valid ssid and password.
// We can, however change it so as to make it as a soft point, wherein we can put whatever ssid we want(we set
// the ssid) and set its password.
const char* ssid = "";
const char* password = "";

// UART configuration
#define RX_PIN 16
#define TX_PIN 17
#define UART_NUM UART_NUM_2
#define BAUD_RATE 9600

// Web server on port 80
WebServer server(80);

// Received data storage
const int MAX_RX_BUFFER = 1024;
char rxBuffer[MAX_RX_BUFFER];
int rxIndex = 0;
unsigned long lastRxTime = 0;
const unsigned long RX_TIMEOUT = 100;  // milliseconds

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // Configure UART2 for FPGA communication
  configureUART();
  
  // Connect to WiFi
  connectToWiFi();
  
  // Set up web server routes
  server.on("/", HTTP_GET, handleRoot);
  server.on("/send", HTTP_POST, handleSendData);
  server.on("/receive", HTTP_GET, handleReceiveData);
  server.on("/clear", HTTP_POST, handleClearBuffer);
  server.begin();
  
  Serial.println("Web server started!");
}

void loop() {
  server.handleClient();
  readFromUART();
}

// ============================================
// UART Configuration
// ============================================
void configureUART() {
  uart_config_t uart_config = {
    .baud_rate = BAUD_RATE,
    .data_bits = UART_DATA_8_BITS,
    .parity = UART_PARITY_DISABLE,
    .stop_bits = UART_STOP_BITS_1,
    .flow_ctrl = UART_HW_FLOWCTRL_DISABLE
  };
  
  uart_param_config(UART_NUM, &uart_config);
  uart_set_pin(UART_NUM, TX_PIN, RX_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
  uart_driver_install(UART_NUM, 256, 256, 0, NULL, 0);
  
  Serial.println("UART2 configured for FPGA communication");
}

// ============================================
// WiFi Connection
// ============================================
void connectToWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nFailed to connect to WiFi");
  }
}

// ============================================
// Read data from FPGA via UART
// ============================================
void readFromUART() {
  if (uart_is_driver_installed(UART_NUM)) {
    size_t available = 0;
    uart_get_buffered_data_len(UART_NUM, &available);
    
    if (available > 0) {
      uint8_t byte;
      while (uart_read_bytes(UART_NUM, &byte, 1, 0) > 0) {
        // Add byte as ASCII character to buffer
        if (rxIndex < MAX_RX_BUFFER - 1) {
          rxBuffer[rxIndex++] = (char)byte;
          lastRxTime = millis();
          
          // Debug output
          Serial.print("Received from FPGA: 0x");
          Serial.print(byte, HEX);
          Serial.print(" (");
          if (byte >= 32 && byte <= 126) {
            Serial.print((char)byte);
          } else {
            Serial.print("non-printable");
          }
          Serial.println(")");
        }
      }
    }
  }
}

// ============================================
// Web Server - Return Received Data
// ============================================
void handleReceiveData() {
  String json = "{\"data\":\"";
  
  // Add current buffer contents as a string
  for (int i = 0; i < rxIndex; i++) {
    char c = rxBuffer[i];
    
    // Handle special characters
    if (c == '"') {
      json += "\\\"";
    } else if (c == '\\') {
      json += "\\\\";
    } else if (c == '\n') {
      // Newline: create actual line break in HTML
      json += "<br>";
    } else if (c == '\r') {
      // Carriage return: skip it (don't display)
      // Do nothing - just skip this character
    } else if (c == '\t') {
      json += "\\t";
    } else if (c >= 32 && c <= 126) {
      // Printable ASCII
      json += c;
    } else {
      // Non-printable characters - show as hex placeholder
      json += "[0x";
      if (c < 16) json += "0";
      json += String((uint8_t)c, HEX);
      json += "]";
    }
  }
  
  json += "\"}";
  
  server.send(200, "application/json", json);
}

// ============================================
// Web Server - Serve HTML Page
// ============================================
void handleRoot() {
  String html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <title>FPGA-ESP UART Control</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 30px auto;
      padding: 20px;
      background-color: #f0f0f0;
    }
    .container {
      background-color: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      max-width: 1400px;
      margin: 0 auto;
    }
    h1 {
      color: #333;
      text-align: center;
      margin-top: 0;
    }
    .panel-wrapper {
      display: flex;
      gap: 30px;
      margin-top: 30px;
    }
    .send-section {
      flex: 1;
      min-width: 0;
    }
    .receive-section {
      flex: 1;
      min-width: 0;
    }
    .section {
      padding-bottom: 20px;
      border-bottom: none;
    }
    h2 {
      color: #555;
      border-left: 4px solid #4CAF50;
      padding-left: 10px;
      margin-top: 0;
      font-size: 18px;
    }
    .input-group {
      margin: 20px 0;
    }
    label {
      display: block;
      margin-bottom: 8px;
      font-weight: bold;
      color: #555;
      font-size: 14px;
    }
    input[type="text"],
    textarea {
      width: 100%;
      padding: 10px;
      font-size: 14px;
      border: 2px solid #ddd;
      border-radius: 4px;
      box-sizing: border-box;
    }
    input[type="text"]:focus,
    textarea:focus {
      outline: none;
      border-color: #4CAF50;
    }
    button {
      width: 100%;
      padding: 12px;
      font-size: 16px;
      background-color: #4CAF50;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-weight: bold;
      margin-top: 10px;
    }
    button:hover {
      background-color: #45a049;
    }
    button:active {
      background-color: #3d8b40;
    }
    .status {
      margin-top: 20px;
      padding: 15px;
      border-radius: 4px;
      text-align: center;
      font-weight: bold;
      display: none;
      font-size: 14px;
    }
    .status.success {
      background-color: #d4edda;
      color: #155724;
      display: block;
    }
    .status.error {
      background-color: #f8d7da;
      color: #721c24;
      display: block;
    }
    .info {
      background-color: #e7f3ff;
      padding: 10px;
      border-radius: 4px;
      margin-top: 15px;
      font-size: 13px;
      color: #004085;
    }
    #rxDisplay {
      background-color: #f5f5f5;
      border: 2px solid #ddd;
      border-radius: 4px;
      padding: 15px;
      min-height: 200px;
      font-family: 'Courier New', monospace;
      font-size: 14px;
      word-wrap: break-word;
      overflow-y: auto;
      max-height: 300px;
      color: #333;
      white-space: pre-wrap;
    }
    .empty-state {
      color: #999;
      font-style: italic;
    }
    .button-group {
      display: flex;
      gap: 10px;
      margin-top: 15px;
    }
    .button-group button {
      flex: 1;
      margin-top: 0;
    }
    button.clear-btn {
      background-color: #f44336;
    }
    button.clear-btn:hover {
      background-color: #da190b;
    }

    /* Responsive design for smaller screens */
    @media (max-width: 1024px) {
      .panel-wrapper {
        flex-direction: column;
        gap: 20px;
      }
      .send-section,
      .receive-section {
        flex: none;
      }
    }
  </style>

</head>
<body>
  <div class="container">
    <h1>FPGA-ESP UART Control</h1>
    
    <div class="panel-wrapper">
      <!-- SEND SECTION -->
      <div class="section send-section">
        <h2>Send Data to FPGA</h2>
        
        <div class="input-group">
          <label for="hexInput">Enter Hexadecimal Values (4 digits per line):</label>
          <textarea 
            id="hexInput" 
            style="width: 100%; height: 200px; padding: 10px; font-size: 14px; font-family: monospace; border: 2px solid #ddd; border-radius: 4px; text-transform: uppercase; box-sizing: border-box; resize: vertical;"
          ></textarea>
        </div>
        
        <button onclick="sendData()">Send All to FPGA</button>
        <p style="font-size: 12px; color: #999; text-align: center; margin-top: 8px;"><kbd>Shift</kbd> + <kbd>Enter</kbd> to send</p>
        
        <div id="sendStatus" class="status"></div>
        
        <div class="info">
          <strong>Format:</strong> Enter one 4-digit hexadecimal value per line (0-9, A-F)<br>
          <strong>Example:</strong> <code>1234</code> sends bytes 0x12 and 0x34<br>
          <strong>Multiple entries:</strong> All values will be sent in order
        </div>
      </div>

      <!-- RECEIVE SECTION -->
      <div class="section receive-section">
        <h2>Receive Data from FPGA</h2>
        
        <label>Data received (ASCII):</label>
        <div id="rxDisplay" class="empty-state">Waiting for data from FPGA...</div>
        
        <div class="button-group">
          <button class="clear-btn" onclick="clearRxBuffer()">Clear Buffer</button>
        </div>
        
        <div class="info">
          <strong>Auto-refresh:</strong> The buffer updates every 500ms<br>
          <strong>Format:</strong> ASCII characters with line breaks on 0x0A(newline)
        </div>
      </div>
    </div>
  </div>

  <script>
    // Auto-refresh receive buffer every 500ms
    setInterval(updateRxBuffer, 500);

    function sendData() {
      const hexInput = document.getElementById('hexInput').value.trim();
      const statusDiv = document.getElementById('sendStatus');
      
      if (!hexInput) {
        statusDiv.className = 'status error';
        statusDiv.textContent = 'Error: Please enter at least one hex value';
        return;
      }
      
      // Split input by lines and filter empty lines
      const hexValues = hexInput.split('\n')
        .map(line => line.trim().toUpperCase())
        .filter(line => line.length > 0);
      
      // Validate all entries
      for (let value of hexValues) {
        if (!/^[0-9A-F]{4}$/.test(value)) {
          statusDiv.className = 'status error';
          statusDiv.textContent = `Error: Invalid format "${value}". Each line must contain exactly 4 hexadecimal digits (0-9, A-F)`;
          return;
        }
      }
      
      // Send all values to ESP32
      fetch('/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'hexvalues=' + encodeURIComponent(hexValues.join(','))
      })
      .then(response => response.text())
      .then(data => {
        statusDiv.className = 'status success';
        statusDiv.textContent = `Success: Sent ${hexValues.length} value(s) (${hexValues.length * 2} bytes) to FPGA`;
        document.getElementById('hexInput').value = '';
      })
      .catch(error => {
        statusDiv.className = 'status error';
        statusDiv.textContent = 'Error: Failed to send data';
        console.error('Error:', error);
      });
    }
    
    function updateRxBuffer() {
      fetch('/receive')
        .then(response => response.json())
        .then(data => {
          const rxDisplay = document.getElementById('rxDisplay');
          if (data.data && data.data.length > 0) {
            rxDisplay.innerHTML = data.data;
            rxDisplay.classList.remove('empty-state');
          } else {
            rxDisplay.innerHTML = 'Waiting for data from FPGA...';
            rxDisplay.classList.add('empty-state');
          }
        })
        .catch(error => console.error('Error:', error));
    }
    
    function clearRxBuffer() {
      fetch('/clear', { method: 'POST' })
        .then(() => {
          document.getElementById('rxDisplay').innerHTML = '';
          document.getElementById('rxDisplay').classList.add('empty-state');
        })
        .catch(error => console.error('Error:', error));
    }
    
    // Allow Shift+Enter key to send
    document.getElementById('hexInput').addEventListener('keypress', function(event) {
      if (event.key === 'Enter' && event.shiftKey) {
        event.preventDefault();
        sendData();
      }
    });
  </script>
</body>
</html>
)rawliteral";
  
  server.send(200, "text/html", html);
}

// ============================================
// Web Server - Handle Multiple Data Transmission
// ============================================
void handleSendData() {
  if (server.hasArg("hexvalues")) {
    String hexString = server.arg("hexvalues");
    
    // Split by comma
    int commaIndex = 0;
    int startIndex = 0;
    int bytesSent = 0;
    
    while (startIndex < hexString.length()) {
      // Find next comma or end of string
      commaIndex = hexString.indexOf(',', startIndex);
      if (commaIndex == -1) {
        commaIndex = hexString.length();
      }
      
      // Extract one hex value
      String hexValue = hexString.substring(startIndex, commaIndex);
      hexValue.toUpperCase();
      hexValue.trim();
      
      // Validate: must be exactly 4 hex characters
      if (hexValue.length() != 4 || !isValidHex(hexValue)) {
        server.send(400, "text/plain", "Invalid hex format");
        return;
      }
      
      // Convert hex string to two bytes
      uint8_t byte1 = hexCharToByte(hexValue[0], hexValue[1]);
      uint8_t byte2 = hexCharToByte(hexValue[2], hexValue[3]);
      
      // Send both bytes to FPGA via UART
      uint8_t data[2] = {byte1, byte2};
      uart_write_bytes(UART_NUM, (const char*)data, 2);
      
      // Debug output
      Serial.print("Sent to FPGA: 0x");
      Serial.print(byte1, HEX);
      Serial.print(" 0x");
      Serial.print(byte2, HEX);
      Serial.print(" (from ");
      Serial.print(hexValue);
      Serial.println(")");
      
      bytesSent += 2;
      
      // Move to next value
      startIndex = commaIndex + 1;
    }
    
    Serial.print("Total bytes sent: ");
    Serial.println(bytesSent);
    
    server.send(200, "text/plain", "OK");
  } else {
    server.send(400, "text/plain", "Missing hexvalues parameter");
  }
}

// ============================================
// Web Server - Clear Receive Buffer
// ============================================
void handleClearBuffer() {
  rxIndex = 0;
  memset(rxBuffer, 0, MAX_RX_BUFFER);
  server.send(200, "text/plain", "OK");
}

// Check if string contains only valid hex characters
bool isValidHex(String str) {
  for (int i = 0; i < str.length(); i++) {
    char c = str[i];
    if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'))) {
      return false;
    }
  }
  return true;
}

// Convert two hex characters to a byte
uint8_t hexCharToByte(char high, char low) {
  uint8_t highNibble = charToHexDigit(high);
  uint8_t lowNibble = charToHexDigit(low);
  return (highNibble << 4) | lowNibble;
}

// Convert a single hex character to its numeric value
uint8_t charToHexDigit(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  return 0;
}
