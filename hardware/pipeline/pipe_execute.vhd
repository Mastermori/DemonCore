LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;


ENTITY pipe_execute IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        reg_addr_1, reg_addr_2, reg_addr_dest : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        control_enables : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        register_read : OUT STD_LOGIC;
        immediate : OUT signed(31 DOWNTO 0);
        upper_immediate : OUT signed(31 DOWNTO 0);

        -- Durchreiche Werte
        pc : IN unsigned(31 DOWNTO 0);
        pc_4 : IN unsigned(31 DOWNTO 0);
        reg_pc : OUT unsigned(31 DOWNTO 0);
        reg_pc_4 : OUT unsigned(31 DOWNTO 0)
    );
END;