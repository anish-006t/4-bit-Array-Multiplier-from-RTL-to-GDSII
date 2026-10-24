# 4-bit Array Multiplier from RTL to GDSII

Digital VLSI Design assignment: a 4-bit × 4-bit unsigned array multiplier (8-bit product) in Verilog, taken through an open-source RTL-to-GDSII flow on the SkyWater SKY130 process (standard cell library `sky130_fd_sc_hd`).

## Team

| Name | Roll number |
|---|---|
| `Anish Toshniwal` | `2024102009` |
| `Saumya Vira` | `2024102044` |

## Repository layout

```
README.md
rtl/full_adder.v           full adder (assign statements)
rtl/mult_array.v           4x4 array multiplier: 16 AND gates, 12 full adders, 16 flip-flops
tb/tb_mult.v               exhaustive self-checking testbench (256 vectors)
synth/synth.tcl            Yosys synthesis script                      (Part B)
synth/mult_array_netlist.v gate-level netlist (generated)               (Part B)
synth/mult_array_stat.rpt  cell and area report (generated)             (Part B)
sta/sta.tcl                OpenSTA script                               (Part C)
sta/mult_array_timing.rpt  critical path report (generated)            (Part C)
pnr/config.json            LibreLane configuration                      (Part D)
pnr/metrics.json           copied from the final LibreLane run          (Part D)
pnr/mult_array.gds         copied from the final LibreLane run          (Part D)
report/report.pdf          report
```

## Environment

All tools come from the IIC-OSIC-TOOLS Docker image (`hpretl/iic-osic-tools:latest`), with the SKY130 PDK selected (`PDK=sky130A`). The repository folder is mounted inside the container at `/foss/designs`, and every tool command below is run inside the container from `/foss/designs`.

Tool versions in the image: Icarus Verilog 14.0 (devel), Yosys 0.70, OpenSTA 3.1.0, LibreLane 3.1.0.dev3.

## Commands, in the order they were run

### 0. Environment setup (on the host)

```bash
docker pull hpretl/iic-osic-tools:latest
```

Check the tools (inside the container):

```bash
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK            # /foss/pdks sky130A
```

### Part A — RTL design and verification

Simulate the RTL with the exhaustive testbench:

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`

View the waveform:

```bash
gtkwave mult.vcd
```

Error test (task 6): temporarily change `sum` in `rtl/full_adder.v` to `a ^ b`, rerun, then undo:

```bash
sed -i 's/assign sum  = a ^ b ^ cin;/assign sum  = a ^ b;/' rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
sed -i 's/assign sum  = a ^ b;/assign sum  = a ^ b ^ cin;/' rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result with the error: `FAIL: 256 vectors checked, 95 errors`; after undoing it: `PASS: 256 vectors checked, 0 errors`

Worked example (task 5): roll number of Saumya Vira (2024102044) was used. A = last digit 4 + 5 = 9, B = 7, A × B = 63 (`00111111`). In the waveform, a = 9, b = 7 are applied at 3040 ns and p = 63 appears at the rising edge at 3055 ns.

### Part B — Logic synthesis with Yosys

Synthesize the RTL to SKY130 standard cells (writes `synth/mult_array_stat.rpt` and `synth/mult_array_netlist.v`):

```bash
yosys -c synth/synth.tcl
```

Simulate the gate-level netlist with the same testbench:

```bash
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

Result: `PASS: 256 vectors checked, 0 errors`

### Part C — Static timing analysis with OpenSTA

Run 1, with `set T 10.0` in `sta/sta.tcl`:

```bash
sta sta/sta.tcl
```

Result: `worst slack max 7.21` (7.213 ns in `sta/mult_array_timing.rpt`), so T_min = 10 − 7.213 = 2.787 ns ≈ 2.79 ns.

Run 2, after changing the period in `sta/sta.tcl` to `set T 2.79`:

```bash
sed -i 's/^set T 10.0$/set T 2.79/' sta/sta.tcl
sta sta/sta.tcl
```

Result: `worst slack max 0.00` (0.003 ns in `sta/mult_array_timing.rpt`). The committed `sta/mult_array_timing.rpt` is from this run.

### Part D — Physical design with LibreLane

Starting `CLOCK_PERIOD` = 1.2 × T_min = 1.2 × 2.787 = 3.344 ns, rounded up to the next 0.5 ns = 3.5 ns. For each run, `CLOCK_PERIOD` in `pnr/config.json` was set to the value in the table, and the flow was run with:

```bash
cd pnr
librelane config.json
```

When a run failed timing, `CLOCK_PERIOD` was increased by 0.5 ns and the flow was run again. All attempts (setup slack = worst over all corners, from `final/metrics.json`):

| Run | Folder (`pnr/runs/`) | CLOCK_PERIOD (ns) | Setup slack (ns) | DRC errors | LVS errors | Result |
|---|---|---|---|---|---|---|
| 1 | `RUN_2026-10-25_11-46-09` | 3.5 | −2.546 | 0 | 0 | Setup violations (ss corners) |
| 2 | `RUN_2026-10-25_11-48-25` | 4.0 | −2.027 | 0 | 0 | Setup violations (ss corners) |
| 3 | `RUN_2026-10-25_11-49-57` | 4.5 | −1.527 | 0 | 0 | Setup violations (ss corners) |
| 4 | `RUN_2026-10-25_11-51-29` | 5.0 | −1.027 | 0 | 0 | Setup violations (ss corners) |
| 5 | `RUN_2026-10-25_11-53-02` | 5.5 | −0.527 | 0 | 0 | Setup violations (ss corners) |
| 6 | `RUN_2026-10-25_11-54-34` | 6.0 | −0.037 | 0 | 0 | Setup violations (ss corners) |
| 7 | `RUN_2026-10-25_11-56-04` | 6.5 | −0.205 | 0 | 0 | Setup violations (ss corners) |
| 8 | `RUN_2026-10-25_11-57-33` | 7.0 | −0.116 | 0 | 0 | Setup violations (ss corners) |
| 9 | `RUN_2026-10-25_11-59-03` | 7.5 | −0.138 | 0 | 0 | Setup violations (ss corners) |
| 10 | `RUN_2026-10-25_12-00-34` | 8.0 | +0.362 | 0 | 0 | **Clean, flow completed** |

Copy the results of the final run into `pnr/`:

```bash
cp runs/RUN_2026-10-25_12-00-34/final/metrics.json metrics.json
cp runs/RUN_2026-10-25_12-00-34/final/gds/mult_array.gds mult_array.gds
```

View the layout:

```bash
klayout mult_array.gds
```
