//Sw[7:0] data_in

//KEY[0] synchronous reset when pressed
//KEY[1] go signal

//LEDR displays result
//HEX0 & HEX1 also displays result

module lab6part3(SW, KEY, CLOCK_50, LEDR, HEX0, HEX1,HEX2,HEX3,HEX4,HEX5);
    input [9:0] SW;
    input [3:0] KEY;
    input CLOCK_50;
    output [8:0] LEDR;
    output [6:0] HEX0, HEX1,HEX2,HEX3,HEX4,HEX5;

    wire resetn;
    wire go;

    wire [8:0] data_result;
    assign go = ~KEY[1];
    assign resetn = KEY[0];

    part2 u0(
        .clk(CLOCK_50),
        .resetn(resetn),
        .go(go),
        .data_in(SW[7:0]),
        .data_result(data_result)
    );
      
    assign LEDR[8:0] = data_result;

    hex_decoder H0(
        .hex_digit(SW[3:0]), 
        .segments(HEX0)
        );
        
    hex_decoder H1(
        .hex_digit(SW[7:4]), 
        .segments(HEX2)
        );
	hex_decoder H2(
        .hex_digit(data_result[3:0]), 
        .segments(HEX4)
        );	 
	hex_decoder H3(
        .hex_digit(data_result[7:4]), 
        .segments(HEX5)
        ); 
	hex_decoder H4(
        .hex_digit(4'b0), 
        .segments(HEX1)
        );
   hex_decoder H5(
        .hex_digit(4'b0), 
        .segments(HEX3)
        );

endmodule

module part2(
    input clk,
    input resetn,
    input go,
    input [7:0] data_in,
    output [8:0] data_result
    );

    // lots of wires to connect our datapath and control
    wire ld_a, ld_r;
    wire ld_alu_out;
   
    wire [2:0]alu_op;

    control C0(
        .clk(clk),
        .resetn(resetn),
        
        .go(go),
        
        .ld_alu_out(ld_alu_out), 
        
        .ld_a(ld_a),
        
        .ld_r(ld_r), 
        
        
        .alu_op(alu_op)
    );

    datapath D0(
        .clk(clk),
        .resetn(resetn),

        .ld_alu_out(ld_alu_out), 
       
        .ld_a(ld_a),
        
        .ld_r(ld_r), 

      
        .alu_op(alu_op),

        .data_in(data_in),
        .data_result(data_result)
    );
                
 endmodule        
                

module control(
    input clk,
    input resetn,
    input go,

    output reg  ld_a,  ld_r,
    output reg  ld_alu_out,
   
    output reg [2:0]alu_op
    );

    reg [2:0] current_state, next_state; 
	 reg [2:0]count;
    
    localparam  S_LOAD_A        = 4'd0,
                S_LOAD_A_WAIT   = 4'd1,
                S_shift        = 4'd2,
                S_substract   = 4'd3,
                S_q0        = 4'd4,
                S_add   = 4'd5,
                S_output        = 4'd6;
                
    
    // Next state logic aka our state table
    always @(*)
    begin: state_table 
            case (current_state)
                S_LOAD_A: begin 
					 count = 3'b000;
					 next_state = go ? S_LOAD_A_WAIT : S_LOAD_A;
					 
				    end  	// Loop in current state until value is input
                S_LOAD_A_WAIT: next_state = go ? S_LOAD_A_WAIT : S_shift; // Loop in current state until go signal goes low
                S_shift: next_state = S_substract; 
                S_substract: next_state = S_q0; 
                S_q0: next_state = S_add; 
                S_add: begin
					 count = count+3'b001;
					 next_state = (count == 3'b100) ? S_output : S_shift;
					 
					 end 
                S_output:next_state =S_LOAD_A;
            default:     next_state = S_LOAD_A;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_alu_out = 1'b0;
        ld_a = 1'b0;
        
        ld_r = 1'b0;
        
        alu_op       = 3'b000;

        case (current_state)
            S_LOAD_A: begin
                ld_a = 1'b1;
                end
            S_shift: begin
                ld_alu_out = 1'b1; ld_a = 1'b1;
					 alu_op = 3'b010;
                end
            S_substract: begin
                ld_alu_out = 1'b1; ld_a = 1'b1;
					 alu_op = 3'b001;
                end
            S_add: begin
                ld_alu_out = 1'b1; ld_a = 1'b1;
					 alu_op = 3'b000;
                end
            S_q0: begin 
                ld_alu_out = 1'b1; ld_a = 1'b1; 
                
                alu_op = 3'b011; 
            end
            S_output: begin
                ld_r = 1'b1;
					 alu_op = 3'b100; // store result in result register
                
                
            end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_A;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath(
    input clk,
    input resetn,
    input [7:0] data_in,
    input ld_alu_out, 
    input ld_a,
    input ld_r,
    input [2:0]alu_op, 
    
    output reg [8:0] data_result
    );
    
    // input registers
    reg [8:0] a;

    // output of the alu
    reg [8:0] alu_out;
    
    
    // Registers a with respective input logic
    always @ (posedge clk) begin
        if (!resetn) begin
            a <= 9'd0; 
            
        end
        else begin
            if (ld_a)
                a <= ld_alu_out ? alu_out : {5'b00000,data_in[7:4]}; // load alu_out if load_alu_out signal is high, otherwise load from data_in
            
        end
    end
 
    // Output result register
    always @ (posedge clk) begin
        if (!resetn) begin
            data_result <= 8'd0; 
        end
        else 
            if(ld_r)
                data_result <= alu_out;
    end

    
    // The ALU 
    always @(*)
    begin : ALU
        // alu
        case (alu_op)
            3'b000: begin
				if(a[8]==1'b1)
                   alu_out = a + {1'b0,data_in[3:0],4'b0};
				else
			          alu_out = a + {8'b00000000};	//performs addition
               end
            3'b001: begin
                   alu_out = a - {1'b0,data_in[3:0],4'b0}; //performs substraction
               end
				3'b010: begin
				       alu_out = {a[7:0],1'b0};
					end
				3'b011:begin
				      if(a[8]==1'b1)
                   alu_out = {a[8:1],1'b0} ;
						else
						 alu_out = {a[8:1],1'b1} ;
               end 
				3'b100:begin
				       alu_out = a ;	
               end
				
            default: alu_out = 8'b0;
        endcase
    end
    
endmodule


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
