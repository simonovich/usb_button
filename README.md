### USB Button

<table border="0">
  <tr>
    <td>
      <img src="https://github.com/simonovich/usb_button/blob/master/images/sch_rmt_button.png"></img>
    </td>
    <td>
USB Button - это USB-кнопка с подсветкой, которой можно управлять через Internet по MQTT протоколу.
Данный проект предоставляет возможность использовать несколько таких кнопок для распределения доступа к некоему общему ресурсу.

Кнопки умеют обмениваться друг с другом своим состоянием.
Допустим, есть 2 пользователя которые работают над одним и тем же проектом. Брать проект в работу можно только по очереди.
При помощи USB Button легко организовать такую очередь.

Кнопка работает как тумблер ON-OFF, т.е. физически у нее только 2 позиции. На основе анализа состояния кнопки световой индикатор может выдавать разные статусы:
1. Горит ровным светом - вы успешно овладели ресурсом.
2. Моргает - переходное состояние. Либо ресурс уже у вашего коллеги, либо он просит вас освободить его.
3. Подсветки нет - ресурс не на вашей стороне, либо вы не нажали кнопку.

Приступать к работе можно **только** если ваша кнопка в состоянии 1 (см. выше).
    </td>
  </tr>
</table>

#### Пример работы
Пользователи подключают по одной кнопке на своё рабочее место.
Перед тем как приступить к работе над проектом следует нажать свою кнопку.
Кнопка начнет мигать. Если через некоторое время кнопка зажглась - можно приступать к работе.
Продолжает мигать - проект на стороне вашего коллеги. Его кнопка тоже начнет мигать сигнализируя о входящем запросе от вас.
Он может завершить работу и принять ваш запрос - достаточно хлопнуть по своей кнопке.
В то же время вы можете отменить свой запрос и позволить коллеге продолжить работу над проектом. Для этого тоже достаточно одного нажатия кнопки. При этом она погаснет у вызывающего и загорится ровным светом на стороне вызываемого.

Коммуникация между кнопками построена через MQTT протокол. Путём небольших изменений в конфигурации можно управлять рассылкой управляющих команд на одно или несколько подобных устройств.
Можно расширить функционал кнопки, добавить новые команды и возможности. Что позволяет легко интегрировать это решение под свои задачи.

### Технические детали
Проект состоит 3 частей:
- аппаратная
- программная
- системная

<u>На аппаратном уровне это:</u>
- ATtiny85, Arduino Nano либо любой другой микроконтроллер подходящий под требования программы и ваших задач.
**Важно** наличие Serial-порта и пинов для подключения тактовой кнопки и/или светодиода.
- обычная тактовая кнопка + светодиод с обвязкой, либо готовая кнопка с управляемой подсветкой.
Отлично подходят "аркадные" кнопки.

<u>На программном уровне:</u>
- скетч, с использованием прерываний и таймеров. Программа отвечает за обработку сигналов из Serial-порта и событий кнопки.

<u>На системном уровне</u> это скрипт на bash, который интегрируется в систему как демон (сервис). Отвечает за прием/передачу данных между MQTT и Serial.
Там же осуществляется конфигурация проекта.

#### Особенности работы для ATtiny85

Для работы на микроконтроллере ATtiny85 необходимо [прошить ядро с поддержкой V-USB](https://github.com/ArminJo/micronucleus-firmware#recommended-configuration), либо приобрести готовый Digispark Attiny85.
Я использовал "голую" микросхему в DIP исполнении + hw-260 shield с обвязкой под неё.
Оригинальный скетч был упрощён, чтобы вписаться в ограничения по этому чипу.
Например, пришлось отказаться от использования прерывания на кнопке, т.к. единственное доступное для данного МК прерывание уже занято для работы с Serial.

### Управление сервисом
#### Установка
1. Необходимо выставить разрешения на порты
```bash
wget https://github.com/arduino/Arduino/blob/master/build/linux/dist/arduino-linux-setup.sh
```
```bash
chmod +x arduino-linux-setup.sh
```
```bash
./arduino-linux-setup.sh
```

2. Прописать настройки, в том числе учётку к своему MQTT брокеру

Список необходимых параметров
```bash
MQTT_SERVER='your_mqtt_broker' # mqtt.by"
MQTT_PORT=your_mqtt_port # 1883, 1884, 1885, 1886, 1887, 1888, 1889"
MQTT_USER='your_mqtt_login' # user login"
MQTT_PASS='your_mqtt_password' # user password"
MQTT_LOC_CLIENT_ID='your_local_id' # local client id"
MQTT_RMT_CLIENT_ID='your_remote_id' # remote client id"
MQTT_LOC_TOPIC='local_topic_name' # topic for your device"
MQTT_RMT_TOPIC='remote_topic_name' # topic for remote device"
MQTT_LOG='path_to_log_file' # log for incoming MQTT messages"
USB_PORT='your_port' # Serial port (by sample /dev/ttyUSB0 or /dev/ttyACM0)"
```
Создаем файл конфигурации и вписываем все параметры с нужными значениями
```bash
vi scripts/settings.sh
```

3. Запустить скрипт install.sh
```bash
./scripts/install.sh
```
#### Удаление
Просто запустите скрипт unistall.sh
```bash
./scripts/uninstall.sh
```
Если есть необходимость в полной очистке, то дополнительно удалите переменную окружения USB_BUTTON_HOME
```bash
vi ~/.profile
```
#### Посмотреть статус
```bash
systemctl --user list-dependencies default.target
```
или
```bash
systemctl --user status rmtbutton
```
#### Запустить / остановить / рестартовать
Подставляем соответственно start / stop или restart в команду:
```bash
systemctl --user <your_command> rmtbutton
```
#### Проверить логи
```bash
journalctl --user --user-unit rmtbutton
```
