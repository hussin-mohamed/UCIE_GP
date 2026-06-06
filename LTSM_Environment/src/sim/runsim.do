vlib work
vlog -f src_files.f -mfcu +define+SIM -l compile.log
vlog -f rtl_files.f -mfcu +cover +define+SIM -l compile.log
vsim -voptargs=+acc work.LTSM_top -classdebug -uvmcontrol=all -cover +UVM_VERBOSITY=UVM_MEDIUM +UVM_NO_RELNOTES +UVM_TESTNAME=MBTRAIN_test -l run.log
set NoQuitOnFinish 1


add wave -group rx_interface -position insertpoint  \
    sim:/LTSM_top/rx_fsm_sb_if/*

add wave -group tx_interface -position insertpoint  \
    sim:/LTSM_top/tx_fsm_sb_if/*

add wave -group controller_interface -position insertpoint  \
    sim:/LTSM_top/vif/*

add wave -group rdi_interface -position insertpoint  \
    sim:/LTSM_top/ltsm_rdi_if_inst/*
    
add wave -position insertpoint  \
sim:/LTSM_top/DUT/ucie_LTSM_TX_MBTRAIN_inst/encoding_rsp_received \
sim:/LTSM_top/DUT/ucie_LTSM_TX_MBTRAIN_inst/encoding_rsp_sent \
sim:/LTSM_top/DUT/ucie_LTSM_TX_MBTRAIN_inst/previous_state_done \
sim:/LTSM_top/DUT/ucie_LTSM_TX_MBTRAIN_inst/rsp_received \
sim:/LTSM_top/DUT/ucie_LTSM_TX_MBTRAIN_inst/rsp_sent
#.vcop Action toggleleafnames
#wave zoom range 0ns 26ns

coverage save LTSM_tb_train.ucdb -onexit
run -all



#coverage report -detail -cvg -directive -comments -output seqcover_report.txt /.
#coverage report -detail -cvg -directive -comments -output fcover_report.txt {}
#quit -sim
#vcover report LTSM_tb_train.ucdb -details -annotate -all -output coverage_rpt.txt
