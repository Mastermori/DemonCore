ghdl -a pipeline/pipe_constants.vhd general/alu.vhd
ghdl -a --ieee=synopsys pipeline/pipe_fetch.vhd 
ghdl -a pipeline/pipe_decoder.vhd pipeline/pipe_reg_select.vhd pipeline/pipe_execute.vhd
ghdl -a pipeline/pipe_memory.vhd pipeline/pipe_write_back.vhd pipeline/pipeline_collection.vhd 
ghdl -a pipeline/pipeline_test.vhd
ghdl -e pipeTest
ghdl -r pipeTest --wave=pipeTest.ghw
gtkwave pipeTest.ghw