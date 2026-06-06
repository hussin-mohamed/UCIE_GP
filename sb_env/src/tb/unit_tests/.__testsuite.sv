module __testsuite;
  import svunit_pkg::svunit_testsuite;

  string name = "__ts";
  svunit_testsuite svunit_ts;
  
  
  //===================================
  // These are the unit tests that we
  // want included in this testsuite
  //===================================
  sb_scoreboard_unit_test sb_scoreboard_ut();


  //===================================
  // Build
  //===================================
  function void build();
    sb_scoreboard_ut.build();
    sb_scoreboard_ut.__register_tests();
    svunit_ts = new(name);
    svunit_ts.add_testcase(sb_scoreboard_ut.svunit_ut);
  endfunction


  //===================================
  // Run
  //===================================
  task run();
    svunit_ts.run();
    sb_scoreboard_ut.run();
    svunit_ts.report();
  endtask

endmodule
