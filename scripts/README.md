# Flow Scripts

The scripts here document the synthesis, Sky130 mapping, and OpenSTA constraint flow used in the project.

`sta_run.tcl` is the constraint flow that was successfully used after the direct `read_sdc` workaround.
`crypto_core.sdc` records the same clock, I/O delay, and reset false-path constraints in SDC form.

The mapping scripts are included as a reproducible representation of the recorded flow. Because the raw Ubuntu shell scripts were not directly exported into this chat, treat these files as reconstructed flow scripts rather than byte-for-byte copies of the VM files.
