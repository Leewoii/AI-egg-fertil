# AI Model
The AI model used for real-time egg fertility detection is based on YOLOv8n, achieving an accuracy of 0.98 (where 1 is 100% accuracy). We trained the model using a custom dataset captured during the construction of the incubator.
![[Loss per epoch.png]]

![[Precision-Confidence Curve.png]]

![[Accuracy per epoch.png]]

![[F1-Confidence Curve.png]]
# Hardware Setup
Raspberry Pi
Model: Raspberry Pi 4B (8GB)
OS: Raspberry Pi OS Bookworm
Web Camera: Used for real-time fertility detection.
Microphone: Any microphone connected to the Raspberry Pi (we use the DM-717 microphone).

![[Incubator Wiring 3.jpg]]

![[Incubator Wiring 1.jpg]]

![[Incubator Wiring 2.jpg]]

# Arduino Components
IR Speed Sensor
Ultrasonic Sensor (for water monitoring with the humidifier)
5V LED Light
DHT22 (for temperature and humidity monitoring)
Humidifier Fans
DC Motor (for tilting the trays)

# Camera Control
The Raspberry Pi controls the position of the camera using a Nema 17 stepper motor and a switch that places the camera at either the home or end position of the incubator, similar to how 3D printers work.

![[Incubator Camera & tray 2.jpg]]

![[Incubator Camera & tray 3.jpg]]

![[Incubator Camera & tray 4.jpg]]

![[Incubator Camera & tray 5.jpg]]

![[Incubator Camera & tray 6.jpg]]

![[Incubator Camera & tray.jpg]]

# Microphone and Hatching Detection
The system uses a DM-717 microphone to detect if the eggs have hatched. The microphone's sound data is processed and trained using TensorFlow to distinguish between background noises and chickling sounds. This allows the system to accurately detect when the eggs have hatched and trigger mobile notifications.

![[Microphone.jpg]]

![[Microphone & Hatching Area 2 .jpg]]

![[Microphone & Hatching Area.jpg]]
# Mobile Notifications
Notifications are sent to your mobile device using Firebase whenever a key event occurs, such as an egg hatching or a change in incubator conditions.