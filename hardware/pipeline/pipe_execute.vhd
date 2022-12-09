LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.pipe_constants.ALL;
USE WORK.alu;

ENTITY pipe_execute IS
    PORT(
        clk                : IN  STD_LOGIC;
        reset              : IN  STD_LOGIC;
        data_1, data_2     : IN  signed;
        immediate          : IN  signed(31 DOWNTO 0);
        upper_immediate    : IN  signed(31 DOWNTO 0);
        in_alu_main_func   : IN  std_logic_vector(2 downto 0);
        in_alu_second_func : IN  std_logic;
        in_use_immediate   : IN  std_logic;
        result             : OUT signed(31 DOWNTO 0);
        e_in_pc            : IN  unsigned(31 DOWNTO 0);
        e_out_pc           : OUT unsigned(31 DOWNTO 0)
    );
END;

architecture pipe_execute_simple of pipe_execute is
    signal alu_result : signedNumber;
    signal alu_data_2 : signedNumber;
begin

    alu_inst : entity work.alu(alu_simple)
        port map(
            vec1   => data_1,
            vec2   => alu_data_2,
            main_func => in_alu_main_func,
            second_func => in_alu_second_func,
            out_vec => alu_result
        );

    alu_data_2 <= immediate when in_use_immediate = '1' else data_2;

    alu_proc : process(clk, reset) is
    begin
        if (reset = '0') then
            result   <= x"0000_0000";
            e_out_pc <= x"0000_0000";
            --alu_data_2 <= (others => '0');
        elsif (rising_edge(clk)) then
            --alu_main_func <= in_alu_main_func;
            --alu_second_func <= in_alu_second_func;
            result   <= alu_result;
            e_out_pc <= e_in_pc;
        else
            null;
        end if;
    end process;
end architecture;
