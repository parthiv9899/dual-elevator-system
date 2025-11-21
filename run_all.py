#!/usr/bin/env python3
"""
Master Launcher for Dual Elevator System
Interactive menu to run all visualization tools
"""

import subprocess
import sys
import os

class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'

def clear_screen():
    os.system('clear' if os.name != 'nt' else 'cls')

def print_banner():
    clear_screen()
    print(f"""
{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║        🏢  DUAL ELEVATOR SYSTEM - MASTER CONTROL PANEL  🏢          ║
║                                                                      ║
║                  Your Complete Visualization Suite                  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝{Colors.RESET}
""")

def print_menu():
    print(f"{Colors.BOLD}{Colors.YELLOW}Choose your visualization:{Colors.RESET}\n")
    print(f"{Colors.GREEN}1.{Colors.RESET} 📊  {Colors.BOLD}Simple Plots{Colors.RESET}       - Single elevator with matplotlib")
    print(f"{Colors.GREEN}2.{Colors.RESET} 🏢  {Colors.BOLD}Dual Elevator{Colors.RESET}     - Compare both elevators")
    print(f"{Colors.GREEN}3.{Colors.RESET} 🎬  {Colors.BOLD}Live Animation{Colors.RESET}    - Watch elevators move in real-time!")
    print(f"{Colors.GREEN}4.{Colors.RESET} ⚡  {Colors.BOLD}Performance{Colors.RESET}       - Detailed efficiency analysis")
    print(f"{Colors.GREEN}5.{Colors.RESET} 🌐  {Colors.BOLD}HTML Dashboard{Colors.RESET}    - Interactive web dashboard")
    print(f"{Colors.GREEN}6.{Colors.RESET} 🧪  {Colors.BOLD}Run All Tests{Colors.RESET}    - Execute test suite")
    print(f"{Colors.GREEN}7.{Colors.RESET} 📚  {Colors.BOLD}View Docs{Colors.RESET}        - Open documentation")
    print(f"{Colors.RED}0.{Colors.RESET} 🚪  {Colors.BOLD}Exit{Colors.RESET}\n")

def run_script(script_path, description):
    print(f"\n{Colors.CYAN}{'='*70}{Colors.RESET}")
    print(f"{Colors.BOLD}Running: {description}{Colors.RESET}")
    print(f"{Colors.CYAN}{'='*70}{Colors.RESET}\n")

    try:
        result = subprocess.run(['python3', script_path], check=False)
        return result.returncode
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}⚠️  Interrupted by user{Colors.RESET}")
        return 1
    except Exception as e:
        print(f"\n{Colors.RED}❌ Error: {e}{Colors.RESET}")
        return 1

def run_shell_script(script_path, description):
    print(f"\n{Colors.CYAN}{'='*70}{Colors.RESET}")
    print(f"{Colors.BOLD}Running: {description}{Colors.RESET}")
    print(f"{Colors.CYAN}{'='*70}{Colors.RESET}\n")

    if os.name == 'nt':
        script_path = script_path.replace('.sh', '.bat')

    try:
        # For .bat files, we might need to run with shell=True on Windows
        # For .sh files, the direct list is fine.
        is_windows_batch = os.name == 'nt' and script_path.endswith('.bat')
        
        # The script path needs to be adjusted for Windows
        if is_windows_batch:
            # subprocess.run on Windows prefers the command as a string with shell=True
            # Also, use os.path.join to create a system-agnostic path
            command = os.path.join(*script_path.split('/'))
            result = subprocess.run(command, check=False, shell=True)
        else:
            result = subprocess.run([script_path], check=False)
            
        return result.returncode
    except Exception as e:
        print(f"\n{Colors.RED}❌ Error: {e}{Colors.RESET}")
        return 1

def show_docs():
    docs = [
        ("QUICK_START.md", "Quick Start Guide"),
        ("PROJECT_CLEANUP_SUMMARY.md", "Complete Technical Report"),
        ("visualization/README.md", "Visualization Guide")
    ]

    print(f"\n{Colors.BOLD}{Colors.CYAN}📚 Available Documentation:{Colors.RESET}\n")
    for i, (file, desc) in enumerate(docs, 1):
        print(f"{Colors.GREEN}{i}.{Colors.RESET} {desc:30s} - {file}")

    print(f"\n{Colors.YELLOW}Tip: Use 'cat filename' to view in terminal{Colors.RESET}")
    print(f"{Colors.YELLOW}     Or open in your favorite text editor{Colors.RESET}\n")

def main():
    while True:
        print_banner()
        print_menu()

        try:
            choice = input(f"{Colors.BOLD}Enter your choice (0-7): {Colors.RESET}").strip()

            if choice == '0':
                print(f"\n{Colors.GREEN}👋 Thanks for using Dual Elevator System!{Colors.RESET}\n")
                break

            elif choice == '1':
                run_script('visualization/visualize_elevator.py',
                          '📊 Single Elevator Visualization')

            elif choice == '2':
                run_script('visualization/visualize_dual.py',
                          '🏢 Dual Elevator Comparison')

            elif choice == '3':
                run_script('visualization/live_animation.py',
                          '🎬 Live Real-Time Animation')

            elif choice == '4':
                run_script('visualization/performance_analyzer.py',
                          '⚡ Performance Analysis')

            elif choice == '5':
                run_script('visualization/generate_dashboard.py',
                          '🌐 HTML Dashboard Generator')

            elif choice == '6':
                print(f"\n{Colors.BOLD}{Colors.CYAN}🧪 Available Test Suites:{Colors.RESET}\n")
                print(f"{Colors.GREEN}a.{Colors.RESET} Single Elevator Test")
                print(f"{Colors.GREEN}b.{Colors.RESET} Scheduler Test")
                print(f"{Colors.GREEN}c.{Colors.RESET} All Tests\n")

                test_choice = input(f"{Colors.BOLD}Choose test (a/b/c): {Colors.RESET}").strip().lower()

                if test_choice == 'a':
                    run_shell_script('./simulation/run_sim.sh', 'Single Elevator Test')
                elif test_choice == 'b':
                    run_shell_script('./simulation/run_scheduler.sh', 'Scheduler Test')
                elif test_choice == 'c':
                    run_shell_script('./simulation/run_sim.sh', 'Single Elevator Test')
                    input(f"\n{Colors.YELLOW}Press ENTER to continue...{Colors.RESET}")
                    run_shell_script('./simulation/run_scheduler.sh', 'Scheduler Test')

            elif choice == '7':
                show_docs()

            else:
                print(f"\n{Colors.RED}❌ Invalid choice. Please enter 0-7.{Colors.RESET}")

            if choice in ['1', '2', '3', '4', '5', '6']:
                input(f"\n{Colors.GREEN}✅ Done! Press ENTER to continue...{Colors.RESET}")

        except KeyboardInterrupt:
            print(f"\n\n{Colors.GREEN}👋 Goodbye!{Colors.RESET}\n")
            break
        except Exception as e:
            print(f"\n{Colors.RED}❌ Error: {e}{Colors.RESET}")
            input(f"\n{Colors.YELLOW}Press ENTER to continue...{Colors.RESET}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
