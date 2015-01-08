Before you can build the design, run make copy-none or copy-<application> in
the examples dir. This will generate a vhdl file containing the memory which
the core should be initialized with. If you initialize with an application, be
aware that static elaboration time will explode; ISE may seem to hang for up to
a couple minutes.

Use ISE 14.7 to synthesize. 13.4 at least messes it up (it doesn't crash and
the design seems to work, but fails miserably when stalls are involved).