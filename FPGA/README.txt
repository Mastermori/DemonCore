README.txt	ajm						15-dec-2022
-de0-mikrorechner.tgz	templates for 'Mikrorechner Projekt'
			32-bit pipelining processor
--------------------------------------------------------------------------------

Makefile	-non graphical compilation and programming
de0Board.vhd	-top level wrapper for pipeProc		noIO / cDisp
de0Board.qpf	-files for Quartus
de0Board.qsf	-					noIO / cDisp
de0Board.sdc	-
quartus2.ini	-search path for external EDA programs, adapt to $tamsSW/...

doc/		-additional datasheets: DE0-board, PCB devices, etc.

cDisplay/cDisp14x6.vhd	-display controller FSM
cDisplay/cDispPkg.vhd	-component: cDisp14x6, pllClk   type: cmdTy
		=> for external use
		components and types used in cDisp14x6
cDisplay/pll/	-pll to generate 2MHz clocks from 50MHz input on DE0-board
		 must be used within de0Board.vhd, see example
cDisplay/rom/	-character ROM for cDisp14x6
		 internally used in cDisp14x6

memory/		-rom10x32	instruction memory	-edit rom10x32.mif !
		 ram10x32	data memory		-edit ram10x32.mif !

src/		-... VHDL design sources

sim/ghdl/	-ghdl simulation (hdl + net)
sim/hdl/	-sim. directory (xmsim) - pre-synthesis
sim/net/	-sim. directory (xmsim) - for Quartus netlist from xcelium
sim/xcelium/	-Quartus generated VHDL (Verilog) netlists for simulation

qProgram/	-saved programming files from prev. runs
qOutput/	-Quartus generated output: reports, programming (de0Board.sof)
		 deleted by Makefile

TO DO		----------------------------------------------------------------
		0. use: memorySim.tgz		>tar xzf memorySim.tgz
			move files to src	>mv memorySim/* src/
		1. add processor VHDL files to src/
		2. edit 'src/procPkg.vhd' to match files
		3. simulate processor in sim/hdl
		4. edit 'de0Board.vhd' (samples in src)
		5. edit memory content
		   'memory/rom10x32.mif' + 'memory/rom10x32.mif'
		6. edit 'de0Board.qsf' (samples in src)
		7. start 'quartus de0Board'
		   add references to new VHDL files in src
		   run design synthesis
		8. simulate quartus generated netlist in sim/net

Where to start the tools?
--------------------------------------------------------------------------------
de0Board          synthesis working directory:  quartus
de0Board/sim/hdl  pre-synthesis simulation:     xmvhdl / xmelab / xmsim
de0Board/sim/net  netlist simulation:           xmvlog / xmvhdl / xmelab / xmsim
--------------------------------------------------------------------------------
README.txt - end
