import RPi.GPIO as GPIO
from time import sleep

# Higher
notes = {
    # 'A': 880,
    'B': 988,
    'C': 1047,
    'D': 1175,
    'E': 1318,
    'F': 1397,
    'G': 1568,
    'A': 1760,
}

# Lower
notes = {
    # 'A': 220,
    'B': 247,
    'C': 262,
    'D': 294,
    'E': 330,
    'F': 349,
    'G': 392,
    'A': 440,
}

note_length = 2
crotchet = note_length * (1/4)
minim = note_length * (1/2)

tune = [
    ('C', crotchet),
    ('C', crotchet),
    ('G', crotchet),
    ('G', crotchet),
    ('A', crotchet),
    ('A', crotchet),
    ('G', minim),
    ('F', crotchet),
    ('F', crotchet),
    ('E', crotchet),
    ('E', crotchet),
    ('D', crotchet),
    ('D', crotchet),
    ('C', minim),
]

GPIO.setmode(GPIO.BCM)

speaker = 12
GPIO.setup(speaker, GPIO.OUT)

p = GPIO.PWM(speaker, 1000)

def play():
    try:
        for _ in range(3):
            for note, length in tune:
                p.ChangeFrequency(notes[note])
                p.start(50)
                sleep(length)
                p.stop()
                sleep(0.1)

            sleep(2)
    except KeyboardInterrupt:
        pass
    p.stop()
    GPIO.cleanup()