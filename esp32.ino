// ============================================================
// COW MILK YIELD SYSTEM — ESP32-S3 CAM N16R8 + OV2640
// RC522 + HX711 + LCD + Camera + WiFiManager + Firebase + NTP
// WiFi reset: hold BOOT button (GPIO0) for 5 seconds
// ============================================================

#include <SPI.h>
#include <MFRC522.h>
#include <HX711.h>
#include <WiFi.h>
#include <WiFiManager.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <time.h>
#include "esp_camera.h"

// ── Firebase ─────────────────────────────────────────────────
#define FIREBASE_DB_URL \
  "https://cow-milk-system-default-rtdb.europe-west1.firebasedatabase.app"

// ── Vision Server ────────────────────────────────────────────
#define VISION_SERVER "https://cow-farm-server.onrender.com/identify"

// ── NTP ──────────────────────────────────────────────────────
#define NTP_SERVER      "pool.ntp.org"
#define GMT_OFFSET_SEC   3600
#define DST_OFFSET_SEC   0

// ── LCD ──────────────────────────────────────────────────────
#define LCD_ADDR  0x27
#define SDA_PIN   21
#define SCL_PIN   19

// ── RC522 Pins ───────────────────────────────────────────────
#define SCK_PIN   47
#define MISO_PIN  48
#define MOSI_PIN  45
#define SS_PIN    42
#define RST_PIN   41

// ── HX711 Pins ───────────────────────────────────────────────
#define HX711_DOUT 14
#define HX711_SCK  40

// ── Button Pins ──────────────────────────────────────────────
#define BTN_ENTER   2    // cow enters
#define BTN_DONE    1    // cow done
#define BTN_BOOT    0    // BOOT button on board = WiFi reset

// ── Scale ────────────────────────────────────────────────────
#define CALIBRATION_FACTOR -7050.0

// ── Timing ───────────────────────────────────────────────────
#define LCD_MSG_SHORT_MS       800
#define LCD_MSG_MEDIUM_MS     1500
#define LCD_MSG_LONG_MS       2000
#define SESSION_POLL_MS       1000
#define DATE_CHECK_INTERVAL  30000UL
#define CLOCK_REFRESH_INTERVAL 30000UL
#define WIFI_RECONNECT_TIMEOUT 8000UL
#define NTP_SYNC_TIMEOUT      10000UL
#define HTTP_TIMEOUT_MS        5000
#define HTTP_CONNECT_TIMEOUT   3000
#define SCALE_INIT_TIMEOUT     5000UL
#define DEBOUNCE_MS              50
#define WIFI_RESET_HOLD_MS     5000UL  // hold BOOT 5s to reset WiFi

// ── OV2640 Camera Pins ───────────────────────────────────────
#define PWDN_GPIO_NUM   -1
#define RESET_GPIO_NUM  -1
#define XCLK_GPIO_NUM   15
#define SIOD_GPIO_NUM    4
#define SIOC_GPIO_NUM    5
#define Y2_GPIO_NUM     11
#define Y3_GPIO_NUM      9
#define Y4_GPIO_NUM      8
#define Y5_GPIO_NUM     10
#define Y6_GPIO_NUM     12
#define Y7_GPIO_NUM     18
#define Y8_GPIO_NUM     17
#define Y9_GPIO_NUM     16
#define VSYNC_GPIO_NUM   6
#define HREF_GPIO_NUM    7
#define PCLK_GPIO_NUM   13

// ── Cow Registry ─────────────────────────────────────────────
struct Cow {
  const char* uid;
  const char* name;
  float       dailyMilk;
  int         sessions;
};

#define NUM_COWS 3
Cow cows[NUM_COWS] = {
  { "8B1FA004", "Bessie", 0.0f, 0 },
  { "09AE7D05", "Daisy",  0.0f, 0 },
  { "AABBCCDD", "Molly",  0.0f, 0 }
};

// ── Hardware ─────────────────────────────────────────────────
MFRC522           rfid(SS_PIN, RST_PIN);
HX711             scale;
LiquidCrystal_I2C lcd(LCD_ADDR, 16, 2);

// ── State Machine ────────────────────────────────────────────
enum State { IDLE, WAITING_RFID, MEASURING };
State currentState   = IDLE;
int   activeCow      = -1;

// ── Session metadata ─────────────────────────────────────────
float  activeVisionConf = 0.0f;
String activeIdMethod   = "unknown";

// ── Date tracking ────────────────────────────────────────────
char currentDate[12] = "";

// ── Edge-detection buttons ───────────────────────────────────
struct ButtonState {
  int           pin;
  bool          lastReading;
  bool          triggered;
  unsigned long lastDebounce;
};

ButtonState btn_enter = { BTN_ENTER, HIGH, false, 0 };
ButtonState btn_done  = { BTN_DONE,  HIGH, false, 0 };

// ── BOOT button long-press state ─────────────────────────────
unsigned long bootBtnHeldSince = 0;
bool          bootBtnActive    = false;

// ============================================================
// FORWARD DECLARATIONS
// ============================================================
void   lcdShow(const char* line1, const char* line2 = "");
void   lcdValue(const char* label, float val, const char* unit);
bool   buttonPressed(ButtonState& btn);
void   checkBootButton();
void   resetWiFi();
void   connectWiFi();
void   maintainWiFi();
void   syncTime();
String getDateString();
String getTimeString();
void   checkAndResetDate();
void   restoreDailyTotalsFromFirebase();
bool   initCamera();
String captureAndIdentify();
bool   firebasePut(const String& path, const String& json);
bool   firebasePost(const String& path, const String& json);
void   sendToFirebase(int cowIdx, float sessionKg,
                      const String& idMethod, float visionConf);
void   restoreDailyTotalsFromFirebase();
float  getFilteredWeight(int samples);
void   finishSession();
String getUID();
int    findCowByUID(const String& uid);
int    findCowByName(const String& name);
void   printSeparator();
void   printDailySummary();
void   showIdleScreen();
void   scanI2C();

// ============================================================
// BUTTON — edge detection, fires once per press
// ============================================================
bool buttonPressed(ButtonState& btn) {
  bool reading = digitalRead(btn.pin);
  if (reading != btn.lastReading)
    btn.lastDebounce = millis();

  bool fired = false;
  if (millis() - btn.lastDebounce > DEBOUNCE_MS) {
    if (reading == LOW && !btn.triggered) {
      fired         = true;
      btn.triggered = true;
    }
    if (reading == HIGH)
      btn.triggered = false;
  }
  btn.lastReading = reading;
  return fired;
}

// ============================================================
// BOOT BUTTON — long press (5s) to reset WiFi
// Call every loop iteration — non-blocking
// ============================================================
void checkBootButton() {
  bool pressed = (digitalRead(BTN_BOOT) == LOW);

  if (pressed) {
    if (!bootBtnActive) {
      bootBtnActive    = true;
      bootBtnHeldSince = millis();
      Serial.println("🔵 BOOT button held — release to cancel WiFi reset");
    }

    unsigned long heldMs = millis() - bootBtnHeldSince;

    // Show countdown after 2 seconds
    if (heldMs >= 2000 && heldMs < WIFI_RESET_HOLD_MS) {
      int secsLeft = (WIFI_RESET_HOLD_MS - heldMs) / 1000 + 1;
      lcd.clear();
      lcd.setCursor(0, 0); lcd.print("Maintenir: Reset WiFi");
      lcd.setCursor(0, 1); lcd.print("Relacher=annul ");
      lcd.print(secsLeft);
      lcd.print("s");
    }

    // Trigger after 5 seconds
    if (heldMs >= WIFI_RESET_HOLD_MS) {
      bootBtnActive = false;
      resetWiFi();
    }

  } else {
    // Released before 5s — cancel and restore screen
    if (bootBtnActive) {
      bootBtnActive = false;
      Serial.println("   BOOT released early — cancelled.");
      if (currentState == IDLE) showIdleScreen();
    }
  }
}

// ============================================================
// LCD HELPERS
// ============================================================
void lcdShow(const char* line1, const char* line2) {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(line1);
  if (line2 && strlen(line2) > 0) {
    lcd.setCursor(0, 1);
    lcd.print(line2);
  }
}

void lcdValue(const char* label, float val, const char* unit) {
  lcd.setCursor(0, 1);
  lcd.print(label);
  lcd.print(val, 2);
  lcd.print(unit);
  lcd.print("    ");
}

// ============================================================
// WIFI RESET
// ============================================================
void resetWiFi() {
  Serial.println("🔴 Resetting WiFi credentials...");
  lcdShow("Reset WiFi!", "Redemarrage...");
  delay(2000);

  WiFiManager wm;
  wm.resetSettings();
  ESP.restart();
}

// ============================================================
// WIFIMANAGER
// ============================================================
void connectWiFi() {
  WiFiManager wm;
  wm.setConfigPortalTimeout(180);

  lcdShow("Connexion WiFi", "NutriLait-Setup");
  Serial.println("📶 WiFiManager starting...");
  Serial.println("   No saved WiFi → connect to: NutriLait-Setup");
  Serial.println("   Password: cow12345 → open 192.168.4.1");

  bool ok = wm.autoConnect("NutriLait-Setup", "cow12345");

  if (ok) {
    Serial.println("✅ WiFi connected!");
    Serial.print("   IP: "); Serial.println(WiFi.localIP());
    lcdShow("WiFi OK!", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("⚠️  Portal timed out — offline mode.");
    lcdShow("Echec WiFi", "Mode hors ligne");
  }
  delay(LCD_MSG_LONG_MS);
}

// ============================================================
// MAINTAIN WIFI
// ============================================================
void maintainWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  Serial.println("📶 Reconnecting WiFi...");
  WiFi.reconnect();
  unsigned long t = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t < WIFI_RECONNECT_TIMEOUT) {
    delay(500); yield();
  }
  if (WiFi.status() == WL_CONNECTED)
    Serial.println("✅ WiFi reconnected.");
  else
    Serial.println("⚠️  WiFi still offline.");
}

// ============================================================
// NTP TIME SYNC — with 3s settle + 3 attempts + backup servers
// ============================================================
void syncTime() {
  if (WiFi.status() != WL_CONNECTED) return;

  lcdShow("Synchro heure...", "Veuillez patienter");

  // Allow network stack to fully settle after WiFi connect
  Serial.print("🕐 Waiting for network to settle");
  for (int i = 0; i < 3; i++) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println();

  const int MAX_ATTEMPTS = 3;
  bool synced = false;

  for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    Serial.printf("   NTP attempt %d/%d...\n", attempt, MAX_ATTEMPTS);

    configTime(GMT_OFFSET_SEC, DST_OFFSET_SEC,
               NTP_SERVER,
               "time.cloudflare.com",
               "time.windows.com");

    struct tm t;
    unsigned long start = millis();
    while (!getLocalTime(&t) && millis() - start < NTP_SYNC_TIMEOUT) {
      delay(500); yield();
    }

    if (getLocalTime(&t)) {
      synced = true;
      char buf[20];
      strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M", &t);
      Serial.println("✅ Time synced: " + String(buf));
      lcdShow("Heure synchronisee!", buf);
      delay(LCD_MSG_MEDIUM_MS);
      break;
    }

    Serial.printf("   ⚠️  Attempt %d failed", attempt);
    if (attempt < MAX_ATTEMPTS) {
      Serial.println(" — retrying in 2s...");
      delay(2000);
    } else {
      Serial.println();
    }
  }

  if (!synced) {
    Serial.println("⚠️  NTP failed — uptime fallback.");
    lcdShow("Echec NTP", "Mode secours");
    delay(LCD_MSG_MEDIUM_MS);
  }
}

// ============================================================
// TIMESTAMPS
// ============================================================
String getDateString() {
  struct tm t;
  if (!getLocalTime(&t)) {
    char buf[12];
    sprintf(buf, "day-%lu", millis() / 86400000UL);
    return String(buf);
  }
  char buf[12];
  strftime(buf, sizeof(buf), "%Y-%m-%d", &t);
  return String(buf);
}

String getTimeString() {
  struct tm t;
  if (!getLocalTime(&t)) {
    unsigned long s = millis() / 1000UL;
    char buf[10];
    sprintf(buf, "%02lu:%02lu:%02lu", (s/3600)%24, (s/60)%60, s%60);
    return String(buf);
  }
  char buf[10];
  strftime(buf, sizeof(buf), "%H:%M:%S", &t);
  return String(buf);
}

// ============================================================
// DAILY RESET
// ============================================================
void checkAndResetDate() {
  String today = getDateString();
  if (strlen(currentDate) == 0) {
    today.toCharArray(currentDate, sizeof(currentDate));
    Serial.print("📅 Date set: "); Serial.println(currentDate);
    return;
  }
  if (today != String(currentDate)) {
    Serial.println("📅 New day — resetting daily totals.");
    for (int i = 0; i < NUM_COWS; i++) {
      cows[i].dailyMilk = 0.0f;
      cows[i].sessions  = 0;
    }
    today.toCharArray(currentDate, sizeof(currentDate));
  }
}

// ============================================================
// RESTORE TODAY'S TOTALS FROM FIREBASE AFTER REBOOT
// ============================================================
void restoreDailyTotalsFromFirebase() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️  No WiFi — cannot restore daily totals.");
    return;
  }

  String today = getDateString();
  if (today.startsWith("day-")) {
    Serial.println("⚠️  No real date — skipping restore.");
    return;
  }

  Serial.println("🔄 Restoring today's totals from Firebase...");
  lcdShow("Restauration...", today.c_str());

  bool anyRestored = false;

  for (int i = 0; i < NUM_COWS; i++) {
    String path = String(FIREBASE_DB_URL)
                + "/cows/" + String(cows[i].name)
                + "/history/" + today + ".json";

    HTTPClient http;
    http.begin(path);
    http.setTimeout(HTTP_TIMEOUT_MS);
    http.setConnectTimeout(HTTP_CONNECT_TIMEOUT);

    int code = http.GET();

    if (code == 200) {
      String payload = http.getString();
      http.end();

      if (payload == "null" || payload.isEmpty()) {
        Serial.printf("   %s: no data yet today\n", cows[i].name);
        continue;
      }

      StaticJsonDocument<256> doc;
      if (deserializeJson(doc, payload)) {
        Serial.printf("   ❌ %s: JSON parse error\n", cows[i].name);
        continue;
      }

      cows[i].dailyMilk = doc["daily_milk_kg"] | 0.0f;
      cows[i].sessions  = doc["sessions"]       | 0;

      Serial.printf("   ✅ %s: %.3f kg, %d sessions restored\n",
                    cows[i].name, cows[i].dailyMilk, cows[i].sessions);
      anyRestored = true;

    } else {
      Serial.printf("   ⚠️  %s: HTTP %d\n", cows[i].name, code);
      http.end();
    }
  }

  if (anyRestored) lcdShow("Totaux restaures", today.c_str());
  else             lcdShow("Nouvelle journee", today.c_str());
  delay(LCD_MSG_MEDIUM_MS);
}

// ============================================================
// FIREBASE REST — PUT
// ============================================================
bool firebasePut(const String& path, const String& json) {
  if (WiFi.status() != WL_CONNECTED) return false;
  HTTPClient http;
  http.begin(String(FIREBASE_DB_URL) + path + ".json");
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(HTTP_TIMEOUT_MS);
  http.setConnectTimeout(HTTP_CONNECT_TIMEOUT);
  int  code = http.PUT(json);
  bool ok   = (code == 200 || code == 204);
  if (!ok) Serial.printf("❌ PUT failed: %d\n", code);
  http.end();
  return ok;
}

// ============================================================
// FIREBASE REST — POST
// ============================================================
bool firebasePost(const String& path, const String& json) {
  if (WiFi.status() != WL_CONNECTED) return false;
  HTTPClient http;
  http.begin(String(FIREBASE_DB_URL) + path + ".json");
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(HTTP_TIMEOUT_MS);
  http.setConnectTimeout(HTTP_CONNECT_TIMEOUT);
  int  code = http.POST(json);
  bool ok   = (code == 200 || code == 204);
  if (!ok) Serial.printf("❌ POST failed: %d\n", code);
  http.end();
  return ok;
}

// ============================================================
// SEND TO FIREBASE
// ============================================================
void sendToFirebase(int cowIdx, float sessionKg,
                    const String& idMethod, float visionConf) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️  No WiFi — data not saved.");
    lcdShow("Pas de WiFi!", "Donnees non sauv.");
    delay(LCD_MSG_LONG_MS);
    return;
  }

  Cow&   cow  = cows[cowIdx];
  String date = getDateString();
  String time = getTimeString();

  lcdShow("Envoi...", "Veuillez patienter");
  Serial.println("📤 Sending to Firebase...");

  // Daily history
  StaticJsonDocument<256> histDoc;
  histDoc["uid"]           = cow.uid;
  histDoc["daily_milk_kg"] = serialized(String(cow.dailyMilk, 3));
  histDoc["sessions"]      = cow.sessions;
  histDoc["last_updated"]  = time;
  String histJson;
  serializeJson(histDoc, histJson);
  bool ok1 = firebasePut("/cows/" + String(cow.name) + "/history/" + date, histJson);
  Serial.println(ok1 ? "   ✅ History updated." : "   ❌ History failed.");

  // Session log
  StaticJsonDocument<256> sessionDoc;
  sessionDoc["cow"]         = cow.name;
  sessionDoc["uid"]         = cow.uid;
  sessionDoc["milk_kg"]     = serialized(String(sessionKg, 3));
  sessionDoc["session_num"] = cow.sessions;
  sessionDoc["date"]        = date;
  sessionDoc["time"]        = time;
  sessionDoc["id_method"]   = idMethod;
  sessionDoc["vision_conf"] = visionConf;
  String sessionJson;
  serializeJson(sessionDoc, sessionJson);
  bool ok2 = firebasePost("/sessions/" + date, sessionJson);
  Serial.println(ok2 ? "   ✅ Session pushed." : "   ❌ Session failed.");

  if (ok1 && ok2) lcdShow("Firebase OK!", "Donnees sauvees");
  else            lcdShow("Erreur Firebase", "Voir moniteur");
  delay(LCD_MSG_LONG_MS);
}

// ============================================================
// CAMERA INIT — OV2640
// ============================================================
bool initCamera() {
  camera_config_t config;
  config.ledc_channel  = LEDC_CHANNEL_0;
  config.ledc_timer    = LEDC_TIMER_0;
  config.pin_d0        = Y2_GPIO_NUM;
  config.pin_d1        = Y3_GPIO_NUM;
  config.pin_d2        = Y4_GPIO_NUM;
  config.pin_d3        = Y5_GPIO_NUM;
  config.pin_d4        = Y6_GPIO_NUM;
  config.pin_d5        = Y7_GPIO_NUM;
  config.pin_d6        = Y8_GPIO_NUM;
  config.pin_d7        = Y9_GPIO_NUM;
  config.pin_xclk      = XCLK_GPIO_NUM;
  config.pin_pclk      = PCLK_GPIO_NUM;
  config.pin_vsync     = VSYNC_GPIO_NUM;
  config.pin_href      = HREF_GPIO_NUM;
  config.pin_sscb_sda  = SIOD_GPIO_NUM;
  config.pin_sscb_scl  = SIOC_GPIO_NUM;
  config.pin_pwdn      = PWDN_GPIO_NUM;
  config.pin_reset     = RESET_GPIO_NUM;
  config.xclk_freq_hz  = 20000000;
  config.pixel_format  = PIXFORMAT_JPEG;

  if (psramFound()) {
    config.frame_size   = FRAMESIZE_VGA;
    config.jpeg_quality = 8;
    config.fb_count     = 2;
    config.fb_location  = CAMERA_FB_IN_PSRAM;
    config.grab_mode    = CAMERA_GRAB_LATEST;
  } else {
    config.frame_size   = FRAMESIZE_QVGA;
    config.jpeg_quality = 10;
    config.fb_count     = 1;
    config.fb_location  = CAMERA_FB_IN_DRAM;
    config.grab_mode    = CAMERA_GRAB_WHEN_EMPTY;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("❌ Camera init failed: 0x%x\n", err);
    lcdShow("Erreur Camera!", "Verifier cablage");
    return false;
  }

  sensor_t* s = esp_camera_sensor_get();
  if (s != NULL) {
    s->set_vflip(s, 1);
    s->set_hmirror(s, 0);
    s->set_brightness(s, 2);
    s->set_contrast(s, 2);
    s->set_saturation(s, -1);
    s->set_whitebal(s, 1);
    s->set_awb_gain(s, 1);
    s->set_exposure_ctrl(s, 1);
    s->set_aec2(s, 1);
    s->set_gain_ctrl(s, 1);
    s->set_agc_gain(s, 0);
    s->set_aec_value(s, 400);

    Serial.println("   Warming up camera...");
    for (int i = 0; i < 3; i++) {
      camera_fb_t* w = esp_camera_fb_get();
      if (w) esp_camera_fb_return(w);
      delay(200);
    }
    Serial.println("✅ OV2640 tuning applied.");
  }

  Serial.println("✅ Camera initialized!");
  return true;
}

// ============================================================
// CAPTURE AND IDENTIFY
// ============================================================
String captureAndIdentify() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️  No WiFi — skipping vision.");
    return "no_wifi";
  }

  Serial.println("📸 Capturing photo...");
  lcdShow("Analyse...", "Camera active");

  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("❌ Camera capture failed.");
    lcdShow("Echec camera", "RFID seul");
    delay(LCD_MSG_MEDIUM_MS);
    return "capture_error";
  }

  Serial.printf("   Photo: %u bytes\n", fb->len);

  HTTPClient http;
  http.begin(VISION_SERVER);
  http.addHeader("Content-Type", "image/jpeg");
  http.setTimeout(HTTP_TIMEOUT_MS);
  http.setConnectTimeout(HTTP_CONNECT_TIMEOUT);

  int code = http.POST(fb->buf, fb->len);
  esp_camera_fb_return(fb);
  fb = nullptr;

  if (code != 200) {
    Serial.printf("❌ Vision server error: %d\n", code);
    http.end();
    return "server_error";
  }

  String response = http.getString();
  http.end();
  Serial.print("📡 Vision: "); Serial.println(response);

  StaticJsonDocument<128> doc;
  if (deserializeJson(doc, response)) {
    Serial.println("❌ JSON parse error.");
    return "parse_error";
  }

  String status = doc["status"].as<String>();
  String cow    = doc["cow"].as<String>();
  float  conf   = doc["confidence"].as<float>();

  if (status == "ok") {
    Serial.printf("✅ Vision: %s (%.1f%%)\n", cow.c_str(), conf);
    return cow;
  }
  if (status == "bad_image") {
    Serial.println("⚠️  Bad image — check lighting.");
    return "bad_image";
  }

  Serial.printf("⚠️  Vision status: %s\n", status.c_str());
  return "unknown";
}

// ============================================================
// FILTERED WEIGHT — median of samples, spike rejection
// ============================================================
float getFilteredWeight(int samples = 10) {
  if (samples > 10) samples = 10;
  float readings[10];
  int   valid = 0;

  for (int i = 0; i < samples; i++) {
    float r = scale.get_units(1);
    if (r > -1.0f && r < 50.0f)
      readings[valid++] = r;
    delay(10);
    yield();
  }

  if (valid == 0) return 0.0f;

  for (int i = 1; i < valid; i++) {
    float key = readings[i];
    int   j   = i - 1;
    while (j >= 0 && readings[j] > key) {
      readings[j+1] = readings[j--];
    }
    readings[j+1] = key;
  }

  float median = readings[valid / 2];
  return (median < 0.0f) ? 0.0f : median;
}

// ============================================================
// HELPERS
// ============================================================
String getUID() {
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uid += "0";
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  return uid;
}

int findCowByUID(const String& uid) {
  for (int i = 0; i < NUM_COWS; i++)
    if (uid.equalsIgnoreCase(cows[i].uid)) return i;
  return -1;
}

int findCowByName(const String& name) {
  for (int i = 0; i < NUM_COWS; i++)
    if (name.equalsIgnoreCase(cows[i].name)) return i;
  return -1;
}

void printSeparator() { Serial.println("============================"); }

void printDailySummary() {
  Serial.println("\n──── DAILY SUMMARY ── " + getDateString() + " ──");
  for (int i = 0; i < NUM_COWS; i++)
    Serial.printf("  %-8s [%s]: %.3f kg (%d sessions)\n",
                  cows[i].name, cows[i].uid,
                  cows[i].dailyMilk, cows[i].sessions);
  Serial.println();
}

void showIdleScreen() {
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print("BTN1 pour entree");
  lcd.setCursor(0, 1); lcd.print("Heure: ");
  lcd.print(getTimeString().substring(0, 5));
}

void scanI2C() {
  Serial.println("🔍 Scanning I2C bus...");
  for (byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0)
      Serial.printf("   Found: 0x%02X\n", addr);
    yield();
  }
  Serial.println("   I2C scan done.");
}

// ============================================================
// FINISH SESSION
// ============================================================
void finishSession() {
  float sessionKg = getFilteredWeight(10);
  if (sessionKg < 0.0f) sessionKg = 0.0f;

  Cow& cow = cows[activeCow];
  cow.dailyMilk += sessionKg;
  cow.sessions++;

  printSeparator();
  Serial.printf("✅ Done   : %s\n",       cow.name);
  Serial.printf("   Session : %.3f kg\n", sessionKg);
  Serial.printf("   Daily   : %.3f kg\n", cow.dailyMilk);
  Serial.printf("   Sessions: %d\n",      cow.sessions);
  printSeparator();

  // Screen 1 — session result
  lcd.clear();
  lcd.setCursor(0, 0);
  char s1[17];
  snprintf(s1, sizeof(s1), "%-9s Termine!", cow.name);
  lcd.print(s1);
  lcdValue("Recu: ", sessionKg, " kg");
  delay(3000);

  // Screen 2 — daily total
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print("Total journal.:");
  lcdValue("", cow.dailyMilk, " kg");
  delay(3000);

  // Screen 3 — session count
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print("Sessions ajd:");
  lcd.setCursor(0, 1); lcd.print(cow.sessions);
  lcd.print(cow.sessions > 1 ? " sessions" : " session");
  delay(LCD_MSG_LONG_MS);

  sendToFirebase(activeCow, sessionKg, activeIdMethod, activeVisionConf);
  printDailySummary();

  activeCow        = -1;
  activeVisionConf = 0.0f;
  activeIdMethod   = "unknown";
  currentState     = IDLE;

  Serial.println("Waiting... Press BTN_ENTER for next cow.\n");
  showIdleScreen();
}

// ============================================================
// SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n🐄 Cow Milk System — ESP32-S3 + OV2640");
  printSeparator();

  // ── Buttons ──────────────────────────────────────────────────
  pinMode(BTN_ENTER, INPUT_PULLUP);
  pinMode(BTN_DONE,  INPUT_PULLUP);
  pinMode(BTN_BOOT,  INPUT_PULLUP);   // BOOT button = GPIO0

  // ── LCD ──────────────────────────────────────────────────────
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000);
  delay(300);
  scanI2C();
  lcd.init();
  lcd.backlight();
  lcdShow("NutriLait", "Demarrage...");
  delay(1000);
  Serial.println("✅ LCD ready.");

  // ── RFID ─────────────────────────────────────────────────────
  SPI.begin(SCK_PIN, MISO_PIN, MOSI_PIN, SS_PIN);
  rfid.PCD_Init();
  delay(100);
  byte v = rfid.PCD_ReadRegister(rfid.VersionReg);
  if (v == 0x00 || v == 0xFF) {
    Serial.println("❌ RC522 not detected!");
    lcdShow("RC522 Error!", "Verifier cablage");
    delay(3000);
  } else {
    Serial.printf("✅ RC522 OK (v0x%02X)\n", v);
    lcdShow("RFID Pret", "");
    delay(LCD_MSG_SHORT_MS);
  }

  // ── HX711 ────────────────────────────────────────────────────
  scale.begin(HX711_DOUT, HX711_SCK);
  delay(LCD_MSG_LONG_MS);

  unsigned long hxStart = millis();
  while (!scale.is_ready() && millis() - hxStart < SCALE_INIT_TIMEOUT) {
    delay(100); yield();
  }
  if (!scale.is_ready()) {
    Serial.println("❌ HX711 not ready — rebooting.");
    lcdShow("HX711 Error!", "Redemarrage...");
    delay(3000);
    ESP.restart();
  }
  scale.set_scale(CALIBRATION_FACTOR);
  scale.tare();
  Serial.println("✅ HX711 ready and tared.");
  lcdShow("Balance Prete", "Tarage OK");
  delay(LCD_MSG_SHORT_MS);

  // ── Camera ───────────────────────────────────────────────────
  if (initCamera()) {
    lcdShow("Camera Prete", "OV2640 OK");
    delay(LCD_MSG_SHORT_MS);
  }

  // ── WiFi + NTP ───────────────────────────────────────────────
  connectWiFi();
  syncTime();
  checkAndResetDate();
  restoreDailyTotalsFromFirebase();

  printSeparator();
  Serial.println("✅ System Ready!");
  Serial.print("   Date: "); Serial.println(currentDate);
  Serial.println("   BTN_ENTER = Cow enters");
  Serial.println("   BTN_DONE  = Cow done");
  Serial.println("   BOOT (G0) hold 5s = Reset WiFi");
  printSeparator();

  showIdleScreen();
}

// ============================================================
// MAIN LOOP
// ============================================================
void loop() {

  maintainWiFi();

  // ── BOOT button check (WiFi reset) — runs every loop ─────────
  checkBootButton();

  // ── Periodic date check ──────────────────────────────────────
  static unsigned long lastDateCheck    = 0;
  static unsigned long lastClockRefresh = 0;

  if (millis() - lastDateCheck > DATE_CHECK_INTERVAL) {
    lastDateCheck = millis();
    checkAndResetDate();
  }

  if (currentState == IDLE &&
      millis() - lastClockRefresh > CLOCK_REFRESH_INTERVAL) {
    lastClockRefresh = millis();
    showIdleScreen();
  }

  // ── IDLE ─────────────────────────────────────────────────────
  if (currentState == IDLE) {

    if (buttonPressed(btn_enter)) {
      Serial.println("\n🔵 Cow entering — scan RFID...");
      lcdShow("Vache entree...", "Scanner RFID");
      currentState = WAITING_RFID;
      activeCow    = -1;
    }
  }

  // ── WAITING_RFID ─────────────────────────────────────────────
  else if (currentState == WAITING_RFID) {

    if (buttonPressed(btn_enter)) {
      Serial.println("↩️  Annule.");
      lcdShow("Annule", "");
      delay(LCD_MSG_SHORT_MS);
      showIdleScreen();
      currentState = IDLE;
      return;
    }

    if (!rfid.PICC_IsNewCardPresent()) { delay(50); return; }
    if (!rfid.PICC_ReadCardSerial())   { delay(50); return; }

    String uid = getUID();
    Serial.print("📡 RFID: "); Serial.println(uid);

    int rfidIdx = findCowByUID(uid);

    String visionName = captureAndIdentify();
    float  visionConf = 0.0f;
    String idMethod   = "unknown";
    int    resolvedIdx = -1;

    if (rfidIdx >= 0) {
      String rfidName = String(cows[rfidIdx].name);

      bool visionError = (visionName == "unknown"       ||
                          visionName == "no_wifi"        ||
                          visionName == "server_error"   ||
                          visionName == "capture_error"  ||
                          visionName == "parse_error"    ||
                          visionName == "bad_image");

      if (!visionError && visionName == rfidName) {
        idMethod    = "RFID+Vision";
        visionConf  = 95.0f;
        resolvedIdx = rfidIdx;
        Serial.println("✅ RFID + Vision MATCH: " + rfidName);
        lcd.clear();
        lcd.setCursor(0, 0); lcd.print(rfidName);
        lcd.setCursor(0, 1); lcd.print("ID: RFID+Vision");
        delay(LCD_MSG_MEDIUM_MS);

      } else if (visionError) {
        idMethod    = "RFID_only";
        visionConf  = 0.0f;
        resolvedIdx = rfidIdx;
        Serial.println("⚠️  RFID seul (vision unavailable).");
        lcd.clear();
        lcd.setCursor(0, 0); lcd.print(rfidName);
        lcd.setCursor(0, 1); lcd.print("ID: RFID seul");
        delay(LCD_MSG_MEDIUM_MS);

      } else {
        idMethod    = "RFID_mismatch";
        visionConf  = 0.0f;
        resolvedIdx = rfidIdx;
        Serial.println("⚠️  Mismatch! RFID=" + rfidName +
                       " Vision=" + visionName);
        lcd.clear();
        lcd.setCursor(0, 0); lcd.print(rfidName);
        lcd.setCursor(0, 1); lcd.print("Conflit: RFID");
        delay(LCD_MSG_MEDIUM_MS);
      }

    } else {
      bool visionError = (visionName == "unknown"       ||
                          visionName == "no_wifi"        ||
                          visionName == "server_error"   ||
                          visionName == "capture_error"  ||
                          visionName == "parse_error"    ||
                          visionName == "bad_image");
      if (!visionError) {
        int visionIdx = findCowByName(visionName);
        if (visionIdx >= 0) {
          idMethod    = "Vision_only";
          visionConf  = 75.0f;
          resolvedIdx = visionIdx;
          Serial.println("⚠️  Vision only: " + visionName);
          lcd.clear();
          lcd.setCursor(0, 0); lcd.print(visionName);
          lcd.setCursor(0, 1); lcd.print("ID: Vision seule");
          delay(LCD_MSG_MEDIUM_MS);
        }
      }
    }

    if (resolvedIdx < 0) {
      Serial.println("❓ Unknown cow.");
      lcdShow("Vache inconnue!", "Verifier RFID");
      delay(LCD_MSG_LONG_MS);
      lcdShow("Vache entree...", "Scanner RFID");
      rfid.PICC_HaltA();
      rfid.PCD_StopCrypto1();
      return;
    }

    activeCow        = resolvedIdx;
    activeIdMethod   = idMethod;
    activeVisionConf = visionConf;

    Cow& cow = cows[activeCow];
    printSeparator();
    Serial.printf("✅ Identified : %s\n", cow.name);
    Serial.printf("   Method     : %s\n", idMethod.c_str());
    Serial.printf("   Confidence : %.1f%%\n", visionConf);

    lcdShow(cow.name, "Tarage balance...");
    scale.tare();
    delay(500);
    Serial.println("✅ Scale tared. Milking started.");
    Serial.println("   Press BTN_DONE when done.\n");

    lcd.clear();
    lcd.setCursor(0, 0);
    char top[17];
    snprintf(top, sizeof(top), "%-9s Milk", cow.name);
    lcd.print(top);
    lcd.setCursor(0, 1); lcd.print("Direct:0.000kg");
    currentState   = MEASURING;

    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
  }

  // ── MEASURING ────────────────────────────────────────────────
  else if (currentState == MEASURING) {

    
    static unsigned long lastPrint = 0;
    if (millis() - lastPrint > SESSION_POLL_MS) {
      lastPrint = millis();
      float live = getFilteredWeight(5);
      Serial.printf("  ⚖️  %.3f kg\n", live);
      lcd.setCursor(0, 1);
      lcd.print("Direct:");
      lcd.print(live, 3);
      lcd.print(" kg   ");
    }

    if (buttonPressed(btn_done)) {
         finishSession();
    }
  }
}