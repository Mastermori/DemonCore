LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

ENTITY alu IS
    PORT (
        vec1, vec2 : IN signed(31 DOWNTO 0);
        main_func : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        second_func : IN STD_LOGIC;
        out_vec : OUT signed(31 DOWNTO 0)
    );
END;

ARCHITECTURE alu_simple OF alu IS
BEGIN
    evaluate : PROCESS (vec1, vec2, main_func, second_func) IS
    BEGIN
        --out_vec <= (OTHERS => '-');
        CASE main_func IS
            WHEN "000" =>
                IF second_func = '1' THEN
                    out_vec <= vec1 - vec2; -- sub
                ELSE
                    out_vec <= vec1 + vec2; -- add/addi
                END IF;
            WHEN "001" =>
                out_vec <= shift_left(vec1, to_integer(unsigned(vec2(4 DOWNTO 0)))); -- sll/slli
            WHEN "010" =>
                IF signed(vec1) < signed(vec2) THEN -- slt / slti
                    out_vec <= x"0000_0001";
                ELSE
                    out_vec <= x"0000_0000";
                END IF;
            WHEN "011" =>
                IF unsigned(vec1) < unsigned(vec2) THEN -- sltu / sltiu
                    out_vec <= x"0000_0001";
                ELSE
                    out_vec <= x"0000_0000";
                END IF;
            WHEN "100" =>
                out_vec <= vec1 XOR vec2; -- xor / xori
            WHEN "101" =>
                IF vec2(10) = '1' THEN
                    out_vec <= shift_right(signed(vec1), to_integer(vec2(4 DOWNTO 0))); -- sra / srai
                ELSE
                    out_vec <= signed(shift_right(unsigned(vec1), to_integer(vec2(4 DOWNTO 0)))); -- srl /srli
                END IF;
            WHEN "110" =>
                out_vec <= vec1 OR vec2; -- or / ori
            WHEN "111" =>
                out_vec <= vec1 AND vec2; -- and / andi
            WHEN OTHERS => NULL;
        END CASE;

    END PROCESS evaluate;
END alu_simple; -- alu_simple