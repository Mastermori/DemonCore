library IEEE;
use IEEE.std_logic_1164.all;

entity MEALY is				-- Mealy machine
port (	X, CLOCK			: in  STD_LOGIC;
	Z				: out STD_LOGIC);
end entity MEALY;

architecture BEHAVIOR of MEALY is
  type   STATE_TYPE is (S0, S1, S2, S3);
  signal CURRENT_STATE, NEXT_STATE	: STATE_TYPE;
begin

  -- Process to hold combinational logic
  -- NEXT_STATE <= f(CURRENT_STATE, X)
  --          Z <= f(CURRENT_STATE, X)	-- MEALY
  -------------------------------------------------------------------
  COMBIN: process (CURRENT_STATE, X) is
  begin
    case CURRENT_STATE is
      when S0 =>  if X = '0' then	Z <= '0';
					NEXT_STATE <= S0;
		  elsif X = '1' then	Z <= '1';
					NEXT_STATE <= S2;
		  else			Z <= 'U';
					NEXT_STATE <= S0;
		  end if;
      when S1 =>  if X = '0' then	Z <= '0';
					NEXT_STATE <= S0;
		  elsif X = '1' then	Z <= '0';
					NEXT_STATE <= S2;
		  else			Z <= 'U';
					NEXT_STATE <= S0;
		  end if;
      when S2 =>  if X = '0' then	Z <= '1';
					NEXT_STATE <= S2;
		  elsif X = '1' then	Z <= '0';
					NEXT_STATE <= S3;
		  else			Z <= 'U';
					NEXT_STATE <= S0;
		  end if;
      when S3 =>  if X = '0' then	Z <= '0';
					NEXT_STATE <= S3;
		  elsif X = '1' then	Z <= '1';
					NEXT_STATE <= S1;
		  else			Z <= 'U';
					NEXT_STATE <= S0;
		  end if;
    end case;
  end process COMBIN;
 
  -- Process to hold synchronous elements (flip-flops)
  -------------------------------------------------------------------
  SYNCH: process (CLOCK) is
  begin
    if rising_edge(CLOCK) then		CURRENT_STATE <= NEXT_STATE;
    end if;
  end process SYNCH;
end architecture BEHAVIOR;

