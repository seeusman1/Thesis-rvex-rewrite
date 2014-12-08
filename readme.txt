This will be the new rvex core, version 3 if I'm not mistaken.

The core files are mostly done. Documentation/specifications are in the code.
In particular, there is a big section at the top of rvex.vhd (the toplevel
entity) with general information. There's also documentation about the pipeline
stages and latencies in rvex_pipeline_pkg.vhd, and information on how the
configurable pipelane code works in rvex_pipelane.vhd.

I will eventually also make a PDF with more general information.

Currently working on the VHDL unit test runner and test cases for it, while
debugging the core at the same time. After that's done I'll first focus on
getting a standalone version of the core working on the ML605, followed by the
cached version with the new cache I wrote earlier.

Internal interfaces in the core files are still slightly in flux due to
bugfixing, but the general layout of the files should not change anymore. The
toplevel interface can be considered frozen at this point.
