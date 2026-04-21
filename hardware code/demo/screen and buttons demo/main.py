from machine import Pin, I2C
import ssd1306
import time

# ---- OLED SETUP ----
i2c = I2C(0, scl=Pin(17), sda=Pin(16))
oled = ssd1306.SSD1306_I2C(128, 32, i2c)

# ---- BUTTONS ----
btn_up = Pin(2, Pin.IN, Pin.PULL_UP)
btn_down = Pin(3, Pin.IN, Pin.PULL_UP)
btn_left = Pin(4, Pin.IN, Pin.PULL_UP)
btn_right = Pin(5, Pin.IN, Pin.PULL_UP)

# ---- DATE STATE ----
day = 1
month = 1
year = 2026

cursor = 0  # 0=day, 1=month, 2=year
editing = True

# ---- HELPERS ----
def days_in_month(m, y):
    if m in (1,3,5,7,8,10,12):
        return 31
    elif m in (4,6,9,11):
        return 30
    elif m == 2:
        # leap year
        if (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0):
            return 29
        return 28

def draw():
    oled.fill(0)

    # Format date
    date_str = "{:02d}/{:02d}/{:04d}".format(day, month, year)

    # Centering
    x = (128 - len(date_str)*8) // 2
    y = 12

    oled.text(date_str, x, y)

    # Draw cursor underline
    if cursor == 0:
        oled.hline(x, y+10, 16, 1)
    elif cursor == 1:
        oled.hline(x+24, y+10, 16, 1)
    elif cursor == 2:
        oled.hline(x+48, y+10, 32, 1)

    oled.show()

def button_pressed(btn):
    if btn.value() == 0:
        time.sleep_ms(150)  # debounce
        return True
    return False

# ---- MAIN LOOP ----
while editing:
    draw()

    if button_pressed(btn_up):
        if cursor == 0:
            day += 1
            if day > days_in_month(month, year):
                day = 1
        elif cursor == 1:
            month += 1
            if month > 12:
                month = 1
            if day > days_in_month(month, year):
                day = days_in_month(month, year)
        elif cursor == 2:
            year += 1

    if button_pressed(btn_down):
        if cursor == 0:
            day -= 1
            if day < 1:
                day = days_in_month(month, year)
        elif cursor == 1:
            month -= 1
            if month < 1:
                month = 12
            if day > days_in_month(month, year):
                day = days_in_month(month, year)
        elif cursor == 2:
            year -= 1
            if year < 2000:
                year = 2000

    if button_pressed(btn_right):
        if cursor < 2:
            cursor += 1
        else:
            # confirm
            editing = False

    if button_pressed(btn_left):
        if cursor > 0:
            cursor -= 1
        else:
            # exit without saving
            editing = False

# ---- AFTER CONFIRM ----
oled.fill(0)
oled.text("Saved:", 30, 5)
oled.text("{:02d}/{:02d}/{:04d}".format(day, month, year), 10, 18)
oled.show()

