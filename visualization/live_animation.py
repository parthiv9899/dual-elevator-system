#!/usr/bin/env python3
"""
Real-Time Live Animation of Elevator Movement
Watch the elevators move in real-time with fancy terminal graphics!
"""

import subprocess
import re
import time
import sys
import os

# Colors and emojis
class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    BLACK = '\033[30m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BG_BLACK = '\033[40m'
    BG_RED = '\033[41m'
    BG_GREEN = '\033[42m'
    BG_YELLOW = '\033[43m'
    BG_BLUE = '\033[44m'
    BG_MAGENTA = '\033[45m'
    BG_CYAN = '\033[46m'
    BG_WHITE = '\033[47m'

def clear_screen():
    """Clear terminal screen"""
    os.system('clear' if os.name != 'nt' else 'cls')

def draw_building(e1_floor, e1_state, e2_floor, e2_state, time_ms, requests_pending):
    """Draw fancy building with both elevators"""
    clear_screen()

    # Header
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.YELLOW}        🏢  DUAL ELEVATOR SYSTEM - LIVE ANIMATION  🏢{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.RESET}\n")

    # Time display
    print(f"{Colors.WHITE}⏱️  Time: {Colors.GREEN}{time_ms:.2f} μs{Colors.RESET}     " +
          f"{Colors.WHITE}📊 Pending Requests: {Colors.YELLOW}{requests_pending}{Colors.RESET}\n")

    # State descriptions
    state_names = {
        0: f"{Colors.WHITE}💤 IDLE{Colors.RESET}",
        1: f"{Colors.GREEN}🚪 DOOR OPEN{Colors.RESET}",
        2: f"{Colors.BLUE}⬆️  MOVING UP{Colors.RESET}",
        3: f"{Colors.RED}⬇️  MOVING DOWN{Colors.RESET}"
    }

    # Building structure
    print(f"    {Colors.BOLD}ELEVATOR 1{Colors.RESET}             {Colors.BOLD}ELEVATOR 2{Colors.RESET}")
    print(f"    {state_names.get(e1_state, 'UNKNOWN'):30s}  {state_names.get(e2_state, 'UNKNOWN')}")
    print(f"    {'─'*15}            {'─'*15}")

    # Draw floors (8 floors)
    for floor in range(7, -1, -1):
        # Elevator 1 representation
        if floor == e1_floor:
            if e1_state == 1:  # Door open
                e1_car = f"{Colors.BG_GREEN}{Colors.WHITE}【 🚪 OPEN 】{Colors.RESET}"
            elif e1_state == 2:  # Moving up
                e1_car = f"{Colors.BG_BLUE}{Colors.YELLOW}【  ⬆️⬆️⬆️  】{Colors.RESET}"
            elif e1_state == 3:  # Moving down
                e1_car = f"{Colors.BG_RED}{Colors.YELLOW}【  ⬇️⬇️⬇️  】{Colors.RESET}"
            else:  # Idle
                e1_car = f"{Colors.BG_WHITE}{Colors.BLUE}【 IDLE 💤 】{Colors.RESET}"
        else:
            e1_car = "             "

        # Elevator 2 representation
        if floor == e2_floor:
            if e2_state == 1:  # Door open
                e2_car = f"{Colors.BG_GREEN}{Colors.WHITE}【 🚪 OPEN 】{Colors.RESET}"
            elif e2_state == 2:  # Moving up
                e2_car = f"{Colors.BG_BLUE}{Colors.YELLOW}【  ⬆️⬆️⬆️  】{Colors.RESET}"
            elif e2_state == 3:  # Moving down
                e2_car = f"{Colors.BG_RED}{Colors.YELLOW}【  ⬇️⬇️⬇️  】{Colors.RESET}"
            else:  # Idle
                e2_car = f"{Colors.BG_WHITE}{Colors.BLUE}【 IDLE 💤 】{Colors.RESET}"
        else:
            e2_car = "             "

        # Floor display
        floor_color = Colors.YELLOW if (floor == e1_floor or floor == e2_floor) else Colors.WHITE
        print(f"  {floor_color}Floor {floor}{Colors.RESET}: |{e1_car}|      |{e2_car}|")

    print(f"    {'─'*15}            {'─'*15}\n")

def run_live_animation():
    """Run simulation and show live animation"""
    print(f"{Colors.BOLD}{Colors.GREEN}🚀 Starting live elevator simulation...{Colors.RESET}")
    print(f"{Colors.CYAN}   Compiling and running Verilog simulation...{Colors.RESET}\n")
    time.sleep(1)

    # Run simulation in background and parse output
    try:
        # Check if script exists
        if not os.path.exists('./simulation/run_visualization.sh'):
            print(f"{Colors.RED}❌ Error: simulation script not found!{Colors.RESET}")
            print(f"{Colors.YELLOW}   Please run from project root directory.{Colors.RESET}")
            return

        # Use visualization testbench for realistic elevator movement
        process = subprocess.Popen(
            ['./simulation/run_visualization.sh'],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )

        pattern = r'Time=\s*(\d+).*?E1\[F=(\d+),S=(\d+)\].*?E2\[F=(\d+),S=(\d+)\]'

        e1_floor, e1_state = 0, 0
        e2_floor, e2_state = 0, 0
        frame_count = 0
        matched_lines = 0

        for line in process.stdout:
            # Print compilation messages
            if "error" in line.lower() or "Error" in line:
                print(f"{Colors.RED}{line.strip()}{Colors.RESET}")
                continue

            match = re.search(pattern, line)
            if match:
                matched_lines += 1
                try:
                    time_val = int(match.group(1)) / 1000.0  # Convert nanoseconds to microseconds
                    e1_floor = int(match.group(2))
                    e1_state = int(match.group(3))
                    e2_floor = int(match.group(4))
                    e2_state = int(match.group(5))

                    # Update display every N frames for smooth animation
                    frame_count += 1
                    if frame_count % 5 == 0:  # Update every 5 frames for smoother viewing
                        draw_building(e1_floor, e1_state, e2_floor, e2_state, time_val, 0)
                        time.sleep(0.1)  # Slow down for human viewing
                except (ValueError, IndexError) as e:
                    # Skip malformed lines
                    continue

        process.wait()

        # Final display
        if matched_lines > 0:
            print(f"\n{Colors.BOLD}{Colors.GREEN}✅ Simulation Complete! ({matched_lines} frames processed){Colors.RESET}")
        else:
            print(f"\n{Colors.YELLOW}⚠️  No simulation data captured. Check if simulation ran correctly.{Colors.RESET}")

        print(f"\n{Colors.CYAN}Press ENTER to continue...{Colors.RESET}")
        input()

    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}⚠️  Animation stopped by user{Colors.RESET}")
    except FileNotFoundError:
        print(f"\n{Colors.RED}❌ Error: Required tools not found (iverilog/vvp){Colors.RESET}")
        print(f"{Colors.YELLOW}   Please install Icarus Verilog.{Colors.RESET}")
    except Exception as e:
        print(f"\n{Colors.RED}❌ Error: {e}{Colors.RESET}")
        import traceback
        print(f"{Colors.YELLOW}{traceback.format_exc()}{Colors.RESET}")

def show_welcome():
    """Show welcome screen"""
    clear_screen()
    print(f"""
{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║        🎬  LIVE ELEVATOR ANIMATION  🎬                          ║
║                                                                  ║
║     Watch your elevators move in REAL-TIME with colors!         ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝{Colors.RESET}

{Colors.YELLOW}Features:{Colors.RESET}
  🎨 Colorful real-time display
  🏢 ASCII art building view
  ⏱️  Live timing information
  🚪 Door open/close animation
  ⬆️⬇️  Movement indicators

{Colors.GREEN}Press ENTER to start... (Ctrl+C to stop){Colors.RESET}
""")
    input()

def main():
    show_welcome()
    run_live_animation()
    return 0

if __name__ == "__main__":
    sys.exit(main())
