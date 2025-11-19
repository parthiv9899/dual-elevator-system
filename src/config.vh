// src/config.vh
// This file contains global configurations and parameters for the elevator system.
// Using a central config file makes the project easier to manage and scale.

// Defines the total number of floors in the building.
// You can change this value to scale the elevator system.
`define NUM_FLOORS 8

// Calculates the number of bits required to represent the floor numbers.
// For N floors, we need clog2(N) bits. For example, 8 floors need 3 bits (0-7).
`define FLOOR_BITS $clog2(`NUM_FLOORS)
