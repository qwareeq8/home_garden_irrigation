```markdown
# A Simple Automated Home Garden Irrigation System

This repository contains all the project files for the fully automated home garden irrigation system using the PIC16F877A microcontroller. The project was developed during Fall Semester 2019/2020 by Yusuf Qwareeq and Osama Abuhamdan at The University of Jordan. It uses an environment-aware approach with sensor inputs (simulated by potentiometers), rule-based decision algorithms, and user control via push-buttons. The system manages two garden zones and controls two pumps (represented by LEDs), displays sensor readings on an LCD, and even indicates frost conditions with a flashing red LED.

## Repository Structure

- **Source Code:** Contains the assembly code for the irrigation system.
- **Documents:** Contains the project handout, reports, schematics, and additional documentation.

```
home_garden_irrigation/
├── docs/
│   └── report.pdf
├── src/
│   └── main.asm
└── README.md
```

## Project Overview

The automated irrigation system is designed to manage a home garden with two distinct zones. Key features include:

- **Dual-Zone Control:** Each zone is monitored separately with its own set of sensors for soil pH and humidity.
- **Environmental Awareness:** The system reads analog inputs from five sensors (air temperature, two for soil pH, and two for soil humidity) via the PIC’s A/D converter.
- **Automatic & Manual Modes:** By default, the system operates automatically using a rule-based algorithm to decide pump operation. A manual mode is also available, allowing direct control of each pump.
- **LCD Display:** The LCD displays system mode (AUTO/MANUAL), sensor readings (temperature, humidity, and pH), and alerts.
- **Safety Features:** A frost alert is implemented; if the temperature falls below 5 °C, a red LED flashes every 1.5 seconds and both pumps are turned off. Additionally, sensor faults trigger alerts and override pump operation in automatic mode.

## System Description

Upon startup, the system initializes its registers, configures the A/D module, LCD, interrupts, and Timer0, and sets the default mode to automatic. In automatic mode, sensor readings are continuously processed and the irrigation algorithm decides pump activation based on soil humidity, pH levels, and temperature. Users can switch to manual mode via a push-button, enabling direct control of the pumps regardless of sensor readings. The system also allows users to switch the displayed zone on the LCD.

The project code is decomposed into several subroutines:
- **Initialization & Main Loop:** Sets up hardware and continuously checks the system mode.
- **Sensor Conversion:** Reads and scales analog sensor values for temperature, humidity, and pH.
- **Decision Algorithms:** Implements rule-based logic (using subroutines like RBA1 and RBA2) to control the pumps.
- **User Interface:** Manages LCD output and processes push-button inputs for mode and zone changes.
- **Interrupt Handling:** Includes routines for de-bouncing and managing periodic events like the frost alert LED flashing.

For further details, please refer to the project handout and report in the **docs/** folder.

## How to Use

1. **Hardware Setup:** Load the assembly code (`main.asm`) onto a PIC16F877A microcontroller. Ensure the sensors (potentiometers), push-buttons, LCD, and LEDs are connected as specified in the project handout.
2. **Simulation & Testing:** If available, use the test benches in the **test_benches/** folder for simulation using your preferred PIC simulator.
3. **Documentation:** Refer to the documents in the **docs/** folder for schematics, detailed flowcharts, and the final project report.

## Revision History

- **December 7th, 2019:** Last revised version of the assembly code.
- **Project Development:** Initial design, module testing, and final integration were carried out during Fall Semester 2019/2020 by Yusuf Qwareeq and Osama Abuhamdan.

## Contact

- **Yusuf Qwareeq:** qwareeq8@gmail.com
- **Osama Abuhamdan:** osamaabuhamdan@yahoo.com
