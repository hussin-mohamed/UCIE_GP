# TX Verification Branch

This branch is dedicated to the verification of the **UCIe Transmitter (TX)**.

## Contributors
*   **Youssef Gamal**
*   **Abdelrahaman Mohamed**

## Collaboration Rules & Best Practices

To avoid merge conflicts and ensure a smooth workflow, please adhere to the following rules:

1.  **Sync Daily:** Before you write a single line of code for the day, **always pull** the latest changes.
    *   Command: `git pull origin tx_verification`
2.  **Communicate Shared Files:** If you are planning to modify a shared file (e.g., a package file `tx_pkg.sv` or the environment `tx_env.sv`), notify the other person immediately.
3.  **Frequency:** Commit and push your work frequently. Small, frequent updates are much easier to manage than large, infrequent ones.
    *   Commands: 
        *   `git add .`
        *   `git commit -m "Brief description of changes"`
        *   `git push origin tx_verification`
4.  **Instant Notification:** After pushing changes to a shared file, let the other person know so they can pull the updates right away.

---

## Handling Merge Conflicts

If you see a "CONFLICT" message when pulling or pushing, don't panic. Follow these steps:

### 1. Identify the Conflict
Git will tell you which files have conflicts. Open those files and look for the conflict markers:
```text
<<<<<<< HEAD
(Your changes)
=======
(Changes from the remote branch)
>>>>>>> origin/tx_verification
```

### 2. Resolve Manually
Decide which code to keep (or combine both). Remove the `<<<<<<<`, `=======`, and `>>>>>>>` markers.

### 3. Finalize the Resolution
Once the file is fixed, run the following commands:
1.  **Add the resolved file:** `git add <file_name>`
2.  **Commit the merge:** `git commit -m "Fixed merge conflict in <file_name>"`
3.  **Push the fix:** `git push origin tx_verification`

### Pro-Tip: Safe Pulling
If you have local changes and want to pull safely, you can use:
`git pull --rebase origin tx_verification`
This keeps the commit history linear and often makes conflicts easier to manage.
