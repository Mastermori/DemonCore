-- ramIO.vhd		------------------------------------------------------
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
-- entity		ramIO		-RAM	separate input/output buses
-- architecture		simModel
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- ramIO		------------------------------------------------------
------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;

USE std.textio.ALL;
USE work.memPkg.ALL;

ENTITY ramIO IS
	GENERIC (
		addrWd : INTEGER RANGE 2 TO 16 := 8; -- #address bits
		dataWd : INTEGER RANGE 2 TO 32 := 8; -- #data    bits
		fileId : STRING := "memory.dat"); -- filename
	PORT (--	nCS	: in    std_logic;		-- not Chip   Select
		nWE : IN STD_LOGIC; -- not Write  Enable
		addr : IN STD_LOGIC_VECTOR(addrWd - 1 DOWNTO 0);
		dataI : IN STD_LOGIC_VECTOR(dataWd - 1 DOWNTO 0);
		dataO : OUT STD_LOGIC_VECTOR(dataWd - 1 DOWNTO 0);
		fileIO : IN fileIoT := none);
END ENTITY ramIO;

-- ramIO(simModel)	------------------------------------------------------
------------------------------------------------------------------------------
ARCHITECTURE simModel OF ramIO IS
	CONSTANT addrHi : NATURAL := (2 ** addrWd) - 1;
	SUBTYPE memEleT IS STD_LOGIC_VECTOR(dataWd - 1 DOWNTO 0);
	TYPE memArrT IS ARRAY (0 TO addrHi) OF memEleT;

	SIGNAL memory : memArrT; -- memory content
BEGIN

	-- mem		simulation model
	----------------------------------------------------------------------------
	--memP: process (nCS, nWE, addr, dataI, fileIO) is
	memP : PROCESS (nWE, addr, dataI, fileIO) IS
		FILE ioFile : text; -- used for file I/O
		VARIABLE ioLine : line; --
		VARIABLE ioStat : file_open_status; --
		VARIABLE rdStat : BOOLEAN; --
		VARIABLE ioAddr : INTEGER RANGE memory'RANGE;
		VARIABLE ioData : STD_LOGIC_VECTOR(dataWd - 1 DOWNTO 0);
	BEGIN
		-- fileIO	dump/load memory content into/from file
		--------------------------------------------------------------------------
		IF fileIO'event THEN
			IF fileIO = dump THEN --  dump memory array	----------------------
				file_open(ioStat, ioFile, fileID, write_mode);
				ASSERT ioStat = open_ok
				REPORT "ramIO - dump: error opening data file"
					SEVERITY error;
				FOR dAddr IN memory'RANGE LOOP
					write(ioLine, dAddr); -- format line:
					write(ioLine, ' '); --   <addr> <data>
					write(ioLine, STD_LOGIC_VECTOR(memory(dAddr)));
					writeline(ioFile, ioLine); -- write line
				END LOOP;
				file_close(ioFile);

			ELSIF fileIO = load THEN --  load memory array	----------------------
				file_open(ioStat, ioFile, fileID, read_mode);
				ASSERT ioStat = open_ok
				REPORT "ramIO - load: error opening data file"
					SEVERITY error;
				WHILE NOT endfile(ioFile) LOOP
					readline(ioFile, ioLine); -- read line
					read(ioLine, ioAddr, rdStat); -- read <addr>
					IF rdStat THEN --      <data>
						read(ioLine, ioData, rdStat);
					END IF;
					IF rdStat THEN
						memory(ioAddr) <= ioData;
					ELSE
						REPORT "ramIO - load: format error in data file"
							SEVERITY error;
					END IF;
				END LOOP;
				file_close(ioFile);
			END IF; -- fileIO = ...
		END IF; -- fileIO'event

		-- consistency checks: inputs without X, no timing!
		------------------------------------------------------------------------
		--  if nCS'event  then	assert not Is_X(nCS)
		--			  report "ramIO: nCS - X value"
		--			  severity warning;
		--  end if;
		IF nWE'event THEN
			ASSERT NOT Is_X(nWE)
			REPORT "ramIO: nWE - X value"
				SEVERITY warning;
		END IF;
		IF addr'event THEN
			ASSERT NOT Is_X(addr)
			REPORT "ramIO: addr - X value"
				SEVERITY warning;
		END IF;
		IF dataI'event THEN
			ASSERT NOT Is_X(dataI)
			REPORT "ramIO: dataI - X value"
				SEVERITY warning;
		END IF;

		-- here starts the real work...
		------------------------------------------------------------------------
		--  if nCS = '0'	then				-- chip select
		IF nWE = '0' THEN -- +write cycle
			memory(to_integer(unsigned(addr))) <= dataI;
			dataO <= dataI;
		ELSE -- +read cycle
			dataO <= memory(to_integer(unsigned(addr)));
		END IF; -- nWE = ...
		--  end if;	-- nCS = '0'

	END PROCESS memP;

END ARCHITECTURE simModel;

------------------------------------------------------------------------------