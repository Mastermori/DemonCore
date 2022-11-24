-- tlcWalk1.vhd
--
-- architecture	behave1		-single process RT-code
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

--entity tlcWalk is
--generic (	maxWalkC	: integer range 10 to 2000	:= 1000; 
--		maxCarC		: integer range 10 to maxWalkC	:=  800); 
--port    (	clk, rst	: in  std_logic;
--		reqWalk		: in  std_logic;
--		lightCar	: out std_logic_vector(1 to 3);
--		lightWalk	: out std_logic_vector(1 to 2));
--end entity tlcWalk;

architecture behave1 of tlcWalk is
begin
  fsmP: process (clk, rst) is
    type stateTy is (Gr, Yr, Rr, Rg, RYr);
    variable	cnt		: integer range 0 to maxWalkC;
    variable	state		: stateTy;
    variable	request		: boolean;
  begin
    if rst = '0'	then	state := Gr;
				cnt   := 0;
				request   := false;
				lightCar  <= "001";
				lightWalk <= "10";
    elsif rising_edge(clk) then
	case state is
	when Gr =>		lightCar  <= "001";
		if    (reqWalk = '1')	then	request := true;
		end if;
		if    (cnt > 0)		then	cnt   := cnt - 1;
		elsif request		then	state := Yr;
		end if;
	when Yr =>		lightCar  <= "010";
				cnt   := maxWalkC-1;		-- 999
				state := Rr;
	when Rr =>		lightCar  <= "100";
				lightWalk <= "10";
		if request		then	state := Rg;
					else	state := RYr;
		end if;
	when Rg =>		lightWalk <= "01";
				request    := false;
		if (cnt > 0)		then	cnt   := cnt - 1;
					else	state := Rr;
		end if;
	when RYr =>		lightCar <= "110";
				cnt   := maxCarC-1;		-- 799
				state := Gr;
	end case;
    end if;
  end process fsmP;
end architecture behave1;
