library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
   generic (
      N : positive := 64;
      comm_baud_rate : positive := 9600
   );
   port(
      clk   : in std_logic;
      reset : in std_logic;
      rx    : in std_logic;
      tx    : out std_logic
   );
end top_level;

architecture arch of top_level is

   component uart_rx is
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
   end component;

   component rx_ctrl is
   port (
      clk   : in std_logic;
      reset : in std_logic; 
      avail : in  std_logic;  -- from RX
      full  : in std_logic;   -- from FIFO  
      clear : out  std_logic; -- to RX     
      wr_en : out std_logic   -- to FIFO
   );
   end component;

   component fifo is
   generic (
      N : positive := 4; -- la profondeur (le nombre d'éléments) dans la file
      W : positive := 8 -- la largeur (en bits) de la file
   );
   port (
      clk   : in std_logic;
      reset : in std_logic;                           -- actif haut: un '1' réinitialise la file
      din   : in std_logic_vector(W - 1 downto 0);    -- données entrant dans la file
      dout  : out std_logic_vector(W - 1 downto 0);   -- données sortant de la file
      wr_en : in std_logic;                           -- write-enable: si actif, une donnée sera lue de din et
                                                      -- entrée dans la file au prochain front montant de clk
      rd_en : in std_logic;                           -- read-enable: si actif, une donnée sera sortie de la file
                                                      -- et placée sur dout au prochain front montant de clk
      empty : out std_logic;                          -- indique que la file est vide
      full  : out std_logic                           -- indique que la file est pleine
   );
   end component;

   component uart_tx is
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
   end component;
   
   component rs232txsimple is
	generic (
		nStartBits : positive := 1; -- nombre de bits de départ
		nDataBits : positive := 8; -- nombre de bits de données
		nStopBits : positive := 1 -- nombre de bits d'arrêt
	);
	port(
		reset_n : in std_logic;
		bitClk : in std_logic; -- horloge des bits
		lecaractere : in std_logic_vector(nDataBits - 1 downto 0); -- caractère à transmettre
		load : in std_logic; -- signal de contrôle pour lire le caractère et débuter la transmission
		ready : out std_logic; -- indique que le système est prêt à transmettre un nouveau caractère
		rs232_tx_data : out std_logic -- signal de transmission RS-232
	);
   end component;

   component tx_ctrl is
   port (
      clk   : in std_logic;
      reset : in std_logic; 
      ready : in std_logic;   -- from TX
      empty : in std_logic;   -- from FIFO  
      send  : out  std_logic; -- to TX     
      rd_en : out std_logic   -- to FIFO
   );
   end component;

   component traitement2 is
   generic (
      N : positive := 1024
   );
   port(
      clk            : in  std_logic;
      reset          : in  std_logic;
      din            : in  std_logic_vector(7 downto 0);
      dout           : out std_logic_vector(7 downto 0);
      fifo_in_empty  : in  std_logic;
      fifo_in_rd_en  : out std_logic;
      fifo_out_full  : in  std_logic;
      fifo_out_wr_en : out std_logic
   );
   end component;

   signal clear      : std_logic;
   signal new_data   : std_logic;
   signal din        : std_logic_vector( 7 downto 0 );

   signal send       : std_logic;
   signal ready      : std_logic;
   signal dout       : std_logic_vector( 7 downto 0 );

   signal fifo_in_dout  : std_logic_vector(7 downto 0);
   signal fifo_in_wr_en : std_logic;
   signal fifo_in_rd_en : std_logic;
   signal fifo_in_empty : std_logic;
   signal fifo_in_full  : std_logic;

   signal fifo_out_din   : std_logic_vector(7 downto 0);
   signal fifo_out_wr_en : std_logic;
   signal fifo_out_rd_en : std_logic;
   signal fifo_out_empty : std_logic;
   signal fifo_out_full  : std_logic;

begin

   u_rx: uart_rx
   generic map(comm_baud_rate => comm_baud_rate)
   port map(
      clk            => clk, 
      reset          => reset, 
      dout           => din,
      avail          => new_data, 
      clear          => clear, 
      rx_serial_data => rx 
   );

   u_fifo_in: fifo
   generic map( N => N, W => 8)
   port map(
      clk   => clk,
      reset => reset,
      din   => din,
      dout  => fifo_in_dout,
      wr_en => fifo_in_wr_en,
      rd_en => fifo_in_rd_en,
      empty => fifo_in_empty,
      full  => fifo_in_full
   );

   u_rx_control: rx_ctrl
   port map(
      clk   => clk,
      reset => reset,
      avail => new_data,
      full  => fifo_in_full,
      clear => clear,
      wr_en => fifo_in_wr_en
   );

   u_tx: uart_tx
   generic map(comm_baud_rate => comm_baud_rate)
   port map
   ( 
      clk             => clk,
      send            => send,
      data            => dout,
      ready           => ready,
      tx_serial_data  => tx
   );
   
--   u_tx: rs232txsimple 
--	generic map(
--		nStartBits => 1,
--		nDataBits  => 8,
--		nStopBits  => 1
--	)
--	port map(
--		reset_n       => reset,
--		bitClk        => clk,
--		lecaractere   => dout,
--		load          => send,
--		ready         => ready,
--		rs232_tx_data => tx
--	);


   u_fifo_out: fifo
   generic map( N => N, W => 8)
   port map(
      clk   => clk,
      reset => reset,
      din   => fifo_out_din,
      dout  => dout,
      wr_en => fifo_out_wr_en,
      rd_en => fifo_out_rd_en,
      empty => fifo_out_empty,
      full  => fifo_out_full
   );

   u_tx_control: tx_ctrl
   port map(
      clk   => clk,
      reset => reset,
      ready => ready,
      empty => fifo_out_empty,
      send  => send,
      rd_en => fifo_out_rd_en
   );

   u_traitement: traitement2
   generic map( N => N )
   port map(
      clk            => clk,
      reset          => reset,
      din            => fifo_in_dout,
      dout           => fifo_out_din,
      fifo_in_empty  => fifo_in_empty,
      fifo_in_rd_en  => fifo_in_rd_en,
      fifo_out_full  => fifo_out_full,
      fifo_out_wr_en => fifo_out_wr_en
   );

end arch;

