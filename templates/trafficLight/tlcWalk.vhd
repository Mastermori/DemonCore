-- tlcWalk.vhd
--
-- entity	tlcWalk		-traffic-light controller
-- architecture	behave		-multiple process RT-code
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity tlcWalk is
generic (	maxWalkC	: integer range 10 to 2000	:= 1000; 
		maxCarC		: integer range 10 to 2000	:=  800); 
port    (	clk, rst	: in  std_logic;
		reqWalk		: in  std_logic;
		lightCar	: out std_logic_vector(1 to 3);
		lightWalk	: out std_logic_vector(1 to 2));
end entity tlcWalk;

architecture behave of tlcWalk is
  type stateTy is (Gr, Yr, Rr, Rg, RYr);
  signal	cnt		: integer range 0 to maxWalkC;
  signal	request		: boolean;
  signal	curSt, nextSt	: stateTy;
begin
  fsmL_P: process (curSt, cnt, request) is
  begin
    nextSt	<= curSt;
    lightCar	<= "100";
    lightWalk	<= "10";

    case curSt is
    when Gr =>	lightCar <= "001";
		if (cnt = 0) and request then	nextSt <= Yr;
		end if;
    when Yr =>	lightCar <= "010";
		nextSt   <= Rr;
    when Rr =>	if request	then		nextSt <= Rg;
				else		nextSt <= RYr;
		end if;
    when Rg =>	lightWalk <= "01";
		if (cnt = 0)	then		nextSt <= Rr;
		end if;
    when RYr =>	lightCar <= "110";
		nextSt   <= Gr;
    end case;
  end process fsmL_P;

  fsmR_P: process (clk,rst) is
  begin
    if rst = '0'		then curSt <= Gr;
    elsif rising_edge(clk)	then curSt <= nextSt;
    end if;
  end process fsmR_P;

  cntP: process (clk, rst) is
  begin
    if rst = '0'	then	cnt <= 0;
    elsif falling_edge(clk) then	--'event and clk = '0' then
      case curSt is
	when Yr		=>	cnt <= maxWalkC;
	when RYr	=>	cnt <= maxCarC;
	when Rr		=>	null;
	when Gr | Rg	=>	if cnt > 0	then	cnt <= cnt - 1;
				end if;
      end case;
    end if;
  end process cntP;

  reqP: process (clk, rst) is
  begin
    if rst = '0'	then	request <= false;
    elsif falling_edge(clk) then	--'event and clk = '0' then
      case curSt is
	when Gr		=>  if reqWalk = '1' then
				request <= true;
			    end if;
	when rG		=>	request <= false;
	when others	=>	null;
      end case;
    end if;
  end process reqP;
end architecture behave;
