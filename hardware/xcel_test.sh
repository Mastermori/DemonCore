xmvhdl -linedebug memorySim/memPkg.vhd memorySim/ramIO.vhd memorySim/rom.vhd
xmvhdl -linedebug pipeline/pipe_constants.vhd general/alu.vhd
xmvhdl -linedebug pipeline/pipe_fetch.vhd 
xmvhdl -linedebug pipeline/pipe_decoder.vhd pipeline/pipe_reg_select.vhd pipeline/pipe_execute.vhd
xmvhdl -linedebug pipeline/pipe_memory.vhd pipeline/pipe_write_back.vhd
xmvhdl -linedebug pipeline/pipeline_collection.vhd 
xmvhdl -linedebug pipeline/pipeline_test.vhd
xmelab pipeTest
xmsim -gui pipeTest
gtkwave pipeTest.ghw