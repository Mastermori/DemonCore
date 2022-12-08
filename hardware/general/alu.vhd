LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

ENTITY alu IS
    PORT(
        vec1, vec2 : IN  signed(31 downto 0);
        opCode     : IN  std_logic;
        outVec     : OUT signed(31 downto 0)
    );
END;

ARCHITECTURE alu_simple OF alu IS
BEGIN
    outVec <= vec1 + vec2 WHEN opCode = '0' ELSE vec1 - vec2;
END alu_simple;                         -- alu_simple