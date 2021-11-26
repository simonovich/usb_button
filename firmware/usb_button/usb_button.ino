/*------------------------------------------------*/
const byte button = 2;
const byte led = 3;

volatile boolean state = false; // состояние светодиода, false - ВЫКЛ, true - ВКЛ
boolean rmtBtn = false, lcBtn = false;

/*------------------------------------------------*/
void setup() {
  Serial.begin(9600);
  Serial.setTimeout(100);
  pinMode(button, INPUT_PULLUP); // установка направления работы порта для кнопки как вход
  pinMode(led, OUTPUT); // установка направления работы порта для светодиода как выход
  attachInterrupt (0, button_press, LOW); // установка прерывания №0 (цифровой вывод 2) по изменению сигнала с низкого уровня (0 В) на высокий уровень (5 В), т.е. по переднему фронту сигнала с кнопки.
  //при появлении на порте высокого уровня (5 В) сработает прерывание и запустится обработчик прерывания - функция button_press
}
/*------------------------------------------------*/
void loop() {
  button_tick();
  serial_tick();
  commands_tick();
}
/*------------------------------------------------*/
void button_press () {
  static unsigned long millis_prev;
  if (millis() - 100 > millis_prev) state = !state; // инвертируем состояние светодиода (false - ВЫКЛ, true - ВКЛ) + защита от дребезга контактов
  millis_prev = millis();
}

void button_tick(){
  // Переключатель включен
  if (state && !lcBtn) {
    lcBtn = true;
    Serial.println(lcBtn);
  }
  // Переключатель выключен
  if (!state && lcBtn) {
    // гасим подсветку
    lcBtn = false;
    digitalWrite(led, lcBtn);
    Serial.println(lcBtn);
  }
}

void serial_tick(){
  // получить состояние удаленного переключателя из порта
  if (Serial.available() > 0) rmtBtn = Serial.readString().equals("1\n");
}

void commands_tick(){
  // если удал переключатель выкл
  if (lcBtn && !rmtBtn) {
    digitalWrite(led, HIGH);
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
    digitalWrite(led, ledState = !ledState);
  }
}
/*------------------------------------------------*/
