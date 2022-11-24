-- README.txt		ajm	17-apr-2020
--
-- files		-------------------------------------------------------
-------------------------------------------------------------------------------
delayLine		-Delay line example from "introVHDL.pdf"
  reg.vhd		-Register
  delayLine.vhd		-Delay line
  dlTest.vhd		-Testbench

fsm-examples		-Finite-state machines in VHDL
  mealy.vhd		-Mealy model
  moore.vhd		-Moore model

trafficLight		-Traffic light example
  tlcFSM.pdf		-State transition diagram
  tlcWalk.vhd		-Mealy-fsm			multiple processes
  tlcWalk1.vhd		-Mealy-fsm + output registers	single process
  tlcTest.vhd		-Testbench
  tlcDiff.vhd		-Testbench comparing both models
  light.sv		-Mnemonic map for simulation

templates		-setup simulation and FPGA design
  cds.lib + hdl.var	-files needed for Cadence VHDL Simulator


-- directory layout	-------------------------------------------------------
-------------------------------------------------------------------------------
General			-make subdirectory for project/design	<designDir>
			-place all VHDL files there		<design*>.vhd

VHDL simulation		-place cds.lib and hdl.var in <designDir>
			-make subdirectory "work"

<designDir>/
	+-- <design1>.vhd
	+-- <design2>.vhd
	+-- ...
	+-- cds.lib
	+-- hdl.var
	+-- work/


-- EDA-tool setup	-------------------------------------------------------
-------------------------------------------------------------------------------
1. open terminal with shell, go to <designDir>

2. sh/bash users				--------------------------
	>source $tamsSW/profile.d/edaSetup.sh	--interactive setup script
						  ldv	->VHDL simulation
						  alt	->FPGA design

   csh/tcsh users				--------------------------
	>source $tamsSW/profile.d/edaSetup.csh	--interactive setup script
						  s.o.	ldv / alt

3. start EDA-toolchain				--------------------------
	>xmvhdl -linedebug <srcFile1> <...n>	->VHDL simulation
	>xmelab <testbench>
	>xmsim -gui <testbench>

	>quartus				->FPGA design

-------------------------------------------------------------------------------
-- README.txt -- end
