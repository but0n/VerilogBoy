`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    15:28:43 02/07/2018 
// Design Name: 
// Module Name:    dvi_mixer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dvi_mixer(
    input clk,
    input rst,
    // GameBoy Image Input
    input gb_hs,
    input gb_vs,
    input gb_pclk,
    input [1:0] gb_pdat,
    input gb_valid,
    // Debugger Char Input
    output [6:0] dbg_x,
    output [4:0] dbg_y,
    input [6:0] dbg_char,
    output dbg_sync,
    // DVI signal Output
    output dvi_hs,
    output dvi_vs,
    output dvi_blank,
    output reg [7:0] dvi_r,
    output reg [7:0] dvi_g,
    output reg [7:0] dvi_b
    );

    //Decoded GameBoy Input colors
    wire [7:0] gb_r;
    wire [7:0] gb_g;
    wire [7:0] gb_b;

    //Background colors
    wire [7:0] bg_r;
    wire [7:0] bg_g;
    wire [7:0] bg_b;

    //X,Y positions generated by the timing generator
    wire [10:0] dvi_x;
    wire [10:0] dvi_y;
    
    //X,Y positions of GB display
    wire [7:0] gb_x;
    wire [7:0] gb_y;

    //VGA font
    wire [6:0] font_ascii;
    wire [3:0] font_row;
    wire [2:0] font_col;
    wire font_pixel;

    //Final pixel output
    wire [7:0] out_r;
    wire [7:0] out_g;
    wire [7:0] out_b;

    wire signal_in_gb_range;
    assign out_r = (signal_in_gb_range) ? (gb_r) : (bg_r);
    assign out_g = (signal_in_gb_range) ? (gb_g) : (bg_g);
    assign out_b = (signal_in_gb_range) ? (gb_b) : (bg_b);

    always @(negedge clk)
    begin
      dvi_r <= out_r;
      dvi_g <= out_g;
      dvi_b <= out_b;
    end

    // Font
    localparam font_fg_color = 8'hFF;
    localparam font_bg_color = 8'h20;
    assign dbg_x[6:0] = dvi_x[9:3];
    assign dbg_y[4:0] = dvi_y[8:4];
    assign font_ascii[6:0] = dbg_char[6:0];
    assign font_row[3:0] = dvi_y[3:0];
    assign font_col[2:0] = dvi_x[2:0];
    assign bg_r[7:0] = (font_pixel) ? (font_fg_color) : (font_bg_color);
    assign bg_g[7:0] = (font_pixel) ? (font_fg_color) : (font_bg_color);
    assign bg_b[7:0] = (font_pixel) ? (font_fg_color) : (font_bg_color);
    assign dbg_sync = dvi_vs;

    // Gameboy Input
    reg [7:0] gb_v_counter;
    reg [7:0] gb_h_counter;
    
    reg [1:0] gb_buffer [0:23039];
    wire gb_wr_valid = (gb_v_counter > 8'd0);
    wire [14:0] gb_wr_addr = ((gb_v_counter > 8'd0)?(gb_v_counter - 8'd1):8'd0) * 160 + gb_h_counter;
    
    reg gb_vs_last;
    reg gb_hs_last;
    reg gb_pclk_last;
    
    always @(posedge clk)
    begin
        if (rst) begin
            gb_vs_last <= 0;
            gb_hs_last <= 0;
            gb_pclk_last <= 0;
        end
        else begin
            gb_vs_last <= gb_vs;
            gb_hs_last <= gb_hs;
            gb_pclk_last <= gb_pclk;
        end
    end
    
    always @(posedge clk)
    begin
        if (rst) begin
            gb_v_counter <= 0;
            gb_h_counter <= 0;
        end
        else begin
            if ((gb_vs_last == 1)&&(gb_vs == 0)) begin
                gb_v_counter <= 0;
            end
            else if ((gb_hs_last == 1)&&(gb_hs == 0)) begin
                gb_h_counter <= 0;
                gb_v_counter <= gb_v_counter + 1'b1;
            end 
            else if (gb_valid) begin
                if ((gb_pclk_last == 0)&&(gb_pclk == 1)) begin
                    gb_h_counter <= gb_h_counter + 1'b1;
                    if (gb_wr_valid)
                        gb_buffer[gb_wr_addr] <= gb_pdat;
                end
            end
        end
    end

    // Debug
    wire [14:0] gb_rd_addr = gb_y * 160 + gb_x;
    reg [1:0] gb_rd_data;
    
    always @ (posedge clk)
    begin
        gb_rd_data <= gb_buffer[gb_rd_addr];
    end
    
    assign gb_r[7:0] = (gb_rd_data == 2'b11) ? (8'h00) : 
                      ((gb_rd_data == 2'b10) ? (8'h55) : 
                      ((gb_rd_data == 2'b01) ? (8'hAA) : (8'hFF)));
    assign gb_g[7:0] = gb_r[7:0];
    assign gb_b[7:0] = gb_r[7:0];
    //assign gb_g[7:0] = gb_x[7:0];
    //assign gb_b[7:0] = gb_y[7:0];
    
    dvi_timing dvi_timing(
      .clk(clk),
      .rst(rst),
      .hs(dvi_hs),
      .vs(dvi_vs),
      .vsi(gb_vs),
      .x(dvi_x),
      .y(dvi_y),
      .gb_x(gb_x),
      .gb_y(gb_y),
      .gb_en(signal_in_gb_range),
      .enable(dvi_blank)
      //.address()
    );

    vga_font vga_font(
      .clk(clk),
      .ascii_code(font_ascii),
      .row(font_row),
      .col(font_col),
      .pixel(font_pixel)
    );    
    
endmodule
