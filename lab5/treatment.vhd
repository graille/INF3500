---------------------------------------------------
--  Polyechnique de Montréal
--  Traitement de l'expression d'entrée
--  Auteur: Shervin Vakili
--  Inf3500
---------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity traitement is
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
end traitement;

architecture arch of traitement is

	-- COMPONENTS DECLARATION
	type rd_state_type is (idle, rd_wait, rd);
	signal rd_state : rd_state_type := idle;
	type wr_state_type is (idle, wr_req);
	signal wr_state : wr_state_type := idle;

	type cmnd_type is array (3 downto 0) of std_logic_vector(7 downto 0);
	signal command, command_temp: cmnd_type;
	signal temp : std_logic_vector(7 downto 0);
	signal activate_rd: std_logic;         -- 1 quand une nombre est complètement recieved
	signal activate_wr: std_logic;         -- pour activer le retour en arrière le résultat via le port COM
	signal activate_treatment: std_logic;
	signal entree, entree_temp : std_logic_vector(15 downto 0);  -- valeur d'entrée entré par l'utilisateur. le numéro de l'élément souhaité à la série de Fibonacci
	signal cnt: unsigned(3 downto 0);
	constant result_message : string := "Result: ";
	signal result : std_logic_vector(15 downto 0);
	signal result_unsigned : unsigned(15 downto 0);
	signal entree_10 : integer;
	signal milliersBCD, centainesBCD, dizainesBCD, unitesBCD : unsigned(7 downto 0);

	-- signaux pour Fibonacci
	signal go: std_logic;
	signal sortieValide: std_logic;

	type tr_state_type is (idle, entree_rd, calcul, sortie_rd);
	signal tr_state : tr_state_type := idle;

	component fibonacci is
		generic (
			W : positive := 16
		);
		port(
			clk, reset, go : in STD_LOGIC;
			entree : in unsigned(W - 1 downto 0);
			Fn : out unsigned(W - 1 downto 0);
			sortieValide : out std_logic
		);
	 end component;


	 component unsigned2dec is
		port(
			nombre : in unsigned(15 downto 0);
			milliersBCD, centainesBCD, dizainesBCD, unitesBCD : out unsigned(3 downto 0)
		);
	 end component;



begin

	milliersBCD(7 downto 4) <= "0011";
	centainesBCD(7 downto 4) <= "0011";
	dizainesBCD(7 downto 4) <= "0011";
	unitesBCD(7 downto 4) <= "0011";

	 -- reading precoss
	process( clk ) is
	begin
		if( rising_edge( clk ) ) then
			if( reset = '1' ) then
				rd_state <= idle;
					 cnt <= "0000";
					 activate_rd <= '0';

			else
				case rd_state is
					when idle =>
						activate_rd <= '0';
						cnt <= "0000";
						command_temp <= (others => (others=>'0'));
						if fifo_in_empty = '0' then
							rd_state <= rd_wait;
						end if;

					when rd_wait =>
						if fifo_in_empty = '0' then
							rd_state <= rd;
						end if;

					when rd =>
						if ( din=x"0D" or cnt > 2 ) then     --fin de la chaîne d'entrée
							command_temp(conv_integer(cnt)) <= din;
							cnt <= "0000";
							rd_state <= idle;
							activate_rd <= '1';
							command <= command_temp;
						else
							command_temp(conv_integer(cnt)) <= din;
							temp <= din;
							cnt <= cnt+1;
							rd_state <= rd_wait;
						end if;

				end case;
			end if;
		end if;
	end process;

	 fifo_in_rd_en <= '1' when ( fifo_in_empty = '0' and rd_state=rd_wait) else '0';


	--instancier le module Fibonacci
	F1: Fibonacci
	generic map(w => 16)
	port map(
		clk => clk,
		reset => reset,
		go => go,
		entree => unsigned(entree),
		Fn => result_unsigned,
		sortieValide => sortieValide
	);

	 --aider:
	 entree_10 <= conv_integer(entree_temp)*10;

	 -- traitement du numéro d'entrée
	process( clk ) is
		variable ch_cnt, i: integer:= 0;
		variable ch_temp: std_logic_vector(7 downto 0);
		variable long_ch : std_logic_vector(15 downto 0):= (others => '0');
	begin
		if( rising_edge( clk ) ) then
			if( reset = '1' ) then
				tr_state <= idle;
				--à compléter
			else
				case tr_state is
					when idle =>
					--à compléter

					when entree_rd =>
						ch_temp:= command(i);
						if (ch_temp=x"00" or ch_temp=x"0D" or i>2) then    -- Fin de la chaîne d'entrée
							--à compléter
							go <= '1';
							entree <= entree_temp;
							tr_state <= calcul;

						elsif (unsigned(ch_temp) <= 9 and unsigned(ch_temp) >= 0) then
							--à compléter
							entree_temp <= conv_std_logic_vector((entree_10 + conv_integer(ch_temp)), 16);
						end if;

					when calcul =>
						if(sortieValide = '1') then
							tr_state <= sortie_rd;
						end if;

					when sortie_rd =>
						result <= std_logic_vector(result_unsigned);

				end case;
			end if;
		end if;
	end process;

	BCD:unsigned2dec port map(
		nombre 			=> unsigned(result),
		milliersBCD    => milliersBCD(3 downto 0),
		centainesBCD 	=> centainesBCD(3 downto 0),
		dizainesBCD 	=> dizainesBCD(3 downto 0),
		unitesBCD 		=> unitesBCD(3 downto 0)
	);

	-- renvoyer le résultat à l'ordinateur
	process( clk ) is
		variable cnt2: integer:= 0;
	begin
		if( rising_edge( clk ) ) then
			fifo_out_wr_en <= '0';
			if( reset = '1' ) then
				wr_state <= idle;
					 cnt2 := 0;
			else
				case wr_state is
					when idle =>
						cnt2 := 0;
						fifo_out_wr_en <= '0';
						if( activate_wr = '1' ) then
							wr_state <= wr_req;
						end if;

					when wr_req =>
						if fifo_out_full='0' then
							if cnt2=0 then     		 -- CR
								dout <= x"0D";
							else							 -- envoyer le résultat
								if cnt2<9 then
									dout <= CONV_STD_LOGIC_VECTOR(character'pos(result_message(cnt2)), 8);
								elsif cnt2=9 then
									dout <= std_logic_vector(milliersBCD);
								elsif cnt2=10 then
									dout <= std_logic_vector(centainesBCD);
								elsif cnt2=11 then
									dout <= std_logic_vector(dizainesBCD);
								elsif cnt2=12 then
									dout <= std_logic_vector(unitesBCD);
								elsif cnt2=13 then
									dout <= x"0D";      -- CR
								else
									wr_state <= idle;
								end if;

							end if;

							fifo_out_wr_en <= '1';
							cnt2 := cnt2+1;
						end if;

				end case;
			end if;
		end if;
	end process;

end arch;

