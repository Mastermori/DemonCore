LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pipe_fetch IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        vec_in : IN unsigned;
        vec_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END;