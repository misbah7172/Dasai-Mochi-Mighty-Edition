#include "display_manager.h"
#include "config.h"

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1

bool DisplayManager::begin() {
    _display = new Adafruit_SSD1306(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
    
    if (!_display->begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("SSD1306 allocation failed");
        return false;
    }
    
    _display->clearDisplay();
    _display->setTextColor(SSD1306_WHITE);
    _display->display();
    
    Serial.println("OLED display initialized");
    return true;
}

void DisplayManager::end() {
    if (_display) {
        _display->clearDisplay();
        _display->display();
        delete _display;
        _display = nullptr;
    }
}

void DisplayManager::update() {
    if (!_display) return;
    
    unsigned long now = millis();
    
    switch (_currentState) {
        case DisplayState::TIME_VIEW:
            _drawTime();
            break;
        case DisplayState::REMINDER_LIST:
            _drawReminders();
            break;
        case DisplayState::FACE_VIEW:
            _drawFace(_currentMood);
            break;
        case DisplayState::MESSAGE_VIEW:
            // Message view is static, no update needed
            break;
        case DisplayState::BATTERY_LOW:
            // Animate battery low warning
            if (now % 1000 < 500) {
                _display->invertDisplay(true);
            } else {
                _display->invertDisplay(false);
            }
            break;
    }
    
    _drawStatusBar();
    _display->display();
}

void DisplayManager::clear() {
    if (_display) {
        _display->clearDisplay();
        _display->display();
    }
}

void DisplayManager::setBrightness(uint8_t brightness) {
    if (_display) {
        _display->ssd1306_command(SSD1306_SETCONTRAST);
        _display->ssd1306_command(brightness);
    }
}

void DisplayManager::showTimeView() {
    _currentState = DisplayState::TIME_VIEW;
    _lastUpdate = millis();
}

void DisplayManager::showReminderList() {
    _currentState = DisplayState::REMINDER_LIST;
    _lastUpdate = millis();
}

void DisplayManager::showMessage(const String& title, const String& message) {
    if (!_display) return;
    
    _display->clearDisplay();
    
    // Draw title
    _display->setTextSize(1);
    _display->setCursor(0, 0);
    _display->println(title);
    
    // Draw line
    _display->drawLine(0, 10, SCREEN_WIDTH, 10, SSD1306_WHITE);
    
    // Draw message
    _display->setTextSize(1);
    _display->setCursor(0, 15);
    
    // Word wrap the message
    String words[20];
    int wordCount = 0;
    int start = 0;
    
    for (int i = 0; i <= message.length(); i++) {
        if (i == message.length() || message[i] == ' ') {
            if (i > start) {
                words[wordCount++] = message.substring(start, i);
                if (wordCount >= 20) break;
            }
            start = i + 1;
        }
    }
    
    String line = "";
    int y = 15;
    
    for (int i = 0; i < wordCount; i++) {
        if (line.length() + words[i].length() + 1 > 21) { // 21 chars per line
            _display->setCursor(0, y);
            _display->println(line);
            y += 8;
            line = words[i];
            if (y > 56) break; // Don't go past bottom
        } else {
            if (line.length() > 0) line += " ";
            line += words[i];
        }
    }
    
    if (line.length() > 0 && y <= 56) {
        _display->setCursor(0, y);
        _display->println(line);
    }
    
    _currentState = DisplayState::MESSAGE_VIEW;
    _display->display();
}

void DisplayManager::showFace(MochiMood mood) {
    _currentMood = mood;
    _currentState = DisplayState::FACE_VIEW;
    _lastUpdate = millis();
}

void DisplayManager::showBatteryLow(int percent) {
    if (!_display) return;
    
    _display->clearDisplay();
    
    // Draw battery icon
    _display->drawRect(40, 20, 40, 20, SSD1306_WHITE);
    _display->fillRect(80, 25, 4, 10, SSD1306_WHITE);
    
    // Draw percentage
    _display->setTextSize(2);
    _display->setCursor(30, 45);
    _display->printf("%d%%", percent);
    
    // Draw warning text
    _display->setTextSize(1);
    drawCenteredText("LOW BATTERY!", 8, 1);
    
    _currentState = DisplayState::BATTERY_LOW;
    _display->display();
}

void DisplayManager::setMood(MochiMood mood) {
    _currentMood = mood;
}

MochiMood DisplayManager::getMood() const {
    return _currentMood;
}

void DisplayManager::drawCenteredText(const String& text, int y, int textSize) {
    if (!_display) return;
    
    _display->setTextSize(textSize);
    int16_t x1, y1;
    uint16_t w, h;
    _display->getTextBounds(text.c_str(), 0, 0, &x1, &y1, &w, &h);
    
    int x = (SCREEN_WIDTH - w) / 2;
    _display->setCursor(x, y);
    _display->print(text);
}

void DisplayManager::drawScrollingText(const String& text, int y, int textSize) {
    if (!_display) return;
    
    _display->setTextSize(textSize);
    
    if (text != _scrollText) {
        _scrollText = text;
        _scrollOffset = 0;
    }
    
    int textWidth = text.length() * 6 * textSize; // Approximate character width
    
    if (textWidth > SCREEN_WIDTH) {
        // Text needs scrolling
        _display->setCursor(-_scrollOffset, y);
        _display->print(text);
        
        _scrollOffset += 1;
        if (_scrollOffset > textWidth + SCREEN_WIDTH) {
            _scrollOffset = 0;
        }
    } else {
        // Text fits on screen
        drawCenteredText(text, y, textSize);
    }
}

void DisplayManager::showBLEStatus(bool connected) {
    // Will be drawn in status bar
}

void DisplayManager::showBatteryPercent(int percent) {
    // Will be drawn in status bar
}

void DisplayManager::showWiFiStatus(bool connected) {
    // Will be drawn in status bar
}

void DisplayManager::_drawFace(MochiMood mood) {
    if (!_display) return;
    
    _display->clearDisplay();
    
    // Draw face outline (circle)
    _display->drawCircle(64, 32, 25, SSD1306_WHITE);
    
    switch (mood) {
        case MochiMood::HAPPY:
            _drawHappyFace();
            break;
        case MochiMood::SLEEPY:
            _drawSleepyFace();
            break;
        case MochiMood::SAD:
            _drawSadFace();
            break;
        case MochiMood::CRAZY:
            _drawCrazyFace();
            break;
        default:
            _drawNormalFace();
            break;
    }
}

void DisplayManager::_drawHappyFace() {
    // Eyes
    _display->fillCircle(55, 25, 3, SSD1306_WHITE);
    _display->fillCircle(73, 25, 3, SSD1306_WHITE);
    
    // Smile
    _display->drawCircle(64, 28, 10, SSD1306_WHITE);
    _display->fillRect(54, 28, 20, 10, SSD1306_BLACK);
}

void DisplayManager::_drawSleepyFace() {
    // Closed eyes (lines)
    _display->drawLine(52, 25, 58, 25, SSD1306_WHITE);
    _display->drawLine(70, 25, 76, 25, SSD1306_WHITE);
    
    // Small mouth
    _display->drawCircle(64, 35, 3, SSD1306_WHITE);
}

void DisplayManager::_drawSadFace() {
    // Eyes
    _display->fillCircle(55, 25, 3, SSD1306_WHITE);
    _display->fillCircle(73, 25, 3, SSD1306_WHITE);
    
    // Frown
    _display->drawCircle(64, 45, 10, SSD1306_WHITE);
    _display->fillRect(54, 35, 20, 10, SSD1306_BLACK);
}

void DisplayManager::_drawCrazyFace() {
    // Different sized eyes
    _display->fillCircle(55, 25, 4, SSD1306_WHITE);
    _display->fillCircle(73, 25, 2, SSD1306_WHITE);
    
    // Wavy mouth
    for (int x = 54; x < 74; x += 2) {
        int y = 35 + (sin(x * 0.5) * 3);
        _display->drawPixel(x, y, SSD1306_WHITE);
    }
}

void DisplayManager::_drawNormalFace() {
    // Eyes
    _display->fillCircle(55, 25, 2, SSD1306_WHITE);
    _display->fillCircle(73, 25, 2, SSD1306_WHITE);
    
    // Neutral mouth
    _display->drawLine(59, 35, 69, 35, SSD1306_WHITE);
}

void DisplayManager::_drawTime() {
    if (!_display) return;
    
    _display->clearDisplay();
    
    // This would get actual time from TimeManager
    // For now, show placeholder
    _display->setTextSize(2);
    drawCenteredText("12:34", 20, 2);
    
    _display->setTextSize(1);
    drawCenteredText("Monday, Oct 12", 40, 1);
}

void DisplayManager::_drawReminders() {
    if (!_display) return;
    
    _display->clearDisplay();
    
    _display->setTextSize(1);
    _display->setCursor(0, 0);
    _display->println("Reminders:");
    
    // This would get actual reminders from TimeManager
    // For now, show placeholder
    _display->setCursor(0, 10);
    _display->println("- Take medicine");
    _display->setCursor(0, 20);
    _display->println("- Meeting at 3PM");
    _display->setCursor(0, 30);
    _display->println("- Call mom");
}

void DisplayManager::_drawStatusBar() {
    if (!_display) return;
    
    // Draw line at top
    _display->drawLine(0, 0, SCREEN_WIDTH, 0, SSD1306_WHITE);
    
    // BLE status (top right)
    if (true) { // Would check actual BLE status
        _display->fillCircle(120, 3, 2, SSD1306_WHITE);
    }
    
    // Battery percentage (top left) 
    _display->setTextSize(1);
    _display->setCursor(0, 0);
    _display->print("85%"); // Would get actual battery level
}