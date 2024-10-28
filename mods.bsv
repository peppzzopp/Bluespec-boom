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
      let exp_add_bias <- u1.f8adder_result(exp_pre_bias[7:0],8'b01111111,0);
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

      //addition.
      //seperation.
      Bit#(1) sign_c = c[31];
      Bit#(8) exp_c = c[30:23];
      Bit#(24) mantissa_c = 24'hFFFFFF;
      mantissa_c[22:0] = c[22:0];
      return mul_out;
    endmethod:fpmac_result
  endmodule:mkFpmac
endpackage:mods
