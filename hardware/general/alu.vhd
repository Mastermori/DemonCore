LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

ENTITY alu IS
    PORT(
        vec1, vec2  : IN  signed(31 downto 0);
        main_func   : IN  std_logic_vector(2 downto 0);
        second_func : IN  std_logic;
        out_vec     : OUT signed(31 downto 0)
    );
END;

ARCHITECTURE alu_simple OF alu IS
BEGIN
    evaluate : process(vec1, vec2, main_func, second_func) is
    begin
        case main_func is
            when "000" =>
                if second_func = '1' then
                    out_vec <= vec1 - vec2; -- sub
                else
                    out_vec <= vec1 + vec2; -- add/addi
                end if;
            when "001" =>
                out_vec <= shift_left(vec1, to_integer(vec2)); -- sll
            when "010" =>
                if signed(vec1) < signed(vec2) then -- slt / slti
                    out_vec <= x"0000_0001";
                else
                    out_vec <= x"0000_0000";
                end if;
            when "011" =>
                if unsigned(vec1) < unsigned(vec2) then -- sltu / sltiu
                    out_vec <= x"0000_0001";
                else
                    out_vec <= x"0000_0000";
                end if;
            when "100" =>
                out_vec <= vec1 xor vec2; -- xor / xori
            when "101" =>
                if second_func = '0' then
                    out_vec <= signed(shift_right(unsigned(vec1), to_integer(vec2))); -- srl /srli
                else
                    out_vec <= shift_right(vec1, to_integer(vec2)); -- sra / srai
                end if;
            when "110" =>
                out_vec <= vec1 or vec2; -- or / ori
            when "111" =>
                out_vec <= vec1 and vec2; -- and / andi
            when others => null;
        end case;
        
    end process evaluate;
END alu_simple;                         -- alu_simple