# 📊 Elevator System Visualization

Python-based visualization tools for the dual elevator system - **NO VCD FILES NEEDED!**

## 🚀 Quick Start

### Prerequisites
```bash
pip install matplotlib numpy
```

### Run Single Elevator Visualization
```bash
python3 visualization/visualize_elevator.py
```

**What you'll get:**
- ✅ Test results in terminal
- 📊 State distribution statistics
- 🎬 ASCII animation of elevator movement
- 📈 Matplotlib plots showing floor position and states over time

### Run Dual Elevator Visualization
```bash
python3 visualization/visualize_dual.py
```

**What you'll get:**
- ✅ Test results for both elevators
- 🏢 Side-by-side building view
- 📈 Matplotlib plots comparing both elevators

---

## 📖 How It Works

1. **Runs the Verilog simulation** automatically
2. **Parses the output** to extract elevator data
3. **Creates visualizations**:
   - Terminal-based ASCII animations
   - Matplotlib plots
   - Statistical summaries
4. **Displays results** in a user-friendly format

---

## 🎨 Sample Output

### Terminal Output:
```
╔══════════════════════════════════════════════════════════╗
║          DUAL ELEVATOR SYSTEM VISUALIZER                  ║
╚══════════════════════════════════════════════════════════╝

🚀 Running elevator simulation...
============================================================

============================================================
📊 SIMULATION RESULTS
============================================================

✅ Tests Passed:  13
❌ Tests Failed:  0
📈 Pass Rate:     100.0%

🎉 ALL TESTS PASSED! 🎉

============================================================
🏢 ELEVATOR JOURNEY SUMMARY
============================================================

📍 Starting Floor:  0
📍 Ending Floor:    7
🔢 Total Samples:   85
⏱️  Duration:        835.00 μs
🎯 Floors Visited:  [0, 1, 2, 3, 4, 5, 6, 7]

📊 State Distribution:
  DOOR_OPEN   : ████████ 15.3%
  IDLE        : ███ 5.9%
  MOVING_DOWN : ███████████ 22.4%
  MOVING_UP   : ████████████████████████ 56.5%
```

### ASCII Animation:
```
⏱️  Time: 495.0 μs

Floor 7: |           |
Floor 6: |           |
Floor 5: |           |
Floor 4: |           |
Floor 3: |   [   ↓    ]   |  ← Elevator here
Floor 2: |           |
Floor 1: |           |
Floor 0: |           |
----------------------------------------
State: MOVING_DOWN
```

### Matplotlib Plots:
- **Floor Position Graph**: Shows elevator movement over time
- **State Diagram**: Color-coded state transitions
- **Saved as PNG** in the visualization folder

---

## 🎯 Features

### ✨ What Makes This Better Than VCD:
- ✅ **No GTKWave needed** - Everything in terminal and matplotlib
- ✅ **Interactive** - Choose what to display
- ✅ **Statistical analysis** - Automatic calculations
- ✅ **Professional plots** - Publication-ready figures
- ✅ **ASCII animations** - See elevator move in terminal
- ✅ **Easy to understand** - No waveform expertise required

### 📊 Visualization Types:

1. **Terminal Statistics**
   - Test pass/fail counts
   - State distribution
   - Floor visit patterns
   - Duration metrics

2. **ASCII Building View**
   - Real-time elevator position
   - Door status
   - Movement direction
   - Both elevators side-by-side (dual mode)

3. **Matplotlib Plots**
   - Floor position over time (line graph)
   - State transitions (scatter plot with colors)
   - Dual elevator comparison
   - Saved as high-resolution PNG

---

## 🔧 Customization

Edit the Python scripts to:
- Change plot colors and styles
- Adjust animation speed
- Modify output format
- Add custom metrics
- Export data to CSV

---

## 📝 Files

- `visualize_elevator.py` - Single elevator visualization
- `visualize_dual.py` - Dual elevator visualization
- `*.png` - Generated plots (auto-saved)

---

## 🎓 Usage Tips

1. **First time?** Start with `visualize_elevator.py` - it's simpler
2. **Want animations?** Answer 'y' when prompted
3. **Need plots?** Answer 'y' for matplotlib display
4. **Batch mode?** Modify scripts to skip prompts
5. **Custom analysis?** Scripts are easy to modify!

---

Enjoy visualizing your elevator system! 🎉
