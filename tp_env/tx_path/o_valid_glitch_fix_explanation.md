# o_valid Glitch Fix Explanation

## The Original Problem

```systemverilog
assign o_valid = w_venable && valid_pattern_reg[valid_counter];
```

This purely combinatorial assignment caused a **glitch/spike** on `o_valid` when `i_no_data` transitioned from low to high (data becomes invalid).

### Why the Glitch Occurred

1. When `i_no_data` goes high → `w_venable` transitions 1→0
2. Simultaneously, `valid_counter` resets to 15 (where `pattern_reg[15] = 1`)
3. Due to timing mismatches in combinatorial logic paths:
   - Both `w_venable` and `pattern_reg[15]` could briefly evaluate to `1`
   - This causes `o_valid` to momentarily spike high before settling to `0`

## The Solution: Hybrid Combinatorial + Registered Output

The fix uses a mux that selects between combinatorial and registered paths based on edge detection:

### New Signals Added

| Signal | Type | Purpose |
|--------|------|---------|
| `w_venable_q1` | Registered | 1-cycle delayed version of `w_venable` for edge detection |
| `o_valid_reg` | Registered | Glitch-free version of valid (but with 1-cycle latency) |
| `o_valid` | Combinatorial mux | Final output - selects between raw and registered |

### Implementation

```systemverilog
// Register w_venable for edge detection
always_ff @(posedge i_dclk or posedge i_reset) begin
    if (i_reset)
        w_venable_q1 <= 1'b0;
    else
        w_venable_q1 <= w_venable;
end

// Registered version (glitch-free)
always_ff @(posedge i_dclk or posedge i_reset) begin
    if (i_reset)
        o_valid_reg <= 1'b0;
    else
        o_valid_reg <= w_valid_raw;
end

// Zero-latency mux: combinatorial on rising edge, registered otherwise
assign o_valid = (w_venable && !w_venable_q1) ? w_valid_raw : o_valid_reg;
```

## How It Works

### Timing Diagram

```
        i_no_data:     ────────┐
                           │ data invalid
                           └───────────
                          
        w_venable:     ┌──────┐
                      │      │        
                      └──────┘
                      
    w_venable_q1:     ─ ┌────┐
                        │    │    
                        └────┘
                        
    Rising edge:       ───●─────── (detected when w_venable=1 AND w_venable_q1=0)
    
    o_valid source:    [RAW ][REG ]
    o_valid:           ┌────────┐
                      └────────┘
```

### State Machine

| Condition | `w_venable` | `w_venable_q1` | `o_valid` Source | Result |
|-----------|-------------|----------------|------------------|--------|
| Idle | 0 | 0 | Registered | Low |
| **Rising edge** | 0→1 | 0 | **Combinatorial** | **Immediate start** |
| Active | 1 | 1 | Registered | Stable, glitch-free |
| Falling edge | 1→0 | 1→0 | Registered | **Clean shutdown** |

### Key Insight

| Edge | Path | Benefit |
|------|------|---------|
| Rising (data becomes valid) | Combinatorial | **Zero latency** - `o_valid` responds immediately |
| Falling (data becomes invalid) | Registered | **Glitch-free** - registered path prevents spike |

## Trade-offs

| Approach | Latency | Glitch-free |
|----------|---------|-------------|
| Original (pure combinatorial) | None | ❌ No |
| Pure registered | 1 cycle | ✅ Yes |
| **Hybrid (this fix)** | **None** | **✅ Yes** |

This solution provides the best of both worlds: immediate response when data becomes valid, while ensuring a clean transition when data becomes invalid.
