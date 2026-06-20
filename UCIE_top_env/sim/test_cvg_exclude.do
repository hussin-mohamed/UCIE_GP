coverage configure -2stepexclusion off
do apply_exclusions.do
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cp_fullcode}
coverage save test_clean.ucdb
vcover report test_clean.ucdb -details -cvg -directive -output test_report.txt
quit
