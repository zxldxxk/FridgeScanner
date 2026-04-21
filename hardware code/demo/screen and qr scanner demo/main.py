from machine import UART, Pin, I2C
import ssd1306
import time

# UART0 på Pico
uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))

# Initialize I2C
i2c = I2C(0, scl=Pin(17), sda=Pin(16), freq=400000)


# Scan for devices (optional)
print(i2c.scan())

# Initialize display (128x32)
oled = ssd1306.SSD1306_I2C(128, 32, i2c)

print("scanning")

while True:
    if uart.any():
        data = uart.read()
        oled.fill(0)
        try:
            print("Scannat:", data.decode().strip())
            oled.text(data.decode().strip(), 0, 10)
            oled.show()
        except:
            print("Raw data:", data)
    time.sleep(0.1)


