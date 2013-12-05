----------------------------------------------------------------------------
--	UART_TX_CTRL.vhd -- UART Data Transfer Component
----------------------------------------------------------------------------
-- Author:  Sam Bobrowicz
--          Copyright 2011 Digilent, Inc.
-- Modified: Tarek Ould Bachir (708) 
--          Changed signals to std_logic_unsigned numeric_std
--          Added constant definitions 
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--	This component may be used to transfer data over a UART device. It will
-- serialize a byte of data and transmit it over a TXD line. The serialized
-- data has the following characteristics:
--         *9600 Baud Rate
--         *8 data bits, LSB first
--         *1 stop bit
--         *no parity
--         				
-- Port Descriptions:
--
--   SEND  - Used to trigger a send operation. The upper layer logic should 
--           set this signal high for a single clock cycle to trigger a 
--           send. When this signal is set high DATA must be valid . Should 
--           not be asserted unless READY is high.
--   DATA  - The parallel data to be sent. Must be valid the clock cycle
--           that SEND has gone high.
--   CLK   - A 100 MHz clock is expected
--   READY - This signal goes low once a send operation has begun and
--           remains low until it has completed and the module is ready to
--           send another byte.
--   tx_serial_data - This signal should be routed to the appropriate TX pin 
--           of the external UART device.
--   
----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
-- Revision History:
--  08/08/2011(SamB): Created using Xilinx Tools 13.2
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_tx is
generic(
    comm_baud_rate : positive := 9600
);
port 
( 
   clk             : in std_logic;   
   send            : in std_logic;
   data            : in std_logic_vector (7 downto 0);
   ready           : out std_logic;
   tx_serial_data  : out std_logic
);
end uart_tx;

architecture behavioral of uart_tx is

   constant clk_freq : real := real( 100000000 );
   constant baud_rate : real := real( comm_baud_rate );
   
   constant divisor : unsigned(15 downto 0) := to_unsigned(integer(round(clk_freq/baud_rate))-1, 16);
   
   type tx_state_type is (rdy, load_bit, send_bit);

   constant bit_index_max : natural := 10;

   --Counter that keeps track of the number of clock cycles the current bit has been held stable over the
   --UART TX line. It is used to signal when the ne
   signal bit_timer : unsigned(15 downto 0) := to_unsigned(0, 16);--(others => '0');

   --combinatorial logic that goes high when bit_timer has counted to the proper value to ensure
   --a 9600 baud rate
   signal bit_done : std_logic;

   --Contains the index of the next bit in tx_data that needs to be transferred 
   signal bit_index : natural;

   --a register that holds the current data being sent over the UART TX line
   signal tx_bit : std_logic := '1';

   --A register that contains the whole data packet to be sent, including start and stop bits. 
   signal tx_data : std_logic_vector(9 downto 0) := (others => '0');

   signal tx_state : tx_state_type := rdy;

begin

   -- assert false
   -- report "baud rate is " & integer'image(integer(baud_rate)) & LF severity note;

   --Next state logic
   next_tx_state_process : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         case tx_state is 
         when rdy =>
            if (send = '1') then
               tx_state <= load_bit;
            end if;
         when load_bit =>
            tx_state <= send_bit;
         when send_bit =>
            if (bit_done = '1') then
               if (bit_index = bit_index_max ) then
                  tx_state <= rdy;
               else
                  tx_state <= load_bit;
               end if;
            end if;
         when others=> --should never be reached
            tx_state <= rdy;
         end case;
      end if;
   end process;

   bit_timing_process : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         if ( tx_state = rdy ) then
            bit_timer <= to_unsigned(0, 16);
         else
            if (bit_done = '1') then
               bit_timer <= to_unsigned(0, 16);
            else
               bit_timer <= bit_timer + 1;
            end if;
         end if;
      end if;
   end process;

   bit_done <= '1' when ( bit_timer = divisor ) else '0';

   bit_counting_process : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         if ( tx_state = rdy ) then
            bit_index <= 0;
         elsif ( tx_state = load_bit ) then
            bit_index <= bit_index + 1;
         end if;
      end if;
   end process;

   tx_data_latch_process : process ( clk ) is
   begin
      if ( rising_edge( clk ) ) then
         if ( send = '1' ) then
            tx_data <= '1' & data & '0';
         end if;
      end if;
   end process;

   tx_bit_process : process ( clk )
   begin
      if ( rising_edge( clk ) ) then
         if ( tx_state = rdy ) then
            tx_bit <= '1';
         elsif ( tx_state = load_bit ) then
            tx_bit <= tx_data( bit_index );
         end if;
      end if;
   end process;

   tx_serial_data <= tx_bit;
   ready <= '1' when ( tx_state = rdy ) else '0';

end behavioral;

