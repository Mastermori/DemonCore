LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pipe_constants.ALL;

ENTITY io_controller IS
    generic(addrWd : integer range 2 to 16 := 8; -- #address bits
            dataWd : integer range 2 to 32 := 8); -- #data    bits
    PORT(
        clk   : IN  STD_LOGIC;
        reset : IN  STD_LOGIC;
        addr  : in  std_logic_vector(addrWd - 1 downto 0);
        dataO : out std_logic_vector(dataWd - 1 downto 0)
    );
END;

ARCHITECTURE io_controller OF io_controller IS
BEGIN
    io_control : process(clk, reset) is
    begin
        if reset = '1' then
            
        elsif rising_edge(clk) then
            
        end if;
    end process io_control;
    polling : process(addr) is
        constant    addrHi      : natural   := (2**addrWd)-1;
        type    ioArrT     is array (0 to addrHi) of std_logic;
        
        variable    ioMemory      :  ioArrT;
    begin
        dataO <= (0 => ioMemory(to_integer(unsigned(addr))), others => '0');
    end process polling;
    
END io_controller;
