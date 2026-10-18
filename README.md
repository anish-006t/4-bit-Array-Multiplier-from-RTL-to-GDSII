# 4-bit Array Multiplier from RTL to GDSII

Digital VLSI Design assignment: a 4-bit × 4-bit unsigned array multiplier (8-bit product) in Verilog, taken through an open-source RTL-to-GDSII flow on the SkyWater SKY130 process (standard cell library `sky130_fd_sc_hd`).

## Team

| Name | Roll number |
|---|---|
| `Anish Toshniwal` | `2024102009` |
| `Saumya vira` | `2024102044` |

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

Worked example (task 5): A = last digit of `<ROLL_NUMBER_USED>` (`<NAME_USED>`) + 5 = `<A>`, B = `<B>`, A × B = `<P>`.

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

_To be added._
