# growbot
Environmental monitoring web app for gardens, greenhouses, and fish tanks. Using a
Raspberry Pi and drivers for Bosch I2C sensors, Atlas Scientific I2C sensors and
peristaltic dosing pumps, and PWM controlled fans, a garden, greenhouse, or fish
tank can be monitored and controlled from any web-capable device.

This project is in the early stages of development. The hardware drivers for the
Bosch BMP280/BME280 environmental sensor, Atlas Scientific devices, and sensors
supported by lm-sensors are mostly complete. The web-based user interface is
currently the main development focus, and currently has limited useability (output
of sensor data is the only feature currently supported).

## To do
* Drivers
    - [ ] Add PWM controller for fans and other PWM controlled devices.
    - [ ] Update other drivers to depend on same library as the PWM controller.
    - [X] Add missing functionality to the AtlasScientfic driver.
        * Support for dosing pumps, temperature, pH, electrical conductivity,
          oxygen reduction potential, and dissolved oxygen sensors are mostly
          complete. Other devices may have only limited functionality.
    - [ ] Add a soil moisture driver.
        * [Vegetronix VH400](https://www.vegetronix.com/Products/VH400/) is one
          hardware option.
        * [Here](https://www.instructables.com/Soil-Moisture-Sensor-Raspberry-Pi/)
          is another option.
        * [Here](https://www.adafruit.com/product/4026) is one more option.
    - [ ] Add a driver for using a webcam to produce still and time-lapse style
          video of the garden.
* User Interface
    - [ ] Add configuration user interface with authentication.
    - [ ] Create a theme and make the UI nice to look at.
    - [ ] Use websockets to update data display. Alternatively, auto-refresh the
          page periodicaly.
* General
    - [ ] Add unit conversion.
    - [ ] Add support for responding to events (e.g., increase fan speed if air
      temperature gets too high).
    - [X] Rework device command queue to be more responsive.
    - [X] Fix the shutdown sequence.
* Documentation
    - [ ] Document config.json.
    - [ ] Add installation instructions.
