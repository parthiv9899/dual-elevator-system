@echo off
echo =========================================
echo   Dual Elevator System - Full System Test
echo =========================================
echo.

echo Step 1: Cleaning previous build artifacts...
if exist dual_sim del dual_sim
if exist dual_elevator_tb.vcd del dual_elevator_tb.vcd
echo    Clean complete
echo.

echo Step 2: Compiling Verilog source files...
iverilog -g2001 -o dual_sim -I src src/elevator_fsm.v src/scheduler.v src/dual_elevator_top.v tb/dual_elevator_tb.v
if %errorlevel% neq 0 (
    echo    Compilation failed
    exit /b 1
)
echo    Compilation successful
echo.

echo Step 3: Running simulation...
echo ----------------------------------------
vvp dual_sim
set SIM_EXIT_CODE=%errorlevel%
echo ----------------------------------------
echo.

if %SIM_EXIT_CODE% equ 0 (
    echo    Simulation completed successfully
    echo.
    echo Generated files:
    if exist dual_elevator_tb.vcd (
        echo   - dual_elevator_tb.vcd (waveform file)
        echo.
        echo To view waveforms, run:
        echo   gtkwave dual_elevator_tb.vcd
    )
) else (
    echo    Simulation failed with exit code %SIM_EXIT_CODE%
    exit /b 1
)

echo.
echo =========================================
echo   Test Complete
echo =========================================
