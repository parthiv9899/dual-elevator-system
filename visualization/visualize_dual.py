#!/usr/bin/env python3
"""
Dual Elevator System Visualizer
Shows both elevators side-by-side with matplotlib animations
"""

import subprocess
import re
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.animation import FuncAnimation
import numpy as np
import sys

class DualElevatorVisualizer:
    def __init__(self):
        self.times = []
        self.e1_floors = []
        self.e2_floors = []
        self.e1_states = []
        self.e2_states = []
        self.e1_doors = []
        self.e2_doors = []
        self.test_results = {"passed": 0, "failed": 0}

    def run_simulation(self):
        """Run the scheduler simulation (simpler than full dual)"""
        print("🚀 Running dual elevator simulation...")
        print("=" * 60)

        try:
            # Run scheduler test as it's more reliable
            result = subprocess.run(
                ['./simulation/run_scheduler.sh'],
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.stdout + result.stderr
        except Exception as e:
            print(f"❌ Error: {e}")
            return None

    def parse_output(self, output):
        """Parse scheduler output"""
        if not output:
            return False

        # Parse monitor output for dual elevators
        pattern = r'Time=\s*(\d+).*?E1\[F=(\d+),S=(\d+)\].*?E2\[F=(\d+),S=(\d+)\]'

        for line in output.split('\n'):
            match = re.search(pattern, line)
            if match:
                time = int(match.group(1)) / 100000  # Convert to seconds (0-10s range)
                e1_floor = int(match.group(2))
                e1_state = int(match.group(3))
                e2_floor = int(match.group(4))
                e2_state = int(match.group(5))

                self.times.append(time)
                self.e1_floors.append(e1_floor)
                self.e1_states.append(e1_state)
                self.e2_floors.append(e2_floor)
                self.e2_states.append(e2_state)

        # Parse test results
        pass_match = re.search(r'Tests Passed:\s*(\d+)', output)
        fail_match = re.search(r'Tests Failed:\s*(\d+)', output)

        if pass_match:
            self.test_results["passed"] = int(pass_match.group(1))
        if fail_match:
            self.test_results["failed"] = int(fail_match.group(1))

        return len(self.times) > 0

    def display_terminal_summary(self):
        """Display terminal summary"""
        print("\n" + "=" * 60)
        print("📊 DUAL ELEVATOR SIMULATION RESULTS")
        print("=" * 60)

        total = self.test_results["passed"] + self.test_results["failed"]
        pass_rate = (self.test_results["passed"] / total * 100) if total > 0 else 0

        print(f"\n✅ Tests Passed:  {self.test_results['passed']}")
        print(f"❌ Tests Failed:  {self.test_results['failed']}")
        print(f"📈 Pass Rate:     {pass_rate:.1f}%")

        if self.test_results["failed"] == 0:
            print("\n🎉 ALL TESTS PASSED! 🎉")
        else:
            print(f"\n⚠️  {self.test_results['failed']} test(s) need attention")

        if self.e1_floors and self.e2_floors:
            print("\n" + "=" * 60)
            print("🏢 ELEVATOR STATISTICS")
            print("=" * 60)

            print(f"\n🅰️  ELEVATOR 1:")
            print(f"  Floors visited: {sorted(set(self.e1_floors))}")
            print(f"  Final floor:    {self.e1_floors[-1]}")

            print(f"\n🅱️  ELEVATOR 2:")
            print(f"  Floors visited: {sorted(set(self.e2_floors))}")
            print(f"  Final floor:    {self.e2_floors[-1]}")

            print(f"\n⏱️  Total Duration: {self.times[-1]:.2f} seconds")

        print("\n" + "=" * 60)

    def create_terminal_view(self):
        """ASCII art showing both elevators"""
        print("\n🎬 DUAL ELEVATOR BUILDING VIEW")
        print("=" * 60)

        if not self.e1_floors or not self.e2_floors:
            return

        # Show last position
        e1_floor = self.e1_floors[-1]
        e2_floor = self.e2_floors[-1]
        e1_state = self.e1_states[-1]
        e2_state = self.e2_states[-1]

        state_symbols = {0: "IDLE", 1: "DOOR", 2: "↑", 3: "↓"}

        print("\n     ELEVATOR 1      ELEVATOR 2")
        print("     " + "─" * 12 + "    " + "─" * 12)

        for f in range(7, -1, -1):
            e1_display = "   [" + ("███" if f == e1_floor else "   ") + "]"
            e2_display = "[" + ("███" if f == e2_floor else "   ") + "]"

            line = f"Floor {f}: {e1_display}      {e2_display}"
            print(line)

        print("     " + "─" * 12 + "    " + "─" * 12)
        print(f"     {state_symbols[e1_state]:^12s}    {state_symbols[e2_state]:^12s}")

    def plot_dual_elevators(self):
        """Create matplotlib plot for both elevators"""
        if not self.e1_floors or not self.e2_floors:
            print("No data to plot")
            return

        fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(14, 10))
        fig.suptitle('Dual Elevator System Simulation', fontsize=16, fontweight='bold')

        # Plot 1: Both elevator positions
        ax1.plot(self.times, self.e1_floors, 'b-', linewidth=2, label='Elevator 1', marker='o', markersize=3)
        ax1.plot(self.times, self.e2_floors, 'r-', linewidth=2, label='Elevator 2', marker='s', markersize=3)
        ax1.set_xlabel('Time (seconds)', fontsize=12)
        ax1.set_ylabel('Floor Number', fontsize=12)
        ax1.set_title('Elevator Positions Over Time', fontsize=14)
        ax1.grid(True, alpha=0.3)
        ax1.set_yticks(range(8))
        ax1.legend(loc='upper right', fontsize=11)

        # Plot 2: Elevator 1 state
        state_colors_e1 = {0: 'gray', 1: 'green', 2: 'blue', 3: 'red'}
        colors_e1 = [state_colors_e1.get(s, 'black') for s in self.e1_states]
        ax2.scatter(self.times, self.e1_states, c=colors_e1, s=15, alpha=0.7)
        ax2.set_xlabel('Time (seconds)', fontsize=12)
        ax2.set_ylabel('State', fontsize=12)
        ax2.set_title('Elevator 1 State Over Time', fontsize=14)
        ax2.set_yticks([0, 1, 2, 3])
        ax2.set_yticklabels(['IDLE', 'DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN'])
        ax2.grid(True, alpha=0.3)

        # Plot 3: Elevator 2 state
        colors_e2 = [state_colors_e1.get(s, 'black') for s in self.e2_states]
        ax3.scatter(self.times, self.e2_states, c=colors_e2, s=15, alpha=0.7)
        ax3.set_xlabel('Time (seconds)', fontsize=12)
        ax3.set_ylabel('State', fontsize=12)
        ax3.set_title('Elevator 2 State Over Time', fontsize=14)
        ax3.set_yticks([0, 1, 2, 3])
        ax3.set_yticklabels(['IDLE', 'DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN'])
        ax3.grid(True, alpha=0.3)

        plt.tight_layout()

        # Save
        output_file = 'visualization/dual_elevator_simulation.png'
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"\n📊 Plot saved to: {output_file}")

        plt.show()

def main():
    print("╔" + "═" * 58 + "╗")
    print("║" + " " * 8 + "DUAL ELEVATOR SYSTEM VISUALIZER" + " " * 18 + "║")
    print("╚" + "═" * 58 + "╝")

    viz = DualElevatorVisualizer()

    output = viz.run_simulation()
    if not output or not viz.parse_output(output):
        print("❌ Failed to get simulation data")
        return 1

    viz.display_terminal_summary()

    response = input("\n🏢 Show building view? (y/n): ").lower()
    if response == 'y':
        viz.create_terminal_view()

    response = input("\n📊 Generate plots? (y/n): ").lower()
    if response == 'y':
        viz.plot_dual_elevators()

    print("\n✅ Done!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
