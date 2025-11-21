@echo off
echo =========================================
echo   Dual Elevator System - Single Elevator Test
echo =========================================
echo.

echo Step 1: Cleaning previous build artifacts...
if exist elevator_sim del elevator_sim
if exist elevator_tb.vcd del elevator_tb.vcd
echo    Clean complete
echo.

echo Step 2: Compiling Verilog source files...
iverilog -g2001 -o elevator_sim -I src src/elevator_fsm.v tb/elevator_tb.v
if %errorlevel% neq 0 (
    echo    Compilation failed
    exit /b 1
)
echo    Compilation successful
echo.

echo Step 3: Running simulation...
echo ----------------------------------------
vvp elevator_sim
set SIM_EXIT_CODE=%errorlevel%
echo ----------------------------------------
echo.

if %SIM_EXIT_CODE% equ 0 (
    echo    Simulation completed successfully
    echo.
    echo Generated files:
    if exist elevator_tb.vcd (
        echo   - elevator_tb.vcd - waveform file
        echo.
        echo To view waveforms, run:
        echo   gtkwave elevator_tb.vcd
    )
) else (
    echo    Simulation failed with exit code %SIM_EXIT_CODE%
    exit /b 1
)

echo.
echo =========================================
echo   Test Complete
echo =========================================
