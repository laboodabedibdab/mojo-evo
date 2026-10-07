# Artificial Life & Cellular Evolution Engine (Mojo)

A high-performance, low-level artificial life simulation engine written in **Mojo**, engineered from scratch to explore digital evolution, genetic programming, and ultra-fast cellular automata dynamics.

## What it does
* **Cellular Grid Simulation:** Manages up to 40,000 intelligent agents simultaneously on a high-speed $256 \times 256$ grid.
* **Genomic Architecture:** Each agent operates on a custom instruction set (genomes stored via `SIMD`) handling vital actions: movement, photosynthesis, combat, resource scavenging, division, communication, and conditional jumps.
* **Evolutionary Mechanics:** Implements pseudo-random bitwise mutations (`randomize`) to drive natural selection and generational adaptation.
* **Hardware-Level Optimization:** Leverages Mojo’s `UnsafePointer`, custom vectorization (`SIMD`), and strict type structures to bypass standard interpreted overhead and push performance to the metal.

---
> ### 🧊 **PROJECT STATUS: THIS PET PROJECT IS CURRENTLY ON HOLD** 🧊
---
