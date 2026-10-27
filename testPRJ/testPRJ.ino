#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "DHT.h"

// ================= 1. CẤU HÌNH WI-FI =================
const char* ssid     = "test";        // Tên Wi-Fi của bạn
const char* password = "test1234";    // Mật khẩu Wi-Fi

// ================= 2. CẤU HÌNH SERVER & THIẾT BỊ =================
// Địa chỉ IP của máy tính chạy Tomcat (port 8080)
// Lưu ý: Thay đổi IP này nếu mạng Wi-Fi của bạn cấp IP khác cho máy tính
const char* serverHost     = "http://10.216.65.149:8080"; 
const char* cmdEndpoint    = "/Airroom/device/command";
const char* dataEndpoint   = "/Airroom/device/data";

// Thông tin định danh thiết bị (phải khớp chính xác trong Database AirRoomDB)
const char* deviceCode = "D001";
const char* apiKey     = "demo-key-d001";

// ================= 3. CẤU HÌNH CHÂN CẮM & NGOẠI VI (KHÔNG ĐỔI) =================
#define DHTPIN 15         // Chân DATA DHT22 cắm GPIO15
#define DHTTYPE DHT22

#define MQ135_PIN 34     // MQ-135 A0 cắm GPIO 34 (ADC1)
#define MQ7_PIN   35     // MQ-7 A0 cắm GPIO 35 (ADC1)

// Khai báo chân LED RGB (Cathode chung)
#define PIN_LED_R 25     // Kênh màu Đỏ -> GPIO25
#define PIN_LED_G 26     // Kênh màu Xanh lá -> GPIO26
#define PIN_LED_B 27     // Kênh màu Xanh dương -> GPIO27

// Khởi tạo màn hình LCD 16x2 qua I2C (Địa chỉ 0x27)
LiquidCrystal_I2C lcd(0x27, 16, 2);
DHT dht(DHTPIN, DHTTYPE);

// Ngưỡng cảnh báo PPM để đổi màu LED RGB
const int CO2_WARNING_THRESHOLD = 1000; // ppm
const int CO_WARNING_THRESHOLD  = 9;    // ppm

// Thời gian polling hỏi lệnh (mỗi 1.5 giây hỏi 1 lần)
unsigned long lastPollTime = 0;
const unsigned long POLL_INTERVAL_MS = 1500;

// --- HÀM ĐIỀU KHIỂN ĐÈN LED RGB ---
void setRGB(int r, int g, int b) {
  analogWrite(PIN_LED_R, r);
  analogWrite(PIN_LED_G, g);
  analogWrite(PIN_LED_B, b);
}

// --- HÀM HIỆU ỨNG BOOT CHỚP TẤT CẢ MÀU KHI CẤP NGUỒN ---
void bootRGBAnimation() {
  int delayTime = 300; // Thời gian sáng mỗi màu (300ms)

  setRGB(255, 0, 0);   delay(delayTime); // Đỏ
  setRGB(0, 255, 0);   delay(delayTime); // Xanh lá
  setRGB(0, 0, 255);   delay(delayTime); // Xanh dương
  setRGB(255, 150, 0); delay(delayTime); // Vàng
  setRGB(255, 0, 255); delay(delayTime); // Tím
  setRGB(0, 255, 255); delay(delayTime); // Xanh lơ (Cyan)
  setRGB(255, 255, 255); delay(delayTime); // Trắng
  setRGB(0, 0, 0);     delay(200);       // Tắt hẳn 1 nhịp ngắn
}

// Hàm trích xuất commandId từ chuỗi JSON response mà không cần thư viện ngoài
int parseCommandId(String json) {
  int idx = json.indexOf("\"commandId\":");
  if (idx < 0) idx = json.indexOf("\"commandId\" :");
  if (idx >= 0) {
    int start = json.indexOf(':', idx) + 1;
    while (start < json.length() && (json[start] == ' ' || json[start] == '\"')) start++;
    int end = start;
    while (end < json.length() && isDigit(json[end])) end++;
    if (end > start) {
      return json.substring(start, end).toInt();
    }
  }
  return -1;
}

// Kiểm tra Wi-Fi và tự động kết nối lại nếu mất mạng
void checkWiFiConnection() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("\n[Wi-Fi] Mat ket noi, dang ket noi lai...");
    lcd.setCursor(0, 1);
    lcd.print("WiFi Reconnecting");
    setRGB(100, 50, 0); // Vàng cảnh báo
    WiFi.reconnect();
    int count = 0;
    while (WiFi.status() != WL_CONNECTED && count < 20) {
      delay(500);
      Serial.print(".");
      count++;
    }
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\n[Wi-Fi] Da ket noi lai thanh cong!");
      lcd.setCursor(0, 1);
      lcd.print("WiFi Connected!   ");
      delay(1000);
      lcd.clear();
    }
  }
}

// --- LUỒNG 1: POLLING HỎI LỆNH ĐO TỪ SERVER (/device/command) ---
int checkForMeasureCommand() {
  checkWiFiConnection();
  if (WiFi.status() != WL_CONNECTED) return -1;

  HTTPClient http;
  String fullUrl = String(serverHost) + String(cmdEndpoint);
  http.begin(fullUrl);
  http.setTimeout(3000);
  http.addHeader("X-Device-Code", deviceCode);
  http.addHeader("X-API-Key", apiKey);
  http.addHeader("Accept", "application/json");

  int httpCode = http.GET();
  int commandId = -1;

  if (httpCode == 200) {
    String payload = http.getString();
    // Server trả về: {"command":"NONE"} hoặc {"command":"START","commandId":12}
    if (payload.indexOf("\"START\"") >= 0) {
      commandId = parseCommandId(payload);
      Serial.printf("[Lệnh đo mới] Nhanh lenh START, commandId = %d\n", commandId);
    }
  } else if (httpCode == 401) {
    Serial.println("[Loi Auth 401] Sai Device-Code hoac API-Key trong DB!");
  } else if (httpCode < 0) {
    // Lỗi không kết nối được tới server (Sai IP, Firewall chặn, hoặc khác mạng)
    static unsigned long lastErrTime = 0;
    if (millis() - lastErrTime > 4000) {
      Serial.printf("[Loi ket noi Server] Code %d (%s) toi %s. Kiem tra IP may tinh & Firewall!\n", 
                    httpCode, http.errorToString(httpCode).c_str(), fullUrl.c_str());
      lastErrTime = millis();
    }
  } else {
    // Không log liên tục mã NONE để tránh ngập Serial
    if (httpCode != 200) {
      Serial.printf("[HTTP Code %d] kiem tra lenh\n", httpCode);
    }
  }
  http.end();
  return commandId;
}

// --- LUỒNG 2: THỰC HIỆN ĐO 5 GIÂY & GỬI DỮ LIỆU (/device/data) ---
void performMeasurementAndSend(int commandId) {
  Serial.printf("\n========================================\n");
  Serial.printf("BAT DAU PHIEN DO THU CONG - CMD #%d\n", commandId);
  Serial.printf("========================================\n");

  // Báo hiệu trên LCD và LED RGB (Đèn Vàng nhấp nháy báo đang đo)
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.printf("Measuring CMD #%d", commandId);

  float sumTemp = 0.0;
  float sumHumid = 0.0;
  long sumMQ135 = 0;
  long sumMQ7 = 0;
  int sampleCount = 0;

  // Đo trong 5 giây, lấy mẫu mỗi 1 giây (đếm ngược 5..4..3..2..1)
  for (int sec = 5; sec >= 1; sec--) {
    // Đổi màu LED nhấp nháy vàng khi đang lấy mẫu
    setRGB(180, 100, 0);

    float t = dht.readTemperature();
    float h = dht.readHumidity();
    int a135 = analogRead(MQ135_PIN);
    int a7   = analogRead(MQ7_PIN);

    // Xử lý nếu cảm biến chưa đọc kịp
    if (isnan(t) || isnan(h)) {
      t = 28.5;
      h = 65.0;
    }

    sumTemp += t;
    sumHumid += h;
    sumMQ135 += a135;
    sumMQ7 += a7;
    sampleCount++;

    // Hiển thị đếm ngược và chỉ số tức thời trên LCD
    lcd.setCursor(0, 1);
    lcd.printf("Time: %ds | %2.1fC", sec, t);

    delay(500);
    setRGB(0, 0, 0); // Nhấp nháy nhẹ
    delay(500);
  }

  // Tính giá trị trung bình sau 5 giây đo
  float avgTemp = sumTemp / sampleCount;
  float avgHumid = sumHumid / sampleCount;
  int avgRaw135 = sumMQ135 / sampleCount;
  int avgRaw7   = sumMQ7 / sampleCount;

  // Quy đổi sang PPM chuẩn với ngưỡng của dự án:
  // CO2 (MQ-135): Clean air ~400-500 ppm, ngưỡng cảnh báo 1000 ppm
  int co2 = map(avgRaw135, 170, 4095, 400, 2500);
  co2 = constrain(co2, 400, 5000);

  // CO (MQ-7): Clean air ~1-3 ppm, ngưỡng cảnh báo 9 ppm
  int co = map(avgRaw7, 400, 4095, 1, 50);
  co = constrain(co, 1, 100);

  Serial.printf("Ket qua do: Temp=%.2fC, Humid=%.2f%%, CO=%d ppm, CO2=%d ppm\n", avgTemp, avgHumid, co, co2);

  // Hiển thị kết quả tóm tắt lên LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.printf("T:%.1fC  H:%.1f%%", avgTemp, avgHumid);
  lcd.setCursor(0, 1);
  lcd.printf("CO:%2d  CO2:%4d", co, co2);

  // Đổi màu LED theo ngưỡng thực tế
  if (co2 > CO2_WARNING_THRESHOLD || co > CO_WARNING_THRESHOLD || avgTemp > 32.0 || avgHumid > 80.0) {
    setRGB(255, 0, 0); // 🔴 ĐỎ: Vượt ngưỡng an toàn
  } else {
    setRGB(0, 200, 0); // 🟢 XANH LÁ: An toàn
  }

  // Đóng gói JSON Payload chuẩn theo backend DeviceDataServlet
  // Gồm 5 trường: commandId, temp, humid, co, co2
  String jsonPayload = "{";
  jsonPayload += "\"commandId\":" + String(commandId) + ",";
  jsonPayload += "\"temp\":" + String(avgTemp, 2) + ",";
  jsonPayload += "\"humid\":" + String(avgHumid, 2) + ",";
  jsonPayload += "\"co\":" + String(co) + ",";
  jsonPayload += "\"co2\":" + String(co2);
  jsonPayload += "}";

  // Gửi POST tới /Airroom/device/data
  HTTPClient http;
  String fullUrl = String(serverHost) + String(dataEndpoint);
  http.begin(fullUrl);
  http.setTimeout(5000);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Code", deviceCode);
  http.addHeader("X-API-Key", apiKey);

  Serial.printf("[POST /device/data] URL: %s\n", fullUrl.c_str());
  Serial.printf("[Payload] %s\n", jsonPayload.c_str());

  int httpCode = http.POST(jsonPayload);

  if (httpCode == 200) {
    String resp = http.getString();
    Serial.printf("[Server Response 200 OK]: %s\n", resp.c_str());
    lcd.setCursor(14, 0);
    lcd.print("OK");
  } else {
    Serial.printf("[Loi gui data] HTTP %d: %s\n", httpCode, http.getString().c_str());
    lcd.setCursor(14, 0);
    lcd.print("ER");
  }
  http.end();

  // Giữ kết quả hiển thị trên LCD trong 4 giây rồi quay về màn hình chờ
  delay(4000);
  lcd.clear();
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  // 1. Khởi tạo màn hình LCD 16x2
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Air Station D001");
  lcd.setCursor(0, 1);
  lcd.print("Connecting WiFi.");

  // 2. Khai báo chân LED RGB (giữ nguyên cấu trúc chân cắm)
  pinMode(PIN_LED_R, OUTPUT);
  pinMode(PIN_LED_G, OUTPUT);
  pinMode(PIN_LED_B, OUTPUT);

  // Hiệu ứng chớp tất cả các màu khi mới cấp nguồn (Boot Animation)
  bootRGBAnimation();

  setRGB(0, 0, 150); // Xanh dương lúc khởi động

  dht.begin();
  pinMode(MQ135_PIN, INPUT);
  pinMode(MQ7_PIN, INPUT);

  // 3. Cấu hình Wi-Fi
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(true);
  delay(500);
  WiFi.setSleep(false);

  Serial.printf("\nDang ket noi Wi-Fi: %s", ssid);
  WiFi.begin(ssid, password);

  int retry_count = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    lcd.print(".");
    retry_count++;
    if (retry_count > 30) {
      Serial.println("\n[Canh bao] Thu noi lai Wi-Fi...");
      WiFi.disconnect();
      WiFi.begin(ssid, password);
      retry_count = 0;
      lcd.setCursor(0, 1);
      lcd.print("Reconnecting... ");
    }
  }

  Serial.println("\n-> Wi-Fi da ket noi thanh cong!");
  Serial.print("-> ESP32 IP: ");
  Serial.println(WiFi.localIP());
  delay(2000);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("D001 Online!");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP());
  setRGB(0, 100, 0); // Xanh lá nhẹ: Sẵn sàng
  delay(2000);
  lcd.clear();
}

void loop() {
  checkWiFiConnection();

  // 1. Cập nhật thông số môi trường tức thời lên màn hình LCD ở chế độ chờ
  float liveTemp = dht.readTemperature();
  float liveHumid = dht.readHumidity();
  if (isnan(liveTemp) || isnan(liveHumid)) {
    liveTemp = 28.0;
    liveHumid = 65.0;
  }
  
  lcd.setCursor(0, 0);
  lcd.printf("D001: Ready CMD ");
  lcd.setCursor(0, 1);
  lcd.printf("T:%.1fC  H:%.1f%%  ", liveTemp, liveHumid);
  setRGB(0, 40, 100); // Xanh cyan dịu ở chế độ chờ

  // 2. Polling hỏi lệnh đo từ server mỗi POLL_INTERVAL_MS (1.5 giây)
  if (millis() - lastPollTime >= POLL_INTERVAL_MS) {
    lastPollTime = millis();
    int cmdId = checkForMeasureCommand();

    // Nếu server có lệnh START -> tiến hành đo 5 giây và gửi kết quả
    if (cmdId >= 0) {
      performMeasurementAndSend(cmdId);
    }
  }

  delay(200);
}