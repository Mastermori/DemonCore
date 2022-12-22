-- memPkg.vhd		------------------------------------------------------
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
-- package		memPkg		-ramB / ramIO / rom
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- memPkg		------------------------------------------------------
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
package memPkg is
  type fileIoT	is (none, dump, load);

  component ramB is
  generic (	addrWd	: integer range 2 to 16	:= 8;	-- #address bits
		dataWd	: integer range 2 to 32	:= 8;	-- #data    bits
		fileId	: string  := "memory.dat");	-- filename
  port (--	nCS	: in    std_logic;		-- not Chip   Select
		nWE	: in    std_logic;		-- not Write  Enable
		nOE	: in    std_logic;		-- not Output Enable
	        addr	: in    std_logic_vector(addrWd-1 downto 0);
	        data	: inout std_logic_vector(dataWd-1 downto 0);
	        fileIO	: in	fileIoT	:= none);
  end component ramB;

  component ramIO is
  generic (	addrWd	: integer range 2 to 16	:= 8;	-- #address bits
		dataWd	: integer range 2 to 32	:= 8;	-- #data    bits
		fileId	: string  := "memory.dat");	-- filename
  port (--	nCS	: in    std_logic;		-- not Chip   Select
		nWE	: in    std_logic;		-- not Write  Enable
	        addr	: in    std_logic_vector(addrWd-1 downto 0);
	        dataI	: in	std_logic_vector(dataWd-1 downto 0);
	        dataO	: out	std_logic_vector(dataWd-1 downto 0);
	        fileIO	: in	fileIoT	:= none);
  end component ramIO;

  component rom is
  generic (	addrWd	: integer range 2 to 16	:= 8;	-- #address bits
		dataWd	: integer range 2 to 32	:= 8;	-- #data    bits
		fileId	: string  := "memory.dat");	-- filename
  port (--	nCS	: in    std_logic;		-- not Chip   Select
	        addr	: in    std_logic_vector(addrWd-1 downto 0);
	        data	: out	std_logic_vector(dataWd-1 downto 0);
	        fileIO	: in	fileIoT	:= none);
  end component rom;
end package memPkg;

------------------------------------------------------------------------------
-- memPkg.vhd - end	------------------------------------------------------
