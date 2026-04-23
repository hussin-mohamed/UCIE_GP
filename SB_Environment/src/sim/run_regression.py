#!/usr/bin/env python3

import os
import subprocess
import random
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

# ===============================================================================
# REGRESSION CONFIGURATION
# ===============================================================================
TESTS = [
    "sb_sendall_test", 
    "sb_rand_test", 
    "sb_conc_test"
]

RUNS_PER_TEST = 10      # Number of unique seeds to run per test
SIMULATOR     = "questa"

# ===============================================================================

def run_single_test(test_name, run_idx):
    """Executes a single make command letting the simulator pick the seed."""
    
    # Construct the make command. SEED is set to random, but RUN_ID keeps files unique.
    cmd = [
        "make", "run", 
        f"SIM={SIMULATOR}", 
        f"TEST={test_name}", 
        f"SEED=random", 
        f"RUN_ID={run_idx}", 
        "GUI=0",
        "VERBOSITY=UVM_NONE"
    ]
    
    start_time = time.time()
    
    # Execute the command and capture the terminal output
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        make_output = result.stdout
    except subprocess.CalledProcessError as e:
        make_output = e.stdout
        
    duration = int(time.time() - start_time)

    # Extract the unique log file path from the Makefile's output
    log_match = re.search(r"Log:\s+(out/logs/\S+\.log)", make_output)
    log_file = log_match.group(1) if log_match else "UNKNOWN_LOG"

    # Parse the Questa/UVM log to determine PASS/FAIL and extract the actual seed
    status = "FAIL"
    actual_seed = "UNKNOWN"
    
    if os.path.exists(log_file):
        with open(log_file, "r") as f:
            log_content = f.read()
            
            # 1. Extract Simulator-generated Seed
            seed_match = re.search(r"(?:sv_seed|Seed)\s*[=:]\s*(\d+)", log_content, re.IGNORECASE)
            if seed_match:
                actual_seed = seed_match.group(1)
            
            # 2. Check Pass/Fail Status
            # A test passes IF it reached the end of the UVM run_test phase naturally...
            if "uvm_root::run_test" in log_content or "$finish" in log_content:
                status = "PASS"
                
                # ...AND there are no logged UVM_ERRORs or UVM_FATALs.
                # (The negative lookahead ignores the string "UVM_ERROR : 0" for backward compatibility)
                if re.search(r"UVM_ERROR(?![\s:]*0\b)", log_content):
                    status = "FAIL"
                    
                if re.search(r"UVM_FATAL(?![\s:]*0\b)", log_content):
                    status = "FAIL"
                    if "timeout" in log_content.lower():
                        status = "TIMEOUT"
                
    return {
        "test": test_name,
        "run_idx": run_idx,
        "seed": actual_seed,
        "status": status,
        "duration": duration,
        "log": log_file
    }

def main():
    print("==========================================================")
    print(" Starting UVM Regression Tracker")
    print(f" Tests queued  : {len(TESTS)}")
    print(f" Runs per test : {RUNS_PER_TEST}")
    print(f" Total jobs    : {len(TESTS) * RUNS_PER_TEST}")
    print("==========================================================\n")

    print(" Cleaning previous output artifacts...")
    subprocess.run(["make", "clean"], check=False)
    subprocess.run(["make", "cleanout"], check=False)
    print(" Starting tests...\n")

    # Create the job list
    jobs = []
    for test in TESTS:
        for i in range(1, RUNS_PER_TEST + 1):
            jobs.append((test, i))

    results = []
    
    # Run tests sequentially
    for t, idx in jobs:
        res = run_single_test(t, idx)
        results.append(res)
        
        # Print live progress to the terminal
        status_color = "\033[92mPASS\033[0m" if res["status"] == "PASS" else "\033[91m" + res["status"] + "\033[0m"
        print(f"[{status_color}] {res['test']} (Run {res['run_idx']}/{RUNS_PER_TEST}) | Seed: {res['seed']} | Time: {res['duration']}s")

    # ===============================================================================
    # POST-REGRESSION SUMMARY & COVERAGE MERGE
    # ===============================================================================
    print("\n==========================================================")
    print(" Regression Execution Complete. Merging Coverage...")
    print("==========================================================")
    
    # Trigger the Makefile target you just created to merge the UCDBs
    subprocess.run(["make", "merge_cov"], check=False)

    print("\n==========================================================")
    print(" REGRESSION SUMMARY REPORT")
    print("==========================================================")
    print(f"{'TEST NAME':<20} | {'SEED':<12} | {'STATUS':<8} | {'TIME(s)':<7} | {'LOG FILE'}")
    print("-" * 80)
    
    # Sort results by test name, then by run index for a clean table
    results.sort(key=lambda x: (x["test"], x["run_idx"]))
    
    total_passed = 0
    for r in results:
        if r["status"] == "PASS":
            total_passed += 1
            
        print(f"{r['test']:<20} | {r['seed']:<12} | {r['status']:<8} | {r['duration']:<7} | {r['log']}")
        
    print("-" * 80)
    print(f" TOTAL PASS RATE: {total_passed} / {len(results)} ({(total_passed/len(results))*100:.1f}%)")
    print("==========================================================\n")

if __name__ == "__main__":
    main()