ghdl -a -fsynopsys memorySim/memPkg.vhd memorySim/ramIO.vhd memorySim/rom.vhd
ghdl -a -fsynopsys pipeline/pipe_constants.vhd general/alu.vhd
ghdl -a -fsynopsys pipeline/pipe_fetch.vhd 
ghdl -a -fsynopsys pipeline/pipe_decoder.vhd pipeline/pipe_reg_select.vhd pipeline/pipe_execute.vhd
ghdl -a -fsynopsys pipeline/pipe_memory.vhd pipeline/pipe_write_back.vhd
ghdl -a -fsynopsys pipeline/pipeline_collection.vhd 
ghdl -a -fsynopsys pipeline/pipeline_test.vhd
ghdl -e -fsynopsys pipeTest
ghdl -r -fsynopsys pipeTest --wave=pipeTest.ghw
gtkwave pipeTest.ghw