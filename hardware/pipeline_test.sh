ghdl -a pipeline/pipe_constants.vhd general/alu.vhd
ghdl -a pipeline/pipe_fetch.vhd pipeline/pipe_decoder.vhd pipeline/pipe_reg_select.vhd
ghdl -a pipeline/pipe_write_back.vhd pipeline/pipe_execute.vhd pipeline/pipeline_collection.vhd
ghdl -a pipeline/pipeline_test.vhd
ghdl -e pipeTest
ghdl -r pipeTest --wave=pipeTest.ghw
gtkwave aluTest.gtkw