package mods;
  //imports

  ///////////////////////////////// interface definitions ////////////////////////////////////////
  //8 bit fulladder
  interface Ifc_8Fadder;
    method ActionValue #(Bit#(9)) f8adder_result (Bit#(8)a, Bit#(8)b, Bit#(1)c);
  endinterface:Ifc_8Fadder

  //32 bit fulladder
  interface Ifc_Fulladder;
    method ActionValue #(Bit#(33)) fulladder_result (Bit#(32)a, Bit#(32)b, Bit#(1)c);
  endinterface:Ifc_Fulladder

  //16x16 bit multiplier
  interface Ifc_Mul;
    method ActionValue #(Bit#(32)) mul_result (Bit#(16)a, Bit#(16)b);
  endinterface:Ifc_Mul
  
  //integer mac module.
  interface Ifc_Intmac;
    method ActionValue #(Bit#(32)) intmac_result (Bit#(8)a, Bit#(8)b, Bit#(32)c);
  endinterface:Ifc_Intmac

   //floating point mac module.
  interface Ifc_Fpmac;
    method ActionValue #(Bit#(32)) fpmac_result (Bit#(16)a, Bit#(16)b, Bit#(32)c);
  endinterface:Ifc_Fpmac

  // Interface for the MAC module, to be used in the systolic array
  interface Ifc_MAC;
    method Action A(Bit#(8) value);        // For int8 inputs, 8-bit data type
    method Action B(Bit#(8) value);        // For int8 inputs, 8-bit data type
    method Action C(Bit#(32) value);       // For int32 or fp32 accumulations
    method Action S1_or_S2(Bool sel);      // True for int8, False for bf16
    method Bit#(32) MAC();                 // The final result of the MAC operation (int32 or fp32)
  endinterface:Ifc_MAC

 ///////////////////////////////// module definitions ////////////////////////////////////////
  //8 bit fulladder
  module mk8Fadder(Ifc_8Fadder);
    method ActionValue #(Bit#(9)) f8adder_result (Bit#(8)a, Bit#(8)b, Bit#(1)c);
      Bit#(9) carry = zeroExtend(c);
      Bit#(9) sum = 0;
      for (Integer i=0;i<8;i=i+1)begin
        carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        sum[i] = (a[i] ^ b[i] ^ carry[i]);
      end
      sum[8] = carry[8];
      return sum;
    endmethod
  endmodule:mk8Fadder

  //32 bit adder
  module mkFulladder(Ifc_Fulladder);
    method ActionValue #(Bit#(33)) fulladder_result (Bit#(32)a, Bit#(32)b, Bit#(1)c);
      Bit#(33) carry = zeroExtend(c);
      Bit#(33) sum = 33'b0;
      for (Integer i=0;i<32;i=i+1)begin
        carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        sum[i] = (a[i] ^ b[i] ^ carry[i]);
      end
      sum[32] = carry[32];
      return sum;
    endmethod
  endmodule:mkFulladder

  //16x16 bit multiplier.
  module mkMul(Ifc_Mul);
  //Booths multiplier.
   Ifc_Fulladder u1 <- mkFulladder;
   method ActionValue #(Bit#(32)) mul_result (Bit#(16)a, Bit#(16)b);
     Bit#(16) neg_a = 16'b0;
     Bit#(32) accum = 32'b0;
     Bit#(17) mplier = zeroExtend(b) <<1;
     Bit#(1)  prev_bit = 1'b0;
     Bit#(2) booth_bits;
     for(Integer i=0;i<16;i=i+1)begin
       if(a[fromInteger(i)] == 1'b1)
         neg_a[fromInteger(i)] = 1'b0;
       else
         neg_a[fromInteger(i)] = 1'b1;
     end
     let negative_a <- u1.fulladder_result(zeroExtend(neg_a),32'b0,1);
     Bit#(16) twoc_a = negative_a[15:0];
     for (Integer i=0;i<16;i=i+1)begin
       booth_bits= mplier[1:0];

       if (booth_bits == 2'b01) begin
         Bit#(32) sign_extended_a = 32'h00000000;
         if(a[15] == 1'b1) begin
           Bit#(32) temp = 32'hFFFF0000;
           sign_extended_a = temp | zeroExtend(a); 
         end
         if(a[15] == 1'b0) begin
           Bit#(32) temp = 32'h00000000;
           sign_extended_a = temp | zeroExtend(a);
         end
          let temp_accum <- u1.fulladder_result(accum, sign_extended_a << fromInteger(i), 0);
          accum = temp_accum[31:0];
       end
       else if (booth_bits == 2'b10) begin
         Bit#(32) sign_extended_twoc_a = 32'h00000000;
         if(twoc_a[15] == 1'b1) begin
           Bit#(32) temp = 32'hFFFF0000;
           sign_extended_twoc_a = temp | zeroExtend(twoc_a); 
         end
         if(twoc_a[15] == 1'b0) begin
           Bit#(32) temp = 32'h00000000;
           sign_extended_twoc_a = temp | zeroExtend(twoc_a);
         end
         let temp_accum <- u1.fulladder_result(accum, sign_extended_twoc_a << fromInteger(i), 0);
         accum = temp_accum[31:0];
       end

       mplier = mplier >> 1;
     end

     return accum;
   endmethod
  endmodule:mkMul

  //Integer Mac module.
  module mkIntmac(Ifc_Intmac);
    Ifc_Fulladder adder <- mkFulladder;
    Ifc_Mul multiplier <- mkMul;
    method ActionValue #(Bit#(32)) intmac_result (Bit#(8)a, Bit#(8)b, Bit#(32)c);
      Bit#(16) sign_extended_a = 16'h0000;
         if(a[7] == 1'b1) begin
           Bit#(16) temp = 16'hFF00;
           sign_extended_a = temp | zeroExtend(a); 
         end
         if(a[7] == 1'b0) begin
           Bit#(16) temp = 16'h0000;
           sign_extended_a = temp | zeroExtend(a);
         end
      Bit#(16) sign_extended_b = 16'h0000;
         if(b[7] == 1'b1) begin
           Bit#(16) temp = 16'hFF00;
           sign_extended_b = temp | zeroExtend(b); 
         end
         if(b[7] == 1'b0) begin
           Bit#(16) temp = 16'h0000;
           sign_extended_b = temp | zeroExtend(b);
         end 
      let mult_out <- multiplier.mul_result(sign_extended_a,sign_extended_b);
      let add_out <- adder.fulladder_result(mult_out,c,0);
      return add_out[31:0];
    endmethod:intmac_result
  endmodule:mkIntmac

  //Floating point mac module.
  (*synthesize*)
  module mkFpmac(Ifc_Fpmac);
    Ifc_8Fadder u1 <- mk8Fadder;
    Ifc_Mul u2 <- mkMul;
    Ifc_Fulladder u3 <- mkFulladder;
    Ifc_Fulladder u4 <- mkFulladder;
    method ActionValue #(Bit#(32)) fpmac_result (Bit#(16)a, Bit#(16)b, Bit#(32)c);
      //extraction of individual fields.
      Bit#(1) sign_a = a[15];
      Bit#(1) sign_b = b[15];
      Bit#(8) exponent_a = a[14:7];
      Bit#(8) exponent_b = b[14:7];
      Bit#(8) mantissa_a = zeroExtend(a[6:0]);
      Bit#(8) mantissa_b = zeroExtend(b[6:0]);
      mantissa_a[7] = 1'b1;
      mantissa_b[7] = 1'b1;

      //multiplication.
      //sign calculation.
      Bit#(1) sign_prod = sign_a ^ sign_b;
      //exponent calculation.
      let exp_pre_bias <- u1.f8adder_result(exponent_a,exponent_b,1'b0);
      let exp_add_bias <- u1.f8adder_result(exp_pre_bias[7:0],8'b10000001,0);
      Bit#(8) exp_prod = exp_add_bias[7:0];
      //mantissa calculation.
      let mantissa_mult_out <- u2.mul_result(zeroExtend(mantissa_a),zeroExtend(mantissa_b));
      Bit#(16) mantissa_prod = mantissa_mult_out[15:0];
      Bit#(23) mantissa_result = 23'b0;
      Bit#(8) exp_result = 8'b0;
      //normalization and translation of mantissa.
      if(mantissa_prod[15] == 1'b1)begin
        mantissa_result[22:8] = mantissa_prod[14:0];
        let exp_inc <- u1.f8adder_result(exp_prod,8'h00,1);
        exp_result = exp_inc[7:0];
      end
      else if(mantissa_prod[14] == 1'b1)begin
        mantissa_result[22:9] = mantissa_prod[13:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'h00,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[13] == 1'b1)begin
        mantissa_result[22:10] = mantissa_prod[12:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hFF,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[12] == 1'b1)begin
        mantissa_result[22:11] = mantissa_prod[11:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hFE,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[11] == 1'b1)begin
        mantissa_result[22:12] = mantissa_prod[10:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hFD,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[10] == 1'b1)begin
        mantissa_result[22:13] = mantissa_prod[9:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hFC,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[9] == 1'b1)begin
        mantissa_result[22:14] = mantissa_prod[8:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hFB,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[8] == 1'b1)begin
        mantissa_result[22:15] = mantissa_prod[7:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hFA,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[7] == 1'b1)begin
        mantissa_result[22:16] = mantissa_prod[6:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF9,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[6] == 1'b1)begin
        mantissa_result[22:17] = mantissa_prod[5:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF8,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[5] == 1'b1)begin
        mantissa_result[22:18] = mantissa_prod[4:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF7,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[4] == 1'b1)begin
        mantissa_result[22:19] = mantissa_prod[3:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF6,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[3] == 1'b1)begin
        mantissa_result[22:20] = mantissa_prod[2:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF5,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[2] == 1'b1)begin
        mantissa_result[22:21] = mantissa_prod[1:0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF4,0);
        exp_result = exp_dec[7:0];
      end
      else if(mantissa_prod[1] == 1'b1)begin
        mantissa_result[22] = mantissa_prod[0];
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF3,0);
        exp_result = exp_dec[7:0];
      end
      else begin
        mantissa_result = 23'b0;
        let exp_dec <- u1.f8adder_result(exp_prod,8'hF2,0);
        exp_result = exp_dec[7:0];
      end
      Bit#(32) mul_out = 0;
      mul_out[31] = sign_prod;
      mul_out[30:23] = exp_result;
      mul_out[22:0] = mantissa_result;

      //Addition.
      //seperation.
      Bit#(1) sign_c = c[31];
      Bit#(8) exp_c = c[30:23];
      Bit#(24) mantissa_c = {1'b1, c[22:0]};

      Bit#(24) aligned_mantissa_mul_out = {1'b1, mul_out[22:0]};
      Bit#(24) aligned_mantissa_c = mantissa_c;
      if (exp_result > exp_c) begin
         let exp_diff <- u1.f8adder_result(exp_result, ~exp_c, 1'b1);
         aligned_mantissa_c = aligned_mantissa_c >> exp_diff[7:0]; // Shift mantissa of c to align with mul_out
         exp_result = exp_result; // Keep exp_result as the common exponent
      end else if (exp_c > exp_result) begin
         let exp_diff <- u1.f8adder_result(exp_c, ~exp_result,1'b1);
         aligned_mantissa_mul_out = aligned_mantissa_mul_out >> exp_diff[7:0]; // Shift mantissa of mul_out
         exp_result = exp_c; // Set exp_result to the higher exponent
      end else begin
         Bit#(8) exp_diff = 8'd0;
      end
      Bit#(23) normalized_mantissa = 23'b0;
      Bit#(1) result_sign = 1'b0;
      Bit#(25) mantissa_sum = 25'b0;

      if (sign_prod == sign_c) begin
         let sum_res <- u4.fulladder_result(zeroExtend(aligned_mantissa_mul_out), zeroExtend(aligned_mantissa_c), 0);
         mantissa_sum = sum_res[24:0]; // No carry, so no additional bit required
         result_sign = sign_prod;
      end 
      else begin
         if (sign_c == 1'b1) begin
            Bit#(32) neg_summ = 32'hFFFFFFFF;
            neg_summ[23:0] = ~aligned_mantissa_c;
            let sub_res <- u4.fulladder_result(zeroExtend(aligned_mantissa_mul_out),neg_summ, 1);
            mantissa_sum = sub_res[24:0];
            if(aligned_mantissa_mul_out >= aligned_mantissa_c)
              result_sign = 1'b0;
            else
              result_sign = 1'b1;
         end 
         else begin
            Bit#(32) neg_summ = 32'hFFFFFFFF;
            neg_summ[23:0] = ~aligned_mantissa_mul_out;
            let sub_res <- u4.fulladder_result(zeroExtend(aligned_mantissa_c),neg_summ, 1);
            mantissa_sum = sub_res[24:0];
            if(aligned_mantissa_c >= aligned_mantissa_mul_out)
              result_sign = 1'b0;
            else
              result_sign = 1'b1;
         end
      end
      Bit#(8) expp = exp_result;
      if (mantissa_sum[24] == 1'b1) begin
          normalized_mantissa = mantissa_sum[23:1];
          exp_result = exp_result + 1; 
      end else if (mantissa_sum[23] == 1'b1) begin
          normalized_mantissa = mantissa_sum[22:0];
      end else if (mantissa_sum[22] == 1'b1) begin
          normalized_mantissa[22:1] = mantissa_sum[21:0];
          exp_result = exp_result - 1;
      end else if (mantissa_sum[21] == 1'b1) begin
          normalized_mantissa[22:2] = mantissa_sum[20:0];
          exp_result = exp_result - 2;
      end else if (mantissa_sum[20] == 1'b1) begin
          normalized_mantissa[22:3] = mantissa_sum[19:0];
          exp_result = exp_result - 3;
      end else if (mantissa_sum[19] == 1'b1) begin
          normalized_mantissa[22:4] = mantissa_sum[18:0];
          exp_result = exp_result - 4;
      end else if (mantissa_sum[18] == 1'b1) begin
          normalized_mantissa[22:5] = mantissa_sum[17:0];
          exp_result = exp_result - 5;
      end else if (mantissa_sum[17] == 1'b1) begin
          normalized_mantissa[22:6] = mantissa_sum[16:0];
          exp_result = exp_result - 6;
      end else if (mantissa_sum[16] == 1'b1) begin
          normalized_mantissa[22:7] = mantissa_sum[15:0];
          exp_result = exp_result - 7;
      end else if (mantissa_sum[15] == 1'b1) begin
          normalized_mantissa[22:8] = mantissa_sum[14:0];
          exp_result = exp_result - 8;
      end else if (mantissa_sum[14] == 1'b1) begin
          normalized_mantissa[22:9] = mantissa_sum[13:0];
          exp_result = exp_result - 9;
      end else if (mantissa_sum[13] == 1'b1) begin
          normalized_mantissa[22:10] = mantissa_sum[12:0];
          exp_result = exp_result - 10;
      end else if (mantissa_sum[12] == 1'b1) begin
          normalized_mantissa[22:11] = mantissa_sum[11:0];
          exp_result = exp_result - 11;
      end else if (mantissa_sum[11] == 1'b1) begin
          normalized_mantissa[22:12] = mantissa_sum[10:0];
          exp_result = exp_result - 12;
      end else if (mantissa_sum[10] == 1'b1) begin
          normalized_mantissa[22:13] = mantissa_sum[9:0];
          exp_result = exp_result - 13;
      end else if (mantissa_sum[9] == 1'b1) begin
          normalized_mantissa[22:14] = mantissa_sum[8:0];
          exp_result = exp_result - 14;
      end else if (mantissa_sum[8] == 1'b1) begin
          normalized_mantissa[22:15] = mantissa_sum[7:0];
          exp_result = exp_result - 15;
      end else if (mantissa_sum[7] == 1'b1) begin
          normalized_mantissa[22:16] = mantissa_sum[6:0];
          exp_result = exp_result - 16;
      end else if (mantissa_sum[6] == 1'b1) begin
          normalized_mantissa[22:17] = mantissa_sum[5:0];
          exp_result = exp_result - 17;
      end else if (mantissa_sum[5] == 1'b1) begin
          normalized_mantissa[22:18] = mantissa_sum[4:0];
          exp_result = exp_result - 18;
      end else if (mantissa_sum[4] == 1'b1) begin
          normalized_mantissa[22:19] = mantissa_sum[3:0];
          exp_result = exp_result - 19;
      end else if (mantissa_sum[3] == 1'b1) begin
          normalized_mantissa[22:20] = mantissa_sum[2:0];
          exp_result = exp_result - 20;
      end else if (mantissa_sum[2] == 1'b1) begin
          normalized_mantissa[22:21] = mantissa_sum[1:0];
          exp_result = exp_result - 21;
      end else if (mantissa_sum[1] == 1'b1) begin
          normalized_mantissa[22] = mantissa_sum[0];
          exp_result = exp_result - 22;
      end else begin
          normalized_mantissa = 23'b0;
           exp_result = 8'b0; // Underflow case; set exponent and mantissa to zero
      end
      Bit#(32) mac_out = 0;
      mac_out[31] = result_sign;
      mac_out[30:23] = exp_result;
      mac_out[22:0] = normalized_mantissa;
      return {sign_c,expp,mantissa_sum[22:0]};
    endmethod:fpmac_result
  endmodule:mkFpmac

  module mkMAC(Ifc_MAC);
    // Internal registers to hold A, B, and C values
    Reg#(Bit#(8)) A_reg <- mkReg(0);
    Reg#(Bit#(8)) B_reg <- mkReg(0);
    Reg#(Bit#(32)) C_reg <- mkReg(0);
    Reg#(Bool) S1_or_S2_reg <- mkReg(False); // Register to hold the S1_or_S2 selection
    method Action A(Bit#(8) value);
      A_reg <= value;
    endmethod
    method Action B(Bit#(8) value);
      B_reg <= value;
    endmethod
    method Action C(Bit#(32) value);
      C_reg <= value;
    endmethod
    method Action S1_or_S2(Bool sel);
      S1_or_S2_reg <= sel;
    endmethod
    method Bit#(32) MAC();
      Bit#(32) result;
      if (S1_or_S2_reg) begin
        result = intmac_result(A_reg, B_reg, C_reg);
      end else begin
        result = fpmac_result(A_reg, B_reg, C_reg);
      end
      return result;
    endmethod
    // Integer MAC operation for int8
    method Bit#(32) intmac_result(Bit#(8) a, Bit#(8) b, Bit#(32) c);
      Bit#(32) result = (zeroExtend(a) * zeroExtend(b)) + c;
      return result;
    endmethod
    // Floating point MAC operation for bfloat16
    method Bit#(32) fpmac_result(Bit#(16) a, Bit#(16) b, Bit#(32) c);
      Bit#(8) exponent_a = a[14:7];
      Bit#(8) exponent_b = b[14:7];
      Bit#(7) mantissa_a = a[6:0];
      Bit#(7) mantissa_b = b[6:0];

      Bit#(8) exp_result = exponent_a + exponent_b; // Simple exponent addition for example
      Bit#(14) mantissa_result = zeroExtend(mantissa_a) * zeroExtend(mantissa_b); // Mantissa multiplication
      // Handle normalization (simplified logic)
      if (mantissa_result[13] == 1'b1) begin
        exp_result = exp_result + 1;
        mantissa_result = mantissa_result >> 1; // Right shift for normalization
      end
      // Combine the result
      Bit#(32) result = {1'b0, exp_result, mantissa_result[13:6]}; // Assuming a 32-bit result
      result = result + c; // Add the accumulator (c)
      return result;
    endmethod
  endmodule:mkMAC
endpackage:mods
