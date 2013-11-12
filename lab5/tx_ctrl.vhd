library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_ctrl is
   port (
      clk   : in std_logic;
      reset : in std_logic; 
      ready : in std_logic;   -- from TX
      empty : in std_logic;   -- from FIFO  
      send  : out  std_logic; -- to TX     
      rd_en : out std_logic   -- to FIFO
   );
end tx_ctrl;

architecture arch of tx_ctrl is	

   type state_type is (idle, prepare_to_pop, pop_data, send_data);
   signal state : state_type := idle;
   
   signal s_send  : std_logic := '0';
   signal s_rd_en : std_logic := '0';

begin
   
    process (clk, reset) is
    begin   
        if( reset = '1' ) then
            state <= idle;
            s_rd_en <= '0';
            s_send <= '0';
        elsif( rising_edge( clk ) ) then
            case state is
                when idle =>
                    if( empty = '0' ) then
                        if( ready = '1' ) then
                            state <= pop_data;
                            s_rd_en <= '1';
                        else
                            state <= prepare_to_pop;
                            s_rd_en <= '0';
                        end if;
                    end if;
                   
                when prepare_to_pop =>
                   if( ready = '1' ) then
                      state <= pop_data;
                      s_rd_en <= '1';
                   end if;
                   
                when pop_data =>
                   state <= send_data;
                   s_rd_en <= '0';
                   s_send <= '1';
                   
                when send_data => 
                   state <= idle;
                   s_send <= '0';
               
            end case;
        end if;   
    end process;

    send <= s_send;
    rd_en <= s_rd_en;

end arch;