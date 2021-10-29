// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This connects microwatt up to caravel.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,

    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

    // Tie unused outputs low 
    assign wbs_ack_o = 1'b0;
    assign wbs_dat_o = 32'b0;
    assign la_data_out = 128'b0;
    assign user_irq = 3'b0;

    wire clk;

    // microwatt signals
    wire ext_clk;
    wire ext_rst_n; // active low
    wire alt_reset;
    wire jtag_tck;
    wire jtag_tdi;
    wire jtag_tdo;
    wire jtag_tms;
    wire jtag_trst;
    wire spi_flash_clk;
    wire spi_flash_cs_n;
    wire [3:0] spi_flash_i;
    wire [3:0] spi_flash_o;
    wire [3:0] spi_flash_oe;
    wire uart0_rxd;
    wire uart0_txd;

    wire oib_clk;
    wire [7:0] ob_data;
    wire ob_pty;
    wire [7:0] ib_data;
    wire ib_pty;

    wire [31:0] gpio_in;
    wire [31:0] gpio_out;
    wire [31:0] gpio_dir;

    // XXX wire this up
    wire external_irq;

    // QSPI unused since we are out of I/Os
    assign spi_flash_i[0] = 0;
    assign spi_flash_i[2] = 0;
    assign spi_flash_i[3] = 0;

    // Only 21 GPIOs, tie the rest low
    assign gpio_in[31:21] = 11'b0;

    // This means we cant use JTAG while the core is in reset
    assign jtag_trst = ~ext_rst_n;

    assign clk = wb_clk_i;

    // microwatt signals
    assign ext_clk = clk;

    // pin 0 - GPIO[20]
    assign gpio_in[20] = io_in[0];
    assign io_out[0] = gpio_out[20];
    assign io_oeb[0] = ~gpio_dir[20];

    // pins 1-4 are the housekeeping SPI slave. Don't use them
    assign io_out[4:1] = 4'b0;
    assign io_oeb[4:1] = 4'b0;

    // UART pins 5-6
    assign uart0_rxd = io_in[5];
    assign io_out[5] = 0; // don't care
    assign io_oeb[5] = 1; // input

    assign io_out[6] = uart0_txd;
    // We'd previously assign rst to the iob, do we need to?
    assign io_oeb[6] = 0; // output

    // reset pin 7
    assign ext_rst_n = ~io_in[7];
    assign io_out[7] = 0; // don't care
    assign io_oeb[7] = 1; // input

    // SPI pins 8-11
    assign io_out[8] = spi_flash_cs_n; //(polarity??)
    assign io_oeb[8] = 0; // output

    assign io_out[9] = spi_flash_clk;
    assign io_oeb[9] = 0; // output

    assign io_out[10] = spi_flash_o[0];
    assign io_oeb[10] = 0; // output

    assign spi_flash_i[1] = io_in[11];
    assign io_out[11] = 0; // don't care
    assign io_oeb[11] = 1; // input

    // JTAG pins 12-15
    assign io_out[12] = jtag_tdo;
    assign io_oeb[12] = 0; // output

    assign jtag_tms = io_in[13];
    assign io_out[13] = 0; // don't care
    assign io_oeb[13] = 1; // input

    assign jtag_tck = io_in[14];
    assign io_out[14] = 0; // don't care
    assign io_oeb[14] = 1; // input

    assign jtag_tdi = io_in[15];
    assign io_out[15] = 0; // don't care
    assign io_oeb[15] = 1; // input

    // external bus and GPIOs share I/Os 16-34
    // XXX Need to add a mux to select between them
    assign gpio_in[18:0] = io_in[34:16];
    assign io_out[34:16] = gpio_out[18:0];
    assign io_oeb[34:16] = ~gpio_dir[18:0];

    // Fetch from flash on reset - pin 35
    assign alt_reset = io_in[35];
    assign io_out[35] = 0; // don't care
    assign io_oeb[35] = 1; // input

    // External bus IRQ - pin 36
    assign external_irq = io_in[36];
    assign io_out[36] = 0; // don't care
    assign io_oeb[36] = 1; // input

    // GPIO 20 - pin 37
    assign gpio_in[20] = io_in[37];
    assign io_out[37] = gpio_out[20];
    assign io_oeb[37] = ~gpio_dir[20];

    // external bus pins 16-34 -> 16-25 outputs, 26-34 inputs
    //assign =  in[18:27] = rst; don't care
    //assign io_oeb[25:16] = {10{rst}}; // outputs
    //assign io_out[16] = oib_clk;
    //assign io_out[24:17] = ob_data;
    //assign io_out[25] = ob_pty;

    //assign io_out[34:26] = 0; // don't care
    //assign io_oeb[34:26] = {9{1'b1}}; // input
    //assign ib_data = io_in[33:26];
    //assign ib_pty = io_in[34];

    microwatt microwatt_0(
    `ifdef USE_POWER_PINS
        .vccd1(vccd1), // User area 1 1.8V power
        .vssd1(vssd1), // User area 1 digital ground
    `endif
        .ext_clk(ext_clk),
        .ext_rst(ext_rst_n),
        .alt_reset(alt_reset),
        .uart0_rxd(uart0_rxd),
        .uart0_txd(uart0_txd),
        .jtag_tck(jtag_tck),
        .jtag_tdi(jtag_tdi),
        .jtag_tms(jtag_tms),
        .jtag_trst(jtag_trst),
        .jtag_tdo(jtag_tdo),
        .spi_flash_cs_n(spi_flash_cs_n),
        .spi_flash_clk(spi_flash_clk),
        .spi_flash_sdat_o(spi_flash_o),
        .spi_flash_sdat_i(spi_flash_i),
        .spi_flash_sdat_oe(spi_flash_oe),

//        .oib_clk(oib_clk),
//        .ob_data(ob_data),
//        .ob_pty(ob_pty),
//        .ib_data(ib_data),
//        .ib_pty(ib_pty),

        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir)
    );
endmodule	// user_project_wrapper
`default_nettype wire
