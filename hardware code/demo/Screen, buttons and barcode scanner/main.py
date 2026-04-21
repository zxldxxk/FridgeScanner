from machine import Pin, I2C, UART
import ssd1306
import time

# ---- SETUP ----
i2c = I2C(0, scl=Pin(17), sda=Pin(16))
oled = ssd1306.SSD1306_I2C(128, 32, i2c)
uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))

# Buttons
btn_up = Pin(2, Pin.IN, Pin.PULL_UP)
btn_down = Pin(3, Pin.IN, Pin.PULL_UP)
btn_left = Pin(4, Pin.IN, Pin.PULL_UP)
btn_right = Pin(5, Pin.IN, Pin.PULL_UP)

# ---- STATE ----
state = "WAIT_SCAN"
barcode = ""

day, month, year = 1, 1, 2026
cursor = 0

# ---- HELPERS ----
def days_in_month(m, y):
    if m in (1,3,5,7,8,10,12):
        return 31
    elif m in (4,6,9,11):
        return 30
    elif m == 2:
        return 29 if (y%4==0 and y%100!=0) or (y%400==0) else 28

def button_pressed(btn):
    if btn.value() == 0:
        time.sleep_ms(150)
        return True
    return False

def draw_date():
    oled.fill(0)
    date_str = "{:02d}/{:02d}/{:04d}".format(day, month, year)
    x = (128 - len(date_str)*8) // 2
    y = 12

    oled.text(date_str, x, y)

    if cursor == 0:
        oled.hline(x, y+10, 16, 1)
    elif cursor == 1:
        oled.hline(x+24, y+10, 16, 1)
    elif cursor == 2:
        oled.hline(x+48, y+10, 32, 1)

    oled.show()

def save_to_file():
    with open("data.txt", "a") as f:
        f.write(f"{barcode},{day:02d}/{month:02d}/{year}\n")

# ---- MAIN LOOP ----
while True:

    # -------------------------
    # 1. WAIT FOR SCAN
    # -------------------------
    if state == "WAIT_SCAN":
        oled.fill(0)
        oled.text("Scan item...", 10, 10)
        oled.show()

        if uart.any():
            try:
                data = uart.read().decode().strip()
                if data:
                    barcode = data
                    print("Scanned:", barcode)

                    oled.fill(0)
                    oled.text("Scanned:", 0, 0)
                    oled.text(barcode[:16], 0, 12)
                    oled.show()

                    time.sleep(1)
                    state = "DATE_INPUT"
            except:
                pass

    # -------------------------
    # 2. DATE INPUT
    # -------------------------
    elif state == "DATE_INPUT":
        draw_date()

        if button_pressed(btn_up):
            if cursor == 0:

                day = (day % days_in_month(month, year)) + 1
            elif cursor == 1:

                month = (month % 12) + 1
            elif cursor == 2:

                year += 1

        if button_pressed(btn_down):
            if cursor == 0:
                day = day - 1 if day > 1 else days_in_month(month, year)
            elif cursor == 1:
                month = month - 1 if month > 1 else 12
            elif cursor == 2:
                year = max(2000, year - 1)

        if button_pressed(btn_right):
            cursor = (cursor + 1) % 3

        if button_pressed(btn_left):
            state = "SAVE"

    # -------------------------
    # 3. SAVE
    # -------------------------
    elif state == "SAVE":
        save_to_file()

        oled.fill(0)
        oled.text("Saved!", 30, 5)
        oled.text("{:02d}/{:02d}/{:04d}".format(day, month, year), 10, 18)
        oled.show()

        time.sleep(2)

        # reset for next loop
        day, month, year = 1, 1, 2026
        cursor = 0
        barcode = ""

        state = "WAIT_SCAN"

    time.sleep(0.05)