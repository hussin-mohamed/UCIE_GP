vlib work
vlog -f src_files.f -mfcu +cover +define+SIM
vsim -voptargs=+acc work.LTSM_top -classdebug -uvmcontrol=all -cover +UVM_VERBOSITY=UVM_MEDIUM +UVM_NO_RELNOTES +UVM_TESTNAME=LTSM_test_base
set NoQuitOnFinish 1

#.vcop Action toggleleafnames
#wave zoom range 0ns 26ns

#coverage save LTSM_tb.ucdb -onexit
run -all

#coverage report -detail -cvg -directive -comments -output seqcover_report.txt /.
#coverage report -detail -cvg -directive -comments -output fcover_report.txt {}
#quit -sim
#vcover report LTSM_tb.ucdb -details -annotate -all -output coverage_rpt.txt
