# growbot
Environmental monitoring web app for gardens, greenhouses, and fish tanks. Using
a Raspberry Pi and drivers for Bosch I2C sensors, Atlas Scientific I2C sensors
and peristaltic pumps, and PWM controlled fans, a garden, greenhouse, or fish tank
can be monitored and controlled from any web-capable device.

This project is in the early stages of development. The hardware drivers for the
Bosch BMP280/BME280 environmental sensor, and Atlas Scientific devices, and
sensors supported by lm-sensors are mostly complete. The web-based user interface
is currently the main development focus, and currently has limited useability
(output of sensor data is the only feature currently supported). Additional
hardware drivers will be developed as needed (a PWM fan driver will soon be in the
works).
