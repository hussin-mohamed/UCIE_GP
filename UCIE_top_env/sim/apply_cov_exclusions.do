# ================================================================
# UCIe PHY Coverage Exclusions
# ================================================================

coverage exclude -du work.clock_divider #clock divider is a model.
coverage exclude -du work.PLL_model #PLL model is a model.
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 366 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 436 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 457 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 513 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 533 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 548 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 551 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 555 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 569 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 591 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 611 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 623 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 641 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 696 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 773 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 849 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 926 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1004 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1057 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1134 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1195 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1225 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 554 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 226 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 384 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 428 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 442 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 467 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 505 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 518 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 596 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 646 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 701 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 726 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 765 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 778 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 803 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 841 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 854 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 879 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 918 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 931 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 956 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 996 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1009 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1062 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1088 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv -line 1126 -code c
coverage exclude -du ucie_LTSM_TX_MBTRAIN -togglenode CS
coverage exclude -du ucie_LTSM_TX_MBTRAIN -togglenode current_substate
coverage exclude -du ucie_LTSM_TX_MBTRAIN -togglenode L1_access
coverage exclude -du ucie_LTSM_TX_MBTRAIN -togglenode L1_SPEEDIDLE_en
coverage exclude -du ucie_LTSM_TX_MBTRAIN -togglenode next_substate
coverage exclude -du ucie_LTSM_TX_MBTRAIN -togglenode NS
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 396 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 476 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 529 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 568 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 621 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 699 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 777 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 856 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 932 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 987 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 1063 -code s
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 407 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 486 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 539 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 577 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 631 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 709 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 787 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 866 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 942 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 997 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 1073 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 1271 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 1385 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 396 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 476 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 529 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 568 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 621 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 699 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 777 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 856 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 932 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 987 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 1063 -code b
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 176 -code e
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 351 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 395 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 475 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 492 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 515 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 528 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 567 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 620 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 698 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 776 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 855 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 931 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 986 -code c
coverage exclude -src ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv -line 1062 -code c