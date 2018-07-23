---
name: Bug report
about: Create a report to help us improve

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior.

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Version info (please complete the following information):**
 - include the output of `versioninfo()` and `Pkg.status()`
 - how are you deploying the widgets? Jupyter Notebook/Lab, Juno, Blink or Mux?

**Before opening an issue**
- make sure you are on the latest release of InteractBase and try rebuilding it with `Pkg.build("InteractBase")`

**If widgets do not appear**
 - test that your WebIO is correctly installed. Make sure you're on latest release and rebuild it with `Pkg.build("WebIO")`
- try a simple code to produce a slider: `using WebIO; display(Node(:input, attributes = Dict("type" => "range")))`
- if this doesn't produce a slider, your WebIO is not installed correctly and you may wish to open an issue at WebIO rather than here,
