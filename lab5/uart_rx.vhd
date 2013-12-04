-- src: https://www.das-labor.org/trac/browser/vhdl/components/wb_uart/vhdl/uart_rx.vhd?rev=1273
-- edited by Tarek Ould Bachir (708)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-----------------------------------------------------------------------------
-- UART Receiver ------------------------------------------------------------
entity uart_rx is
generic(
    comm_baud_rate : positive := 9600    
);
port(
   clk      : in  std_logic;
   reset    : in  std_logic;
   dout     : out std_logic_vector( 7 downto 0 );
   avail    : out std_logic;
   clear    : in  std_logic;
   rx_serial_data : in  std_logic 
);
end uart_rx;

-----------------------------------------------------------------------------
-- Implemenattion -----------------------------------------------------------
architecture rtl of uart_rx is

   constant clk_freq : real := real( 83333333,333333333333333333333333 );
   constant baud_rate : real := real( comm_baud_rate );
   constant divisor : unsigned(15 downto 0) := to_unsigned(integer(round(clk_freq/baud_rate))-1, 16);

   -- Signals
   signal bitcount  : integer range 0 to 10;
   signal count     : unsigned(15 downto 0);
   signal shiftreg  : std_logic_vector(7 downto 0);
   signal rxh       : std_logic_vector(2 downto 0);
   signal rxd2      : std_logic;
   
   -- signal error    : std_logic;

begin

   proc: process( clk ) is
   begin
   
      if clk'event and clk='1' then
      
         if reset = '1' then
            count    <= (others => '0');
            bitcount <= 0;
            -- error    <= '0';
            avail    <= '0';
         else
            if clear='1' then
               -- error <= '0';
               avail <= '0';
            else
          
               if count /= 0 then
                  count <= count - 1;
               else
                  if bitcount=0 then     -- wait for startbit
                     if rxd2 = '0' then     -- FOUND
                        count    <= unsigned( "0" & divisor(15 downto 1) );
                        bitcount <= bitcount + 1;                                               
                     end if;
                  elsif bitcount=1 then  -- sample mid of startbit
                     if rxd2 = '0' then     -- OK
                        count    <= unsigned(divisor);
                        bitcount <= bitcount + 1;
                        shiftreg <= "00000000";
                     else                -- ERROR
                        -- error    <= '1';
                        bitcount <= 0;
                     end if;
                  elsif bitcount=10 then -- stopbit
                     -- if rxd2='1' then     -- OK
                     bitcount <= 0;
                     dout     <= shiftreg;
                     avail    <= '1';
                     -- else                -- ERROR
                     --    error    <= '1';
                     -- end if;
                  else
                     shiftreg(6 downto 0) <= shiftreg(7 downto 1);
                     shiftreg(7) <= rxd2;
                     count    <= unsigned(divisor);
                     bitcount <= bitcount + 1;
                  end if;
               end if;
               
            end if;
         end if;
      end if;
   end process;

   -----------------------------------------------------------------------------
   -- Sync incoming rx_serial_data (anti metastable) --------------------------------------
   syncproc: process(reset, clk) is
   begin
      if reset='1' then
      
         rxh  <= (others => '1');
         rxd2 <= '1';
         
      elsif clk'event and clk='1' then
         
         rxh <= rxh(1 downto 0) & rx_serial_data;
         
         if rxh = "111" then
            rxd2 <= '1';
         elsif rxh="000" then
            rxd2 <= '0';   
         end if;
         
      end if;
   end process;
	                                       
end rtl;