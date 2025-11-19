#!/usr/bin/env python3
"""
Performance Analyzer for Dual Elevator System
Calculates efficiency metrics, wait times, and energy consumption
"""

import subprocess
import re
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict

class PerformanceAnalyzer:
    def __init__(self):
        self.data = []
        self.metrics = {}

    def run_simulation(self):
        """Run simulation and collect data"""
        print("🔬 Running performance analysis...")
        result = subprocess.run(
            ['./simulation/run_scheduler.sh'],
            capture_output=True,
            text=True,
            timeout=30
        )
        return result.stdout + result.stderr

    def parse_data(self, output):
        """Parse simulation output"""
        pattern = r'Time=\s*(\d+).*?E1\[F=(\d+),S=(\d+)\].*?E2\[F=(\d+),S=(\d+)\]'

        for line in output.split('\n'):
            match = re.search(pattern, line)
            if match:
                self.data.append({
                    'time': int(match.group(1)) / 100000,  # Convert to seconds (0-10s range)
                    'e1_floor': int(match.group(2)),
                    'e1_state': int(match.group(3)),
                    'e2_floor': int(match.group(4)),
                    'e2_state': int(match.group(5))
                })

    def calculate_metrics(self):
        """Calculate performance metrics"""
        if not self.data:
            return

        # 1. Total movement distance
        e1_distance = sum(abs(self.data[i]['e1_floor'] - self.data[i-1]['e1_floor'])
                         for i in range(1, len(self.data)))
        e2_distance = sum(abs(self.data[i]['e2_floor'] - self.data[i-1]['e2_floor'])
                         for i in range(1, len(self.data)))

        # 2. Time in each state
        e1_states = [d['e1_state'] for d in self.data]
        e2_states = [d['e2_state'] for d in self.data]

        state_names = ['IDLE', 'DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN']

        e1_state_time = {name: e1_states.count(i) for i, name in enumerate(state_names)}
        e2_state_time = {name: e2_states.count(i) for i, name in enumerate(state_names)}

        # 3. Efficiency metrics
        total_time = self.data[-1]['time']
        e1_busy_time = sum(e1_state_time[s] for s in ['DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN'])
        e2_busy_time = sum(e2_state_time[s] for s in ['DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN'])

        e1_utilization = (e1_busy_time / len(self.data)) * 100 if self.data else 0
        e2_utilization = (e2_busy_time / len(self.data)) * 100 if self.data else 0

        # 4. Energy consumption (arbitrary units: 1 per floor moved)
        total_energy = e1_distance + e2_distance

        # 5. Average speed (floors per microsecond)
        e1_moving_samples = e1_state_time['MOVING_UP'] + e1_state_time['MOVING_DOWN']
        e2_moving_samples = e2_state_time['MOVING_UP'] + e2_state_time['MOVING_DOWN']

        e1_avg_speed = e1_distance / e1_moving_samples if e1_moving_samples else 0
        e2_avg_speed = e2_distance / e2_moving_samples if e2_moving_samples else 0

        self.metrics = {
            'e1_distance': e1_distance,
            'e2_distance': e2_distance,
            'total_distance': e1_distance + e2_distance,
            'e1_utilization': e1_utilization,
            'e2_utilization': e2_utilization,
            'avg_utilization': (e1_utilization + e2_utilization) / 2,
            'total_energy': total_energy,
            'e1_avg_speed': e1_avg_speed,
            'e2_avg_speed': e2_avg_speed,
            'total_time': total_time,
            'e1_state_time': e1_state_time,
            'e2_state_time': e2_state_time
        }

    def display_report(self):
        """Display comprehensive performance report"""
        print("\n" + "="*70)
        print("📊 PERFORMANCE ANALYSIS REPORT")
        print("="*70)

        m = self.metrics

        print(f"\n🏃 MOVEMENT STATISTICS:")
        print(f"  Elevator 1 Distance:  {m['e1_distance']:.1f} floors")
        print(f"  Elevator 2 Distance:  {m['e2_distance']:.1f} floors")
        print(f"  Total Distance:       {m['total_distance']:.1f} floors")
        print(f"  Average Speed (E1):   {m['e1_avg_speed']:.3f} floors/sample")
        print(f"  Average Speed (E2):   {m['e2_avg_speed']:.3f} floors/sample")

        print(f"\n⚡ EFFICIENCY METRICS:")
        print(f"  Elevator 1 Utilization: {m['e1_utilization']:.1f}%")
        print(f"  Elevator 2 Utilization: {m['e2_utilization']:.1f}%")
        print(f"  Average Utilization:    {m['avg_utilization']:.1f}%")

        # Rating system
        if m['avg_utilization'] > 80:
            rating = "🌟 EXCELLENT"
        elif m['avg_utilization'] > 60:
            rating = "✅ GOOD"
        elif m['avg_utilization'] > 40:
            rating = "⚠️  FAIR"
        else:
            rating = "❌ NEEDS IMPROVEMENT"

        print(f"  System Rating:          {rating}")

        print(f"\n💡 ENERGY CONSUMPTION:")
        print(f"  Total Energy Used:    {m['total_energy']:.1f} units")
        print(f"  Energy per Floor:     {m['total_energy']/m['total_distance']:.2f} units"
              if m['total_distance'] > 0 else "  N/A")

        print(f"\n⏱️  TIMING:")
        print(f"  Total Simulation Time: {m['total_time']:.2f} seconds")
        print(f"  Samples Collected:     {len(self.data)}")

        print(f"\n📈 STATE BREAKDOWN (Elevator 1):")
        for state, count in m['e1_state_time'].items():
            percentage = (count / len(self.data)) * 100
            bar = "█" * int(percentage / 3)
            print(f"  {state:12s}: {bar:20s} {percentage:5.1f}%")

        print(f"\n📈 STATE BREAKDOWN (Elevator 2):")
        for state, count in m['e2_state_time'].items():
            percentage = (count / len(self.data)) * 100
            bar = "█" * int(percentage / 3)
            print(f"  {state:12s}: {bar:20s} {percentage:5.1f}%")

        print("\n" + "="*70)

    def create_performance_plots(self):
        """Create detailed performance visualization"""
        m = self.metrics

        fig = plt.figure(figsize=(15, 10))
        fig.suptitle('Elevator System Performance Analysis', fontsize=16, fontweight='bold')

        # Plot 1: Utilization comparison
        ax1 = plt.subplot(2, 3, 1)
        elevators = ['Elevator 1', 'Elevator 2']
        utilizations = [m['e1_utilization'], m['e2_utilization']]
        colors = ['#3498db', '#e74c3c']
        bars = ax1.bar(elevators, utilizations, color=colors, alpha=0.7, edgecolor='black')
        ax1.set_ylabel('Utilization (%)', fontsize=11)
        ax1.set_title('Elevator Utilization', fontsize=12, fontweight='bold')
        ax1.set_ylim(0, 100)
        ax1.grid(axis='y', alpha=0.3)

        # Add value labels
        for bar in bars:
            height = bar.get_height()
            ax1.text(bar.get_x() + bar.get_width()/2., height,
                    f'{height:.1f}%', ha='center', va='bottom')

        # Plot 2: Distance traveled
        ax2 = plt.subplot(2, 3, 2)
        distances = [m['e1_distance'], m['e2_distance']]
        bars = ax2.bar(elevators, distances, color=colors, alpha=0.7, edgecolor='black')
        ax2.set_ylabel('Distance (floors)', fontsize=11)
        ax2.set_title('Total Distance Traveled', fontsize=12, fontweight='bold')
        ax2.grid(axis='y', alpha=0.3)

        for bar in bars:
            height = bar.get_height()
            ax2.text(bar.get_x() + bar.get_width()/2., height,
                    f'{height:.0f}', ha='center', va='bottom')

        # Plot 3: Energy efficiency
        ax3 = plt.subplot(2, 3, 3)
        energy_per_floor = [
            m['e1_distance'] / m['e1_distance'] if m['e1_distance'] > 0 else 0,
            m['e2_distance'] / m['e2_distance'] if m['e2_distance'] > 0 else 0
        ]
        ax3.bar(elevators, energy_per_floor, color=colors, alpha=0.7, edgecolor='black')
        ax3.set_ylabel('Energy per Floor', fontsize=11)
        ax3.set_title('Energy Efficiency', fontsize=12, fontweight='bold')
        ax3.grid(axis='y', alpha=0.3)

        # Plot 4: E1 State distribution (pie)
        ax4 = plt.subplot(2, 3, 4)
        e1_values = [m['e1_state_time'][s] for s in ['IDLE', 'DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN']]
        e1_labels = ['IDLE', 'DOOR\nOPEN', 'MOVING\nUP', 'MOVING\nDOWN']
        colors1 = ['#95a5a6', '#2ecc71', '#3498db', '#e74c3c']
        ax4.pie(e1_values, labels=e1_labels, autopct='%1.1f%%', colors=colors1,
               startangle=90, textprops={'fontsize': 9})
        ax4.set_title('Elevator 1 State Distribution', fontsize=12, fontweight='bold')

        # Plot 5: E2 State distribution (pie)
        ax5 = plt.subplot(2, 3, 5)
        e2_values = [m['e2_state_time'][s] for s in ['IDLE', 'DOOR_OPEN', 'MOVING_UP', 'MOVING_DOWN']]
        ax5.pie(e2_values, labels=e1_labels, autopct='%1.1f%%', colors=colors1,
               startangle=90, textprops={'fontsize': 9})
        ax5.set_title('Elevator 2 State Distribution', fontsize=12, fontweight='bold')

        # Plot 6: Overall metrics
        ax6 = plt.subplot(2, 3, 6)
        ax6.axis('off')
        metrics_text = f"""
        OVERALL PERFORMANCE

        Total Distance:     {m['total_distance']:.0f} floors
        Total Energy:       {m['total_energy']:.0f} units
        Avg Utilization:    {m['avg_utilization']:.1f}%

        Simulation Time:    {m['total_time']:.2f} seconds
        Data Points:        {len(self.data)}

        Efficiency Rating:
        """

        if m['avg_utilization'] > 80:
            metrics_text += "★★★★★ EXCELLENT"
        elif m['avg_utilization'] > 60:
            metrics_text += "★★★★☆ GOOD"
        elif m['avg_utilization'] > 40:
            metrics_text += "★★★☆☆ FAIR"
        else:
            metrics_text += "★★☆☆☆ NEEDS WORK"

        ax6.text(0.1, 0.5, metrics_text, fontsize=11, verticalalignment='center',
                fontfamily='monospace', bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.3))

        plt.tight_layout()

        # Save
        output_file = 'visualization/performance_analysis.png'
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"\n📊 Performance plot saved to: {output_file}")

        plt.show()

def main():
    print("╔" + "═"*68 + "╗")
    print("║" + " "*15 + "PERFORMANCE ANALYZER" + " "*33 + "║")
    print("╚" + "═"*68 + "╝\n")

    analyzer = PerformanceAnalyzer()

    output = analyzer.run_simulation()
    analyzer.parse_data(output)

    if not analyzer.data:
        print("❌ No data collected")
        return 1

    analyzer.calculate_metrics()
    analyzer.display_report()

    response = input("\n📊 Generate performance plots? (y/n): ").lower()
    if response == 'y':
        analyzer.create_performance_plots()

    print("\n✅ Analysis complete!")
    return 0

if __name__ == "__main__":
    import sys
    sys.exit(main())
