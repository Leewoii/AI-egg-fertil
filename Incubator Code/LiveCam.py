import cv2
from ultralytics import YOLO
import time
import subprocess

# Load the YOLOv8 model
model = YOLO("best2.pt")

# Boolean variable to control whether the GUI should be shown
show_gui = True  # True = show GUI, False = no GUI

# Function to set the camera focus using v4l2-ctl
def set_focus(value):
    try:
        subprocess.call(["sudo", "v4l2-ctl", "-d", "/dev/video0", "--set-ctrl", "focus_automatic_continuous=0"])
        subprocess.call(["sudo", "v4l2-ctl", "-d", "/dev/video0", "--set-ctrl", "auto_exposure=1"])
        subprocess.call(["sudo", "v4l2-ctl", "-d", "/dev/video0", "--set-ctrl", f"focus_absolute={value}"])
        subprocess.call(["sudo", "v4l2-ctl", "-d", "/dev/video0", "--set-ctrl", "exposure_time_absolute=150"])
    except Exception as e:
        print(f"Error setting focus: {e}")

# Function to perform object detection
def detect_objects(frame, center_box):
    results = model(frame, verbose=False)  # Perform inference with the YOLOv8 model without verbose output
    detections = results[0].boxes  # Get the detected boxes

    detected_labels = []  # To store detected labels
    for box in detections:
        conf = box.conf[0]  # Confidence score

        # Filter objects with confidence >= 0.50
        if conf >= 0.50:
            x1, y1, x2, y2 = map(int, box.xyxy[0])  # Bounding box coordinates
            label = model.names[int(box.cls[0])]  # Class label

            # Calculate center of the detected object
            center_x, center_y = (x1 + x2) // 2, (y1 + y2) // 2

            # Check if center of object is within the center box
            if center_box[0] <= center_x <= center_box[2] and center_box[1] <= center_y <= center_box[3]:
                detected_labels.append(label)  # Add label if inside the box
                
                # Draw bounding box and label only if GUI is enabled
                if show_gui:
                    color = (0, 255, 0)  # Green color for bounding boxes
                    text = f"{label} {conf:.2f}"
                    cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
                    cv2.putText(frame, text, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

    return frame, detected_labels

# Main function to run AI detection with or without GUI
def main():
    cap = cv2.VideoCapture(0)  # Open the webcam
    
    # Set the resolution to 640x480
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    if not cap.isOpened():
        print("Error: Could not open camera.")
        return

    set_focus(1021)

    # Define the center detection box (blue rectangle)
    frame_width, frame_height = 640, 480
    box_margin = 300  # Half of the box size
    center_box = (
        frame_width // 2 - box_margin,
        frame_height // 2 - box_margin,
        frame_width // 2 + box_margin,
        frame_height // 2 + box_margin
    )

    start_time = time.time()
    detection_history = []  # Store detected labels over time
    detection_interval = 10  # Interval to verify object detection in seconds

    while True:
        ret, frame = cap.read()  # Capture the frame
        if not ret:
            break

        # Draw the blue box on the frame
        if show_gui:
            cv2.rectangle(frame, (center_box[0], center_box[1]), (center_box[2], center_box[3]), (255, 0, 0), 2)

        # Run object detection
        frame, detected_labels = detect_objects(frame, center_box)

        # Append detected labels to the history
        if detected_labels:
            detection_history.append(detected_labels)

        # Print detected labels every 2 seconds, if the same label appears consistently
        if time.time() - start_time >= detection_interval:
            if detection_history:
                # Get the most common label in the history
                flat_labels = [label for sublist in detection_history for label in sublist]
                most_common_label = max(set(flat_labels), key=flat_labels.count)
                
                # Print the result based on the most common label
                if most_common_label in ["fertile", "infertile"]:
                    print(most_common_label)
                else:
                    print(none)
            
            # Exit after printing the result
            #break

        # Show GUI only if enabled
        if show_gui:
            cv2.imshow("Live Camera Feed", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break  # Exit if 'q' is pressed
        else:
            time.sleep(0.1)  # Add a short delay to avoid high CPU usage

    # Release resources
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
