# Synchronous FIFO — SystemVerilog Functional Verification

An educational RTL and verification project for an 8-bit-wide, 8-entry synchronous FIFO. The verification environment uses **plain SystemVerilog classes (no UVM)** and tests data ordering, occupancy flags, overflow/underflow handling, simultaneous read/write, and randomized request sequences.

## Architecture

| Component | Purpose |
| --- | --- |
| `rtl/sync_fifo.sv` | Parameterized FIFO RTL with read/write pointers and occupancy counter |
| `tb/fifo_if.sv` | FIFO interface signals |
| `tb/fifo_tb_pkg.sv` | Transaction, generator, driver, monitor, scoreboard and functional coverage |
| `tb/fifo_properties.sv` | Concurrent SVA occupancy and flag consistency checks |
| `tb/tb_top.sv` | Clock/reset, DUT wiring, environment construction, test control |
| `sim/run_questa.do` | Questa/ModelSim compilation and simulation commands |
| `docs/verification_plan.md` | Feature-by-feature verification checklist |

## FIFO behavior

- Active-low asynchronous reset clears pointers and occupancy, but not storage bits.
- `rd_data` is **first-word fall-through**, meaningful when `empty=0` before the rising clock edge.
- A read on an empty FIFO is rejected; a write on a full FIFO is rejected **unless a simultaneous valid read frees a slot**.
- With simultaneous read/write at full occupancy, both transactions are accepted; the oldest element is returned and replaced by the newly written value.
- At empty occupancy with simultaneous requests, only the write is accepted.
- No separate `valid`/`ready` outputs; acceptance is derived from input requests and pre-edge `full`/`empty`.

## Verification strategy

The generator supplies directed fill/overflow/drain/underflow tests followed by constrained-random traffic. The driver updates the DUT at falling clock edges, and the monitor samples requests and combinational outputs at rising edges. The scoreboard independently models expected FIFO contents using a SystemVerilog queue and compares read data and status flags. Functional coverage includes request combinations crossed with occupancy buckets. Assertions independently check occupancy and full/empty flag consistency.

## Running (Questa/ModelSim)

From the repository root:

```sh
vsim -do sim/run_questa.do
```

Or open Questa/ModelSim and execute:

```tcl
do sim/run_questa.do
```

**Tool requirement:** A simulator supporting SystemVerilog classes, typed mailboxes, constrained randomization, covergroups, and concurrent SVA is required. Some free simulators do not implement this full feature set.

## Expected result

On a successful run, the scoreboard reports zero errors and prints `PASS: scoreboard checks completed` together with transaction counters and functional coverage. A simulation run must be performed before claiming a tested result; no specific coverage percentage is assumed here.

## Suggested extensions

- Add mid-test reset injection and scoreboard reset synchronization.
- Add a larger matrix of WIDTH/DEPTH parameter configurations.
- Add reset recovery and back-to-back boundary tests.
- Produce saved coverage reports and waveforms from your actual simulator run.

## Notes

This project is a compact class-based verification environment, **not UVM**. Its checks correspond to the documented FIFO acceptance policy; changing that policy requires corresponding reference-model updates.
