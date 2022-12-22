-- ramB.vhd		------------------------------------------------------
------------------------------------------------------------------------------
-- Andreas Maeder	01-feb-2007
--			-simulation models of simple RAM / ROM
--			-no timing !!
--
-- parameters		addrWd		-address width	2..16 [8]
--					 was 32 => vhdl overflow: 2**32 -1
--			dataWd		-data with	2..32 [8]
--			fileID		-filename	[memory.dat]
--
-- entity		ramB		-RAM	bidir/tristate data-bus
-- architecture		simModel
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- ramB			------------------------------------------------------
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;
use work.memPkg.all;

entity ramB is
generic (	addrWd	: integer range 2 to 16	:= 8;	-- #address bits
		dataWd	: integer range 2 to 32	:= 8;	-- #data    bits
		fileId	: string  := "memory.dat");	-- filename
port (--	nCS	: in    std_logic;		-- not Chip   Select
		nWE	: in    std_logic;		-- not Write  Enable
		nOE	: in    std_logic;		-- not Output Enable
	        addr	: in    std_logic_vector(addrWd-1 downto 0);
	        data	: inout	std_logic_vector(dataWd-1 downto 0);
	        fileIO	: in	fileIoT	:= none);
end entity ramB;

-- ramB(simModel)	------------------------------------------------------
------------------------------------------------------------------------------
architecture simModel of ramB is
begin

  -- mem		simulation model
  ----------------------------------------------------------------------------
--memP: process (nCS, nWE, nOE, addr, data, fileIO) is
  memP: process (nWE, nOE, addr, data, fileIO) is
    constant	addrHi		: natural	:= (2**addrWd)-1;

    subtype	memEleT		is std_logic_vector(dataWd-1 downto 0);
    type	memArrT		is array (0 to addrHi) of memEleT;

    variable	memory		:  memArrT;		-- memory content

    file	ioFile		: text;			-- used for file I/O
    variable	ioLine		: line;			--
    variable	ioStat		: file_open_status;	--
    variable	rdStat		: boolean;		--
    variable	ioAddr		: integer range memory'range;
    variable	ioData		: std_logic_vector(dataWd-1 downto 0);
  begin
    -- fileIO	dump/load memory content into/from file
    --------------------------------------------------------------------------
    if fileIO'event then
      if fileIO = dump	then	--  dump memory array	----------------------
	file_open(ioStat, ioFile, fileID, write_mode);
	assert ioStat = open_ok
	  report "ramB - dump: error opening data file"
	  severity error;
	for dAddr in memory'range loop
	  write(ioLine, dAddr);				-- format line:
	  write(ioLine, ' ');				--   <addr> <data>
	  write(ioLine, std_logic_vector(memory(dAddr)));
	  writeline(ioFile, ioLine);			-- write line
	end loop;
	file_close(ioFile);

      elsif fileIO = load then	--  load memory array	----------------------
	file_open(ioStat, ioFile, fileID, read_mode);
	assert ioStat = open_ok
	  report "ramB - load: error opening data file"
	  severity error;
	while not endfile(ioFile) loop
	  readline(ioFile, ioLine);			-- read line
	  read(ioLine, ioAddr, rdStat);			-- read <addr>
	  if rdStat then				--      <data>
	    read(ioLine, ioData, rdStat);
	  end if;
	  if rdStat then
	    memory(ioAddr) := ioData;
	  else
	    report "ramB - load: format error in data file"
	    severity error;
	  end if;
	end loop;
	file_close(ioFile);
      end if;	-- fileIO = ...
    end if;	-- fileIO'event

    -- consistency checks: inputs without X, no timing!
    ------------------------------------------------------------------------
--  if nCS'event  then	assert not Is_X(nCS)
--			  report "ramB: nCS - X value"
--			  severity warning;
--  end if;
    if nWE'event  then	assert not Is_X(nWE)
			  report "ramB: nWE - X value"
			  severity warning;
    end if;
    if nOE'event  then	assert not Is_X(nOE)
			  report "ramB: nOE - X value"
			  severity warning;
    end if;
    if addr'event then	assert not Is_X(addr)
			  report "ramB: addr - X value"
			  severity warning;
    end if;
--  if data'event then	assert not Is_X(data)
--			  report "ramB: data - X value"
--			  severity warning;
--  end if;

    -- here starts the real work...
    ------------------------------------------------------------------------
    data <= (others => 'Z');				-- output disabled

--  if nCS = '0'	then				-- chip select
      if nWE = '0'	then				-- +write cycle
	memory(to_integer(unsigned(addr))) := data;

      elsif nWE = '1' and nOE ='0' then			-- +read cycle
	data <= memory(to_integer(unsigned(addr)));
      end if;	-- nWE = ...
--  end if;	-- nCS = '0'

  end process memP;

end architecture simModel;

------------------------------------------------------------------------------
-- ramB.vhd - end	------------------------------------------------------
