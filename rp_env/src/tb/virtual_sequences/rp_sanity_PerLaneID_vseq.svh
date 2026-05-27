// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

//-----------------------------------------------------------------------------
//
// CLASS: rp_sanity_PerLaneID_vseq
//
//
//-----------------------------------------------------------------------------

class rp_sanity_PerLaneID_vseq extends virtual_sequence_base;
  `uvm_object_utils(rp_sanity_PerLaneID_vseq)

  ltsmc_sequence                     ltsmc_seq;
  rmblink_sanity_PerLaneID_sequence  rmblink_sanity_PerLaneID_seq;


  // Function: new
  //
  // Creates a new rp_sanity_PerLaneID_vseq instance with the given name.

  extern function new(string name = "rp_sanity_PerLaneID_vseq");


  // Task: pre_body
  //
  // Creates instances of child reactive sequences before body execution.

  extern task pre_body();


  // Task: body
  //
  // Runs SBINIT to completion and then launches the directed ACTIVE-phase
  // sequences on the child sequencers.

  extern task body();

endclass : rp_sanity_PerLaneID_vseq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rp_sanity_PerLaneID_vseq
//
//-----------------------------------------------------------------------------


// new
// ---

function rp_sanity_PerLaneID_vseq::new(string name = "rp_sanity_PerLaneID_vseq");
  super.new(name);
endfunction : new

// pre_body
// --------

task rp_sanity_PerLaneID_vseq::pre_body();
  super.pre_body();
  ltsmc_seq                    = ltsmc_sequence::type_id::create("ltsmc_seq");
  rmblink_sanity_PerLaneID_seq = rmblink_sanity_PerLaneID_sequence::type_id::create("rmblink_sanity_PerLaneID_seq");
endtask : pre_body

// body
// ----
  
task rp_sanity_PerLaneID_vseq::body();
  ltsmc_seq.configure(
     ._next_state_type(CUSTOM)
    ,._lane_map_code(X16_MODE)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._next_rx_enc(MBINIT_REVERSAL_RX_Init_Handshake)
  );
  ltsmc_seq.start(ltsmc_seqr); 
    
  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(X16_MODE)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._next_rx_enc(RESET_Reset)
  );
  ltsmc_seq.start(ltsmc_seqr);

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(X16_MODE)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._next_rx_enc(RESET_Reset)
  );
  ltsmc_seq.start(ltsmc_seqr);
  
  for (int i = 0; i < 32; i++) begin
    if (i == 0) begin
      rmblink_sanity_PerLaneID_seq.start(rmblink_seqr);
    end else begin
      rmblink_sanity_PerLaneID_seq.start(rmblink_seqr);
    end
  end

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(X16_MODE)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._next_rx_enc(RESET_Reset)
  );
  ltsmc_seq.start(ltsmc_seqr);

  ltsmc_seq.configure(
     ._next_state_type(NEXT)
    ,._lane_map_code(X16_MODE)
    ,._error_threshold(0)
    ,._half_rate(1'b1)
    ,._next_rx_enc(RESET_Reset)
  );
  ltsmc_seq.start(ltsmc_seqr);
  
endtask : body
