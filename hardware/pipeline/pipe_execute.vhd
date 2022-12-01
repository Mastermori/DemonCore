LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;
USE WORK.alu.all;


ENTITY pipe_execute IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        data_1, data_2 : IN word;
        immediate : IN signed(11 DOWNTO 0);
        upper_immediate : IN signed(19 DOWNTO 0);

        alu_enable : IN std_logic;
        add_sub_alu_code : IN STD_LOGIC;

        result : OUT std_logic_vector(31 DOWNTO 0);

        -- Durchreiche Werte
        pc : IN unsigned(31 DOWNTO 0);
        pc_4 : IN unsigned(31 DOWNTO 0);
        reg_pc : OUT unsigned(31 DOWNTO 0);
        reg_pc_4 : OUT unsigned(31 DOWNTO 0)
    );
END;

architecture pipe_execute_simple of pipe_execute is
    signal alu_result : signedNumer;
begin
    alu_inst: entity work.alu(alu_simple)
        port map (
          vec1   => data_1,
          vec2   => data_2,
          opCode => add_sub_alu_code,
          outVec => alu_result
        );

    alu_proc: process (clk, reset) is
    begin
        result <= alu_result;
    end process;
end architecture;