#!/usr/bin/env python3
"""
Elevator Simulation Visualizer
Runs the Verilog simulation, parses output, and creates visual plots + terminal display
"""

import subprocess
import re
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.animation import FuncAnimation
import sys
from pathlib import Path

class ElevatorVisualizer:
    def __init__(self):
        self.times = []
        self.floors = []
        self.states = []
        self.door_status = []
        self.requests = []
        self.test_results = {"passed": 0, "failed": 0}

    def run_simulation(self):
        """Run the Verilog simulation and capture output"""
        print("🚀 Running elevator simulation...")
        print("=" * 60)

        try:
            result = subprocess.run(
                ['./simulation/run_sim.sh'],
                capture_output=True,
                text=True,
                timeout=30
            )

            return result.stdout + result.stderr

        except subprocess.TimeoutExpired:
            print("❌ Simulation timed out!")
            return None
        except Exception as e:
            print(f"❌ Error running simulation: {e}")
            return None

    def parse_output(self, output):
        """Parse simulation output to extract elevator data"""
        if not output:
            return False

        # Parse monitor output: Time, Floor, Requests, DoorOpen, State, etc.
        pattern = r'Time=\s*(\d+),\s+Floor=(\d+),.*?DoorOpen=(\d+).*?State=(\d+)'

        for line in output.split('\n'):
            match = re.search(pattern, line)
            if match:
                time = int(match.group(1)) / 100000  # Convert to seconds (1ps = 1e-12s, but simulation is in ps, divide by 100k for 0-10s range)
                floor = int(match.group(2))
                door = int(match.group(3))
                state = int(match.group(4))

                self.times.append(time)
                self.floors.append(floor)
                self.door_status.append(door)
                self.states.append(state)

        # Parse test results
        pass_match = re.search(r'Tests Passed:\s*(\d+)', output)
        fail_match = re.search(r'Tests Failed:\s*(\d+)', output)

        if pass_match:
            self.test_results["passed"] = int(pass_match.group(1))
        if fail_match:
            self.test_results["failed"] = int(fail_match.group(1))

        return len(self.times) > 0

    def display_terminal_summary(self):
        """Display a nice terminal summary"""
        print("\n" + "=" * 60)
        print("📊 SIMULATION RESULTS")
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

        print("\n" + "=" * 60)
        print("🏢 ELEVATOR JOURNEY SUMMARY")
        print("=" * 60)

        if self.floors:
            print(f"\n📍 Starting Floor:  {self.floors[0]}")
            print(f"📍 Ending Floor:    {self.floors[-1]}")
            print(f"🔢 Total Samples:   {len(self.floors)}")
            print(f"⏱️  Duration:        {self.times[-1]:.2f} seconds")

            # Count floor visits
            unique_floors = set(self.floors)
            print(f"🎯 Floors Visited:  {sorted(unique_floors)}")

            # Count state transitions
            state_names = {0: "IDLE", 1: "DOOR_OPEN", 2: "MOVING_UP", 3: "MOVING_DOWN"}
            state_counts = {}
            for state in self.states:
                name = state_names.get(state, "UNKNOWN")
                state_counts[name] = state_counts.get(name, 0) + 1

            print("\n📊 State Distribution:")
            for state_name, count in sorted(state_counts.items()):
                percentage = (count / len(self.states)) * 100
                bar = "█" * int(percentage / 2)
                print(f"  {state_name:12s}: {bar} {percentage:.1f}%")

        print("\n" + "=" * 60)

    def create_terminal_animation(self):
        """Create ASCII art animation of elevator movement"""
        print("\n🎬 ELEVATOR MOVEMENT VISUALIZATION")
        print("=" * 60)

        if not self.floors:
            print("No data to visualize")
            return

        # Sample every N points for animation
        sample_rate = max(1, len(self.floors) // 30)

        for i in range(0, len(self.floors), sample_rate):
            floor = self.floors[i]
            door = self.door_status[i]
            state = self.states[i]
            time = self.times[i]

            # Clear and draw building
            print("\n" * 2)
            print(f"⏱️  Time: {time:.2f} seconds")
            print("-" * 40)

            # Draw 8 floors
            for f in range(7, -1, -1):
                if f == floor:
                    if door == 1:
                        elevator = "[ 🚪 OPEN ]"
                    elif state == 2:  # MOVING_UP
                        elevator = "[   ↑    ]"
                    elif state == 3:  # MOVING_DOWN
                        elevator = "[   ↓    ]"
                    else:  # IDLE
                        elevator = "[  IDLE  ]"
                else:
                    elevator = "           "

                print(f"  Floor {f}: |{elevator}|")

            print("-" * 40)

            # State indicator
            state_name = {0: "IDLE", 1: "DOOR_OPEN", 2: "MOVING_UP", 3: "MOVING_DOWN"}
            print(f"State: {state_name.get(state, 'UNKNOWN')}")

    def plot_elevator_movement(self):
        """Create matplotlib visualization"""
        if not self.floors:
            print("No data to plot")
            return

        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
        fig.suptitle('Elevator System Simulation Results', fontsize=16, fontweight='bold')

        # Plot 1: Floor position over time
        ax1.plot(self.times, self.floors, 'b-', linewidth=2, label='Floor Position')

        # Highlight door open periods
        for i in range(len(self.times)):
            if self.door_status[i] == 1:
                ax1.axvspan(self.times[i], self.times[min(i+1, len(self.times)-1)],
                           alpha=0.3, color='green')

        ax1.set_xlabel('Time (seconds)', fontsize=12)
        ax1.set_ylabel('Floor Number', fontsize=12)
        ax1.set_title('Elevator Floor Position Over Time', fontsize=14)
        ax1.grid(True, alpha=0.3)
        ax1.set_yticks(range(8))
        ax1.legend()

        # Add door open legend
        green_patch = mpatches.Patch(color='green', alpha=0.3, label='Door Open')
        ax1.legend(handles=[green_patch], loc='upper right')

        # Plot 2: State over time
        state_colors = {0: 'gray', 1: 'green', 2: 'blue', 3: 'red'}
        colors = [state_colors[s] for s in self.states]

        ax2.scatter(self.times, self.states, c=colors, s=10, alpha=0.6)
        ax2.set_xlabel('Time (seconds)', fontsize=12)
        ax2.set_ylabel('State', fontsize=12)
        ax2.set_title('Elevator State Over Time', fontsize=14)
        ax2.set_yticks([0, 1, 2, 3])
        ax2.set_yticklabels(['IDLE', 'DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN'])
        ax2.grid(True, alpha=0.3)

        # Add state legend
        idle_patch = mpatches.Patch(color='gray', label='IDLE')
        door_patch = mpatches.Patch(color='green', label='DOOR_OPEN')
        up_patch = mpatches.Patch(color='blue', label='MOVING_UP')
        down_patch = mpatches.Patch(color='red', label='MOVING_DOWN')
        ax2.legend(handles=[idle_patch, door_patch, up_patch, down_patch],
                  loc='upper right')

        plt.tight_layout()

        # Save figure
        output_file = 'visualization/elevator_simulation.png'
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"\n📊 Plot saved to: {output_file}")

        # Show plot
        plt.show()

def main():
    print("╔" + "═" * 58 + "╗")
    print("║" + " " * 10 + "DUAL ELEVATOR SYSTEM VISUALIZER" + " " * 16 + "║")
    print("╚" + "═" * 58 + "╝")

    viz = ElevatorVisualizer()

    # Run simulation
    output = viz.run_simulation()

    if output is None:
        print("❌ Failed to run simulation")
        return 1

    # Parse results
    if not viz.parse_output(output):
        print("❌ Failed to parse simulation output")
        return 1

    # Display results
    viz.display_terminal_summary()

    # Show ASCII animation
    response = input("\n🎬 Show ASCII animation? (y/n): ").lower()
    if response == 'y':
        viz.create_terminal_animation()

    # Create plots
    response = input("\n📊 Generate matplotlib plots? (y/n): ").lower()
    if response == 'y':
        viz.plot_elevator_movement()

    print("\n✅ Visualization complete!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
