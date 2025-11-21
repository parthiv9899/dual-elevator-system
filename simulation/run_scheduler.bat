@echo off
echo =========================================
echo   Dual Elevator System - Scheduler Test
echo =========================================
echo.

echo Step 1: Cleaning previous build artifacts...
if exist scheduler_sim del scheduler_sim
if exist scheduler_tb.vcd del scheduler_tb.vcd
echo    Clean complete
echo.

echo Step 2: Compiling Verilog source files...
iverilog -g2001 -o scheduler_sim -I src src/scheduler.v tb/scheduler_tb.v
if %errorlevel% neq 0 (
    echo    Compilation failed
    exit /b 1
)
echo    Compilation successful
echo.

echo Step 3: Running simulation...
echo ----------------------------------------
vvp scheduler_sim
set SIM_EXIT_CODE=%errorlevel%
echo ----------------------------------------
echo.

if %SIM_EXIT_CODE% equ 0 (
    echo    Simulation completed successfully
    echo.
    echo Generated files:
    if exist scheduler_tb.vcd (
        echo   - scheduler_tb.vcd (waveform file)
        echo.
        echo To view waveforms, run:
        echo   gtkwave scheduler_tb.vcd
    )
) else (
    echo    Simulation failed with exit code %SIM_EXIT_CODE%
    exit /b 1
)

echo.
echo =========================================
echo   Test Complete
echo =========================================
