-- reg.vhd					AJM : 25.11.2002
--
-- entity	reg	-parametrisable register
-- architecture	behavior
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is
generic( width	: integer range 2 to 64);
port	 ( clk		: in std_logic;
	   dIn		: in  signed(width-1 downto 0);
	   dOut		: out signed(width-1 downto 0));
end entity reg;

architecture behavior of reg is
begin
  reg_P: process (clk) is
  begin
    if rising_edge(clk) then dOut <= dIn;
    end if;
  end process reg_P;
end architecture behavior;
