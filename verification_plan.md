# Verification Plan

| Feature | Stimulus | Expected behavior | Checking |
| --- | --- | --- | --- |
| Reset | Initial reset cycles | Empty asserted, used zero | SVA, scoreboard at test start |
| Basic enqueue/dequeue | Directed writes followed by reads | Preserves first-in-first-out ordering | Queue scoreboard |
| Full condition | Writes beyond FIFO capacity | Extra writes rejected | Scoreboard occupancy/full check |
| Empty condition | Reads beyond queued data | Extra reads rejected | Scoreboard occupancy/empty check |
| Read/write together | Both requests asserted | Correct acceptance and ordering | Scoreboard |
| Simultaneous ops at full | Both requests asserted when full | Oldest entry read; incoming entry accepted | Scoreboard |
| Simultaneous ops at empty | Both requests asserted when empty | Write accepted, read rejected | Scoreboard |
| Random traffic | Class-constrained request combinations | No data loss or reordering | Scoreboard |
| Control flags | All transactions | Full/empty agree with occupancy | SVA and scoreboard |
| Coverage | All monitored cycles | Action/occupancy bins sampled | Functional covergroup |

Limitations: No mid-run reset check, no asynchronous-clock operation, no timing closure or FPGA implementation, and no measured coverage results are included until the simulator is run.
