/*
  All pins can be used as Digital I/O
  Pin 0 → I2C SDA, PWM (LED on Model B)
  Pin 1 → PWM (LED on Model A)
  Pin 2 → I2C SCK, Analog In
  Pin 3 → Analog In (also used for USB+ when USB is in use)
  Pin 4 → PWM, Analog (also used for USB- when USB is in use)
  Pin 5 → Analog In
*/
#include <DigiCDC.h>

/*------------------------------------------------*/
#define BTN_PIN PB2           // Button pin: PB2 - Pin 7
#define LED_PIN PB0           // PB0 - Pin 5

boolean state = false;
boolean rmtBtn = false, lcBtn = false;

/*------------------------------------------------*/
void setup() {
  pinMode(LED_PIN, OUTPUT);
  pinMode(BTN_PIN, INPUT_PULLUP);
  SerialUSB.begin();
}
/*------------------------------------------------*/
void loop() {
  bool btn_state = !digitalRead(BTN_PIN);
  if (btn_state) {
    button_press();
  }
  button_tick();
  serial_tick();
  commands_tick();
}
/*------------------------------------------------*/
// button_press() handler
void button_press() {
  static unsigned long millis_prev;
  if (millis() - 100 > millis_prev && digitalRead(BTN_PIN) == LOW) state = !state;
  millis_prev = millis();
}

void button_tick() {
  // Переключатель включен
  if (state && !lcBtn) {
    lcBtn = true;
    SerialUSB.println(lcBtn);
  }
  // Переключатель выключен
  if (!state && lcBtn) {
    // гасим подсветку
    lcBtn = false;
    digitalWrite(LED_PIN, lcBtn);
    SerialUSB.println(lcBtn);
  }
}

void serial_tick() {
  if (SerialUSB.available()) {
    // получить состояние удаленного переключателя из порта
    char input = SerialUSB.read();
    SerialUSB.delay(2);
    //rmtBtn = strData.equals("1\n");
    if (input == '1')
      rmtBtn = true;
    else if (input == '0')
      rmtBtn = false;
  }
}

void commands_tick() {
  // если удал переключатель выкл
  if (lcBtn && !rmtBtn) {
    digitalWrite(LED_PIN, HIGH);
  }
  // если удал переключатель вкл
  if (lcBtn && rmtBtn) {
    blink_led();
  }
}

void blink_led() {
  unsigned long currentMillis = millis();
  static unsigned int ledState = LOW;
  static unsigned long previousMillis;

  //проверяем не прошел ли нужный интервал, если прошел то
  if (currentMillis - previousMillis > 100) {
    // сохраняем время последнего переключения
    previousMillis = currentMillis;

    // устанавливаем состояния выхода, чтобы включить или выключить светодиод
    digitalWrite(LED_PIN, ledState = !ledState);
  }
}
/*------------------------------------------------*/
