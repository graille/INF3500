library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_ctrl is
    port (
        clk   : in std_logic;
        reset : in std_logic; 
        avail : in  std_logic;  -- from RX
        full  : in std_logic;   -- from FIFO  
        clear : out  std_logic; -- to RX     
        wr_en : out std_logic   -- to FIFO
    );
end rx_ctrl;

architecture arch of rx_ctrl is	

    type state_type is (idle, received);
    signal state : state_type := idle;

    signal  s_clear : std_logic := '0'; 

begin

    process (clk, reset) is
        begin   
        if( reset = '1' ) then
            state <= idle;
            s_clear <= '0';
        elsif( rising_edge( clk ) ) then

            case state is

            when idle =>
                if ( avail = '1' and full /= '1' ) then
                    s_clear <= '1';
                    state <= received;
                end if;  

            when received =>
                s_clear <= '0';
                state <= idle; 

            end case;   

    end if;   
    end process;

    process (avail, full, state, reset) is
    begin
        if( reset = '1' ) then
            wr_en <= '0';
        elsif ( state = idle and avail = '1' and full /= '1' ) then
            wr_en <= '1';
        else
            wr_en <= '0';
        end if;
    end process;

    clear <= s_clear;

end arch;