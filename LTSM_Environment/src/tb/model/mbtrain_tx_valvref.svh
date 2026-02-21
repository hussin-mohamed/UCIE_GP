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

class mbtrain_tx_valvref extends state;
    local static mbtrain_tx_valvref inst = null;
    protected function new(); endfunction

    static function mbtrain_tx_valvref Instance();
        if (inst == null)
        inst = new();
        return inst;
    endfunction
endclass //mbtrain_tx_valvref extends state