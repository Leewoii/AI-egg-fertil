#!/usr/bin/python3
import serial
import tkinter as tk
from time import sleep
import subprocess
import threading
import RPi.GPIO as GPIO
import os
#new dependencies
import re
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import webbrowser
from getmac import get_mac_address

# The URL to open
URL = "https://automated-egg-incubator-2675c.web.app/AI_Hatchery"

# Open Chromium minimized
command = [
    "chromium",  # or "chromium-browser" depending on your system
    "--start-minimized",  # Starts Chromium minimized
    "https://www.example.com"  # You can replace this with the desired URL or leave it empty to open the browser with a blank page
]
subprocess.Popen(command, stdout=sys.stdout, stderr=sys.stderr)

# Global pause event
pause_event = threading.Event()

# Initialize Firebase app
cred = credentials.Certificate('./automated-egg-incubator-2675c-firebase-adminsdk-s47kc-41282ce576.json')
firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()

# Set up the serial connection (adjust the port and baud rate accordingly)
ser = serial.Serial('/dev/arduino0', 9600, timeout=1)  # Update with your actual serial port name

# Flush the output buffer
ser.flush()

# Set DTR (Data Terminal Ready) to True (set it HIGH)
ser.setDTR(True)

# Setup GPIO pins for Motor 1 and Motor 2
direction_pin_1 = 5
pulse_pin_1 = 6
en_pin_1 = 26  # Enable pin for Motor 1
cw_direction_1 = 0
ccw_direction_1 = 1

direction_pin_2 = 12
pulse_pin_2 = 16
en_pin_2 = 19  # Enable pin for Motor 2
ccw_direction_2 = 1
cw_direction_2 = 0

# Buttons setup
button1 = 27  # Mid Left
button2 = 17  # Mid Right
button3 = 13   # Top Front
button4 = 20   # Top Back

# Step sequences for each motor
Steps_Motor_1 = [600,4000,3700,3700,3700,3800,3800,3800]
Steps_Motor_2 = [3600,2300,2300,2250,2300,2200,2300,3300,2200,2400,2250,2300,2200,2200]

#Step Motor Logs
Motor_Step_1 = 0
Motor_Step_2 = 0
detected_labels = ""

Slot_names= [[0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            [0,"slot_1","slot_2","slot_3","slot_4","slot_5","slot_6","slot_7","slot_57","slot_58","slot_59","slot_60","slot_61","slot_62","slot_63"],
            [0,"slot_8","slot_9","slot_10","slot_11","slot_12","slot_13","slot_14","slot_64","slot_65","slot_66","slot_67","slot_68","slot_69","slot_70"],
            [0,"slot_15","slot_16","slot_17","slot_18","slot_19","slot_20","slot_21","slot_71","slot_72","slot_73","slot_74","slot_75","slot_76","slot_77"],
            [0,"slot_22","slot_23","slot_24","slot_25","slot_26","slot_27","slot_28","slot_78","slot_79","slot_80","slot_81","slot_82","slot_83","slot_84"],
            [0,"slot_29","slot_30","slot_31","slot_32","slot_33","slot_34","slot_35","slot_85","slot_86","slot_87","slot_88","slot_89","slot_90","slot_91"],
            [0,"slot_36","slot_37","slot_38","slot_39","slot_40","slot_41","slot_42","slot_92","slot_93","slot_94","slot_95","slot_96","slot_97","slot_98"],
            [0,"slot_43","slot_44","slot_45","slot_46","slot_47","slot_48","slot_49","slot_99","slot_100","slot_101","slot_102","slot_103","slot_104","slot_105"],
            [0,"slot_50","slot_51","slot_52","slot_53","slot_54","slot_55","slot_56","slot_106","slot_107","slot_108","slot_109","slot_110","slot_111","slot_112"]]

# Set up GPIO mode
GPIO.setmode(GPIO.BCM)
GPIO.setup(direction_pin_1, GPIO.OUT)
GPIO.setup(pulse_pin_1, GPIO.OUT)
GPIO.setup(en_pin_1, GPIO.OUT)  # Set up enable pin for Motor 1
GPIO.setup(direction_pin_2, GPIO.OUT)
GPIO.setup(pulse_pin_2, GPIO.OUT)
GPIO.setup(en_pin_2, GPIO.OUT)  # Set up enable pin for Motor 2

GPIO.setup(button1, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(button2, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(button3, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(button4, GPIO.IN, pull_up_down=GPIO.PUD_UP)

# Disable motors initially
GPIO.output(en_pin_1, GPIO.LOW)
GPIO.output(en_pin_2, GPIO.LOW)

# Function to spin the motor for a specified number of steps and direction
def spin_motor(direction_pin, pulse_pin, enable_pin, direction, steps):
    GPIO.output(enable_pin, GPIO.LOW)  # Enable motor
    GPIO.output(direction_pin, cw_direction_1 if direction == "CW" else ccw_direction_1)
    for _ in range(steps):
        GPIO.output(pulse_pin, GPIO.HIGH)
        sleep(0.0001)
        GPIO.output(pulse_pin, GPIO.LOW)
        sleep(0.0005)
    GPIO.output(enable_pin, GPIO.LOW)  # Disable motor after spin

# Function to handle motor 1 continuous spinning until a button is pressed
def continuous_spin_motor_1(direction):
    global Motor_Step_1
    print(Motor_Step_1)
    GPIO.output(en_pin_1, GPIO.HIGH)  # Enable Motor 1
    while GPIO.input(button3) == GPIO.HIGH if direction == "CW" else GPIO.input(button4) == GPIO.HIGH:
        spin_motor(direction_pin_1, pulse_pin_1, en_pin_1, direction, 100)  # 450 steps for each spin
        sleep(0.00005)
    GPIO.output(en_pin_1, GPIO.LOW)  # Disable Motor 1
    if direction == "CW":
        Motor_Step_1 = 8
    else:
        Motor_Step_1 = 0
    print(Motor_Step_1)

# Function to handle motor 2 continuous spinning until a button is pressed
def continuous_spin_motor_2(direction):
    global Motor_Step_2
    print(Motor_Step_2)
    if direction == "CCW":
        Motor_Step_2 = 15
    else:
        Motor_Step_2 = 0
    print(Motor_Step_2)
    GPIO.output(en_pin_2, GPIO.HIGH)  # Enable Motor 2 #motor 2 will move at 500 steps
    while GPIO.input(button2) == GPIO.HIGH if direction == "CCW" else GPIO.input(button1) == GPIO.HIGH:
        spin_motor(direction_pin_2, pulse_pin_2, en_pin_2, direction, 100)  # 450 steps for each spin
        sleep(0.00005)
    GPIO.output(en_pin_2, GPIO.LOW)  # Disable Motor 2

# Function to start Motor 1 sequence with steps in Steps_Motor_1 array
def start_motor_1_sequence():
    GPIO.output(en_pin_1, GPIO.HIGH)  # Enable Motor 1
    for steps in Steps_Motor_1:
        spin_motor(direction_pin_1, pulse_pin_1, en_pin_1, "CW", steps)
        sleep(1)  # Delay between steps
    #continuous_spin_motor_1("CCW")
    GPIO.output(en_pin_1, GPIO.LOW)  # Disable Motor 1

# Function to start Motor 2 sequence with steps in Steps_Motor_2 array
def start_motor_2_sequence():
    GPIO.output(en_pin_2, GPIO.HIGH)  # Enable Motor 2
    for steps in Steps_Motor_2:
        spin_motor(direction_pin_2, pulse_pin_2, en_pin_2, "CCW", steps)
        sleep(1)  # Delay between steps
    #continuous_spin_motor_2("CW")
    GPIO.output(en_pin_2, GPIO.LOW)  # Disable Motor 2

def go_home():
    # Final movement to home positions
    continuous_spin_motor_2("CW")  # Motor 2 full rotation home
    continuous_spin_motor_1("CCW")  # Motor 1 full reverse home
    GPIO.output(en_pin_1, GPIO.LOW)  # Disable Motor 1
    GPIO.output(en_pin_2, GPIO.LOW)  # Disable Motor 2

def Next_Steps(direction_pin, pulse_pin, enable_pin):
    global Motor_Step_1
    global Motor_Step_2
    if direction_pin == direction_pin_1:
        print(Motor_Step_1)
        if Motor_Step_1 <= 7:
            spin_motor(direction_pin, pulse_pin, enable_pin, "CW", Steps_Motor_1[Motor_Step_1])
            Motor_Step_1 += 1
        print(Motor_Step_1)
    elif direction_pin == direction_pin_2:
        print(Motor_Step_2)
        if Motor_Step_2 <= 15:
            spin_motor(direction_pin, pulse_pin, enable_pin, "CCW", Steps_Motor_2[Motor_Step_2])
            Motor_Step_2 += 1
            print(Motor_Step_2)

def Previous_Steps(direction_pin, pulse_pin, enable_pin):
    global Motor_Step_1
    global Motor_Step_2
    if direction_pin == direction_pin_1:
        print(Motor_Step_1)
        if 0 <= Motor_Step_1 <= 8:
            Motor_Step_1 -= 1
            spin_motor(direction_pin, pulse_pin, enable_pin, "CCW", Steps_Motor_1[Motor_Step_1])
    elif direction_pin == direction_pin_2:
        print(Motor_Step_2)
        if 0 <= Motor_Step_2 <= 14:
            Motor_Step_2 -= 1
            spin_motor(direction_pin, pulse_pin, enable_pin, "CW", Steps_Motor_2[Motor_Step_2])
            print(Motor_Step_2)

def upload_data(AI):
    print(AI)
    global Motor_Step_1
    global Motor_Step_2   
    global Slot_names
    print("-----------------------------------")
    print("Debugger")
    print(" ")
    print("AI = ", AI)
    print("Motor1 Pos = " + str(Motor_Step_1))
    print("Motor2 Pos = " + str(Motor_Step_2))
    print("Expected Slot = " + Slot_names[Motor_Step_1][Motor_Step_2])
    print("-----------------------------------")
    # Get the MAC address using getmac library
    mac_address = get_mac_address()  # Get MAC address using the getmac library
    mac_address = mac_address.upper()

    # Reference the document directly using the MAC address as the document ID
    incubator_doc_ref = db.collection('Detection').document(mac_address)
    incubator_doc = incubator_doc_ref.get()
    
    # Check if the document exists
    if incubator_doc.exists:
        print(f"Found incubator with MAC Address {mac_address}")
        incubator_data = incubator_doc.to_dict()
    else:
        print(f"No incubator document found for the MAC Address: {mac_address}")
        return  # Exit if no incubator is found

    # Process only if AI input contains the "slot"
    if "slot" in AI:
        datenow = datetime.today().strftime('%Y-%m-%d')  # Get the current date
        
        # Calculate the endDate by adding 18 days to the current date
        end_date = (datetime.today() + timedelta(days=18)).strftime('%Y-%m-%d')
        
        # Split AI input to get the command and output (slot number and status)
        command, output = AI.split(",")  # Example: "slot_1,fertile"
        
        # Define paths for the Firestore document
        slot_path = f'tray_1.{command}.status' if int(command.split('_')[1]) <= 56 else f'tray_2.{command}.status'
        start_date_path = f'tray_1.{command}.startDate' if int(command.split('_')[1]) <= 56 else f'tray_2.{command}.startDate'
        end_date_path = f'tray_1.{command}.endDate' if int(command.split('_')[1]) <= 56 else f'tray_2.{command}.endDate'

        # Get current values from Firestore (status, start date, and end date)
        current_status = incubator_data.get(slot_path, None)
        current_start_date = incubator_data.get(start_date_path, None)
        current_end_date = incubator_data.get(end_date_path, None)

        print(f"Current Status: {current_status}")
        print(f"Start Date: {current_start_date}")
        print(f"End Date: {current_end_date}")

        # Check if the output is "Fertile" or "Infertile" and update hasEgg to True
        if output.lower() in ["fertile", "infertile"]:
            # If startDate or endDate is missing or "None", update them
            if current_start_date in [None, "None", "N/A"]:
                # Update the status first
                incubator_doc_ref.update({slot_path: output})
                print(f"Updated status for {command}: {output}")
                
                # Update startDate if it's missing
                if current_start_date in [None, "None", "N/A"]:
                    incubator_doc_ref.update({start_date_path: datenow})

                # Update endDate if it's missing
                if current_end_date in [None, "None", "N/A"]:
                    incubator_doc_ref.update({end_date_path: end_date})

            else:
                # Only update the status if startDate and endDate are already available
                incubator_doc_ref.update({slot_path: output})
                print(f"Updated status for {command}: {output}")

            # Update the hasEgg field to True
            has_egg_path = f'tray_1.{command}.hasEgg' if int(command.split('_')[1]) <= 56 else f'tray_2.{command}.hasEgg'
            incubator_doc_ref.update({has_egg_path: True})
            print(f"Updated hasEgg for {command}: True")

        else:
            # If output is not "fertile" or "infertile", update status to "Unknown"
            incubator_doc_ref.update({slot_path: "Unknown"})
            print(f"Updated status for {command}: Unknown")
                
    elif "Upload" in AI:
        # This part handles the upload of other parameters
        try:
            # Extract data from AI input (e.g. "slot_1,23.5,50,21.2,45,water_level")
            command, tempUp, humUp, tempDown, humDown, WaterResivour = AI.split(",")

            # Convert input values to float for storage in Firestore
            tempUp = float(tempUp)
            humUp = float(humUp)
            tempDown = float(tempDown)
            humDown = float(humDown)
            WaterResivour = float(WaterResivour)

            # Update the Firestore document with the new values
            incubator_doc_ref.update({
                "Tray_Temperature": tempUp,
                "Tray_Humidity": humUp,
                "Hatchery_Temperature": tempDown,
                "Hatchery_Humidity": humDown,
                "WaterLevel": WaterResivour
            })

            print(f"Updated values: Tray Temperature: {tempUp}, Tray Humidity: {humUp}, Hatchery Temp: {tempDown}, Hatchery Humidity: {humDown}, Water Level: {WaterResivour}")
        
        except Exception as e:
            print(f"Error in Upload: {e}")

    print("Data updated successfully.")

def thread_function(name):
    while True:
        # Pause threads if pause_event is cleared
        pause_event.wait()  # If cleared, it will block here
        
        print(f"Thread {name} is running.")
        time.sleep(1)

# Function to manually pause threads
def pause_thread():
    print("Pausing all threads...")
    pause_event.clear()  # Clear the event to pause all threads

# Function to resume threads
def resume_threads():
    print("Resuming all threads...")
    pause_event.set()  # Set the event to resume all threads

def Step_Sequence(direction_pin_1, pulse_pin_1, enable_pin_1, direction_pin_2, pulse_pin_2, enable_pin_2):
    pause_thread()
    global Motor_Step_1
    global Motor_Step_2   
    global Slot_names
    # Send '1' via serial
    ser.write(b'1\n')
    print("Sent '1' via serial")
    sleep(1)

    # Wait for Gear1 to be LOW (reflected), then break and check Gear2
    while True:
        if ser.in_waiting > 0:  # Check if data is available on the serial port
            response = ser.readline().decode().strip()  # Read and decode the response

            # Split response into Command and Output
            if "Gear" in response:
                command, output = response.split(",")  # Split into command and output
                if output == "Done":  # Check if command is "Gear1"
                    command, output = response.split(",")
                    print(f"Command: {command}, Output: {output}")
                    break # Split into command and output

    print("DONE!")
    GPIO.output(en_pin_1, GPIO.HIGH)  # Enable Motor 1
    GPIO.output(en_pin_2, GPIO.HIGH)  # Enable Motor 2
    spin_motor(direction_pin_1, pulse_pin_1, en_pin_1, "CW", 500) #motor 1 will move at 500 steps
    spin_motor(direction_pin_2, pulse_pin_2, en_pin_2, "CCW", 500) #motor 2 will move at 500 steps
    continuous_spin_motor_2("CW")  # Motor 2 full rotation home
    continuous_spin_motor_1("CCW")  # Motor 1 full reverse home
    sleep(1)
    for _ in range(7):  # Repeat 8 times for the full cycle
        # Next step on Motor_Step_2 (1 step)
        Next_Steps(direction_pin_2, pulse_pin_2, enable_pin_2)

        # Next step on Motor_Step_1 (8 steps)
        for _ in range(8):
            print("Going")
            Next_Steps(direction_pin_1, pulse_pin_1, enable_pin_1)
            print("Reading")
            result = subprocess.run(['python', 'LiveCam.py'], capture_output=True, text=True)
            detected_labels = result.stdout.strip()
            print("result: " + detected_labels)
            upload_data(Slot_names[Motor_Step_1][Motor_Step_2] + "," + detected_labels)
            sleep(1)

        # Next step on Motor_Step_2 (1 step)
        Next_Steps(direction_pin_2, pulse_pin_2, enable_pin_2)

        # Previous step on Motor_Step_1 (8 steps)
        for _ in range(8):
            Previous_Steps(direction_pin_1, pulse_pin_1, enable_pin_1)
            result = subprocess.run(['python', 'LiveCam.py'], capture_output=True, text=True)
            detected_labels = result.stdout.strip()
            upload_data(Slot_names[Motor_Step_1][Motor_Step_2] + detected_labels)
            sleep(1)
    continuous_spin_motor_1("CCW")  # Motor 1 full reverse home
        # Repeat for the next cycle
    ser.write(b'2\n')
    resume_threads()
    continuous_spin_motor_2("CW")  # Motor 2 full rotation home
    continuous_spin_motor_1("CCW")  # Motor 1 full reverse home

def schedule_step_sequence():
    # Calculate the time remaining until the next 12 AM
    now = datetime.now()
    next_midnight = datetime.combine(now + timedelta(days=1), datetime.min.time())
    time_to_sleep = (next_midnight - now).total_seconds()

    print(f"Step_Sequence will run in {time_to_sleep} seconds (at 12 AM).")
    
    # Sleep until 12 AM, then run Step_Sequence
    threading.Timer(time_to_sleep, run_step_sequence_daily).start()

# Function that runs Step_Sequence and reschedules itself
def run_step_sequence_daily():
    Step_Sequence(direction_pin_1, pulse_pin_1, en_pin_1, direction_pin_2, pulse_pin_2, en_pin_2)
    schedule_step_sequence()  # Reschedule for the next 12 AM

def send_serial_command():
    """Function to send b'3\n' over the serial port."""
    ser.write(b'2\n')
    print("Sent b'3\\n' over serial port.")

    # Schedule this function again after 1 hour (3600 seconds)
    threading.Timer(3600, send_serial_command).start()

def read_and_process_serial():
    """Read data from the serial port, check for 'Upload', then process the CSV."""
    try:
        # Read line from serial port
        data = ser.readline().decode('utf-8').strip()
        print(f"Received: {data}")

        # Check if 'Upload' is in the CSV data
        if 'Upload' in data:
            # Split the CSV by commas
            values = data.split(',')
            
            # Assuming the format is: Upload,tempUp,humUp,tempDown,humDown,WaterResivourPercentage
            if len(values) == 6:
                Upload = values[0]
                print(f"Extracted Upload value: {Upload}")

                # Call the upload_data function with the extracted Upload value
                upload_data(Upload)
            else:
                print(f"Invalid CSV format, expected 6 values but got {len(values)}.")
        else:
            print("No 'Upload' in the received data.")
        
    except Exception as e:
        print(f"Error reading serial data: {e}")

    # Schedule the function to run again after 2 seconds
threading.Timer(2, read_and_process_serial).start()

# Start the first serial command schedule
send_serial_command()

# Start the scheduler
schedule_step_sequence()
    
# GUI setup
root = tk.Tk()
root.attributes("-topmost", True)
root.title("Motor Control UI")
root.geometry("800x480")
# Motor 1 Controls
motor1_frame = tk.LabelFrame(root, text="Motor 1 Controls", padx=10, pady=10)
motor1_frame.pack(fill="both", expand=True, padx=10, pady=10)

motor1_home_button = tk.Button(motor1_frame, text="Home", command=lambda: threading.Thread(target=continuous_spin_motor_1, args=("CCW",)).start())
motor1_home_button.pack(side=tk.LEFT, padx=5, pady=5)

motor1_cw_button = tk.Button(motor1_frame, text="Previous", command=lambda: threading.Thread(target=Previous_Steps, args=(direction_pin_1, pulse_pin_1, en_pin_1)).start())
motor1_cw_button.pack(side=tk.LEFT, padx=5, pady=5)

motor1_ccw_button = tk.Button(motor1_frame, text="Next", command=lambda: threading.Thread(target=Next_Steps, args=(direction_pin_1, pulse_pin_1, en_pin_1)).start())
motor1_ccw_button.pack(side=tk.LEFT, padx=5, pady=5)

motor1_start_button = tk.Button(motor1_frame, text="Start Motor 1", command=lambda: threading.Thread(target=start_motor_1_sequence).start())
motor1_start_button.pack(side=tk.LEFT, padx=5, pady=5)

motor1_last_button = tk.Button(motor1_frame, text="Last", command=lambda: threading.Thread(target=continuous_spin_motor_1, args=("CW",)).start())
motor1_last_button.pack(side=tk.LEFT, padx=5, pady=5)

# Motor 2 Controls
motor2_frame = tk.LabelFrame(root, text="Motor 2 Controls", padx=10, pady=10)
motor2_frame.pack(fill="both", expand=True, padx=10, pady=10)

motor2_home_button = tk.Button(motor2_frame, text="Home", command=lambda: threading.Thread(target=continuous_spin_motor_2, args=("CW",)).start())
motor2_home_button.pack(side=tk.LEFT, padx=5, pady=5)

motor2_cw_button = tk.Button(motor2_frame, text="Previous", command=lambda: threading.Thread(target=Previous_Steps, args=(direction_pin_2, pulse_pin_2, en_pin_2)).start())
motor2_cw_button.pack(side=tk.LEFT, padx=5, pady=5)

motor2_ccw_button = tk.Button(motor2_frame, text="Next", command=lambda: threading.Thread(target=Next_Steps, args=(direction_pin_2, pulse_pin_2, en_pin_2)).start())
motor2_ccw_button.pack(side=tk.LEFT, padx=5, pady=5)

motor2_start_button = tk.Button(motor2_frame, text="Start Motor 2", command=lambda: threading.Thread(target=start_motor_2_sequence).start())
motor2_start_button.pack(side=tk.LEFT, padx=5, pady=5)

motor2_last_button = tk.Button(motor2_frame, text="Last", command=lambda: threading.Thread(target=continuous_spin_motor_2, args=("CCW",)).start())
motor2_last_button.pack(side=tk.LEFT, padx=5, pady=5)

# Start all
start_frame = tk.LabelFrame(root, text="Start Controls", padx=10, pady=10)
start_frame.pack(fill="both", expand=True, padx=10, pady=10)

start_button = tk.Button(start_frame, text="Start Sequence", command=lambda: threading.Thread(target=Step_Sequence, args=(direction_pin_1, pulse_pin_1, en_pin_1, direction_pin_2, pulse_pin_2, en_pin_2)).start())
start_button.pack(side=tk.LEFT, padx=5, pady=5)

root.mainloop()


# Clean up GPIO settings when the application is closed
GPIO.cleanup()
