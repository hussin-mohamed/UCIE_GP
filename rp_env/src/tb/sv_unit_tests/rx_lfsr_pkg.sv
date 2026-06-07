package rx_lfsr_pkg;
  parameter pDATA_WIDTH = 64;
  parameter pLFSR_TAPS = 23;
  parameter pNUM_LANES = 16;
  parameter logic [pLFSR_TAPS-1:0] LANE_ID [0:7] = '{
    23'h1DBFBC, // Lane 0,8
    23'h0607BB, // Lane 1,9
    23'h1EC760, // Lane 2,10
    23'h18C0DB, // Lane 3,11
    23'h010F12, // Lane 4,12
    23'h19CFC9, // Lane 5,13
    23'h0277CE, // Lane 6,14
    23'h1BB807  // Lane 7,15
  };

  static logic [pLFSR_TAPS-1:0] lfsr_state [pNUM_LANES-1:0];
  static logic [pLFSR_TAPS-1:0] lfsr_last_state [pNUM_LANES-1:0];
  static int lane_error_count [pNUM_LANES-1:0];
  logic expected_bit;

  function static load_lfsr_state (
     input  int                     _bit_index
    ,output logic [pDATA_WIDTH-1:0] _out_data [pNUM_LANES-1:0]
  );
    for (int i = 0; i < pNUM_LANES; i++) begin
      lfsr_state[i] = LANE_ID[i % 8];
      _out_data[i][_bit_index] = lfsr_state[i][pLFSR_TAPS-1];
    end
  endfunction : load_lfsr_state

  function static train_detection(
     input  logic [pDATA_WIDTH-1:0] _data             [pNUM_LANES-1:0]
    ,input  int                     _error_threshold
    ,input  int                     _bit_index
    ,output bit                     _success          [pNUM_LANES-1:0]
    ,output logic [pDATA_WIDTH-1:0] _out_data         [pNUM_LANES-1:0]
  );
    for (int i = 0; i < pNUM_LANES; i++) begin
      expected_bit = lfsr_state[i][pLFSR_TAPS-1];
      _out_data[i][_bit_index] = lfsr_state[i][pLFSR_TAPS-1];
      if (_data[i][_bit_index] !== expected_bit) begin
        lane_error_count[i]++;
      end
      if (lane_error_count[i] > _error_threshold) begin
        _success[i] = 1'b0;
      end else begin
        _success[i] = 1'b1;
      end
    end
  endfunction : train_detection

  function update_lfsr_state(input bit load);
    if (!load) begin
      foreach (lfsr_state[i,j]) begin
        if ((j == 2) || (j == 5) || (j == 8) || (j == 16) || (j == 21)) begin
          lfsr_state[i][j] = lfsr_last_state[i][j-1] ^ lfsr_last_state[i][pLFSR_TAPS-1];
        end else if (j == 0) begin
          lfsr_state[i][j] = lfsr_last_state[i][pLFSR_TAPS-1];
        end else begin
          lfsr_state[i][j] = lfsr_last_state[i][j-1];
        end
      end
    end

    lfsr_last_state = lfsr_state;
  endfunction : update_lfsr_state

  function static descramble_data(
     input  logic [pDATA_WIDTH-1:0] _data [pNUM_LANES-1:0]
    ,input  int                     _bit_index
    ,output logic [pDATA_WIDTH-1:0] _out_data [pNUM_LANES-1:0]
  );
    for (int i = 0; i < pNUM_LANES; i++) begin
      _out_data[i][_bit_index] = _data[i][_bit_index] ^ lfsr_state[i][pLFSR_TAPS-1];
    end
  endfunction : descramble_data

  function static rx_lfsr (
     input  bit                     _train
    ,input  bit                     _load
    ,input  logic [pDATA_WIDTH-1:0] _data             [pNUM_LANES-1:0]
    ,input  int                     _error_threshold
    ,output bit                     _success          [pNUM_LANES-1:0]
    ,output logic [pDATA_WIDTH-1:0] _out_data         [pNUM_LANES-1:0]
  );
    for (int bit_index = 0; bit_index < pDATA_WIDTH; bit_index++) begin   
      if (_load)begin
        load_lfsr_state(_out_data,bit_index);
        lane_error_count = '{default:0};
      end else if (_train) begin
        train_detection(_data, _success, _error_threshold, bit_index, _out_data);
      end else begin
        descramble_data(_data, bit_index, _out_data);
      end
      update_lfsr_state(_load);
    end  
  endfunction : rx_lfsr

endpackage : rx_lfsr_pkg
