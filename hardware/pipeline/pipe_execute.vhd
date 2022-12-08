LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;
USE WORK.alu;

ENTITY pipe_execute IS
    PORT(
        clk              : IN  STD_LOGIC;
        reset            : IN  STD_LOGIC;
        data_1, data_2   : IN  signed;
        immediate        : IN  signed(31 DOWNTO 0);
        upper_immediate  : IN  signed(31 DOWNTO 0);
        alu_enable       : IN  std_logic;
        add_sub_alu_code : IN  STD_LOGIC;
        
        result           : OUT signed(31 DOWNTO 0);
        
        e_in_pc          : IN  unsigned(31 DOWNTO 0);
        e_out_pc         : OUT unsigned(31 DOWNTO 0)
    );
END;

architecture pipe_execute_simple of pipe_execute is
    signal alu_result             : signedNumber;
begin

    alu_inst : entity work.alu(alu_simple)
        port map(
            vec1   => data_1,
            vec2   => data_2,
            opCode => add_sub_alu_code,
            outVec => alu_result
        );

    alu_proc : process(clk, reset) is
    begin
        if (reset = '0') then
            result <= x"0000_0000";
            e_out_pc <= x"0000_0000";
        elsif (rising_edge(clk)) then
            result   <= alu_result;
            e_out_pc <= e_in_pc;
        end if;
    end process;
end architecture;
