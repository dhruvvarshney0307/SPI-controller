# SPI-controller

Simple single-master / single-slave SPI implementation in SystemVerilog.  
Supports an 8-bit full-duplex transfer where the master drives SCLK and CS, and master & slave exchange data via MOSI/MISO.

> **SPI Mode:** CPOL = 0, sample on SCLK high (Mode 0-like).  
> **SCLK behavior:** Master toggles `sclk` every rising `clk` (so SCLK ≈ `clk/2` while transferring).

---

## Files / Modules
- `spi_if` — interface with `mosi`, `miso`, `sclk`, `cs` and `clk`.
- `spi_master` — master FSM: `IDLE → TRANSFER → DONE`. Starts transfer on `start`, outputs `done`.
- `spi_slave` — preloads `slave_data`, shifts MISO out and captures MOSI into `received_data`.
- `spi_top` — wires the master and slave to the shared `spi_if`.

---

## Top-level ports (spi_top)
- `clk` — system clock for FSMs.
- `rst` — async reset, active high.
- `start_transfer` — pulse to begin an 8-bit transfer.
- `master_data_in [7:0]` — byte master sends.
- `slave_preload_data [7:0]` — byte slave will send (MISO).
- `transfer_complete` — master’s `done` signal.
- `master_data_out [7:0]` — byte the master received from slave.
- `slave_received_data [7:0]` — byte the slave received from master.

SPI bus signals (in `spi_if`):
- `mosi`, `miso`, `sclk`, `cs` (active low), `clk`.

---

## How it works (summary)
- In `IDLE`, asserting `start_transfer` causes the master to assert `cs` low, load `data_in`, and present the MSB on `mosi`.
- In `TRANSFER`, the master toggles `sclk` every rising `clk`. When `sclk` becomes `1`, the master:
  - samples `miso` into `data_out[bit_cnt]`,
  - shifts its internal register and updates `mosi`,
  - decrements `bit_cnt`.
- After the final bit is sampled (`bit_cnt == 0` and `sclk == 1`), the master transitions to `DONE`, raises `cs`, and asserts `done`.
- The slave samples when `cs` is low and `sclk` is high: it shifts its shift register, updates `miso`, and captures `mosi` into `received_data`.

**Note:** Because `sclk` toggles every `clk` edge, a full SCLK period equals two `clk` cycles. Choose your `clk` frequency so that SCLK meets your timing requirements.

---

## Integration & usage tips
- Drive `start_transfer` for at least one `clk` cycle (module samples `start` in `IDLE`).
- Preload slave data into `slave_preload_data` before starting if you want a known slave response.
- Ensure both master and slave share the same `clk` domain in this design; add CDC logic if using different clocks.
- Use a waveform viewer to verify `cs`, `sclk`, `mosi`, and `miso` timing during first tests.

---

## License
Choose your license (example MIT):

