---------------------------------------------------
--  Polyechnique de Montréal
--  Processeur spécifique de calcule de la série de Fibonacci
--  Auteur: Christian Artin, Benjamin O'Connell-Armand
--  Inf3500
---------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity fibonacci is
	generic (
		W : positive := 16
		);
	port(
		clk, reset, go : in STD_LOGIC;
		entree : in unsigned(W - 1 downto 0); -- n
		Fn : out unsigned(W - 1 downto 0);
		sortieValide : out std_logic := '0'
		);
end fibonacci;

architecture fibonacci_arch of fibonacci is
type fi_state_type is (idle, calcul, terminee);
signal fi_state : fi_state_type := idle;	

begin
	process( clk, reset )
	variable fnm1 : unsigned(W - 1 downto 0) := conv_unsigned(1, W);
	variable fnm2 : unsigned(W - 1 downto 0) := conv_unsigned(1, W);
	variable Fn_temp : unsigned(W - 1 downto 0) := fnm1 + fnm2;
	variable n : integer;

	begin
		if ( rising_edge(clk) ) then
			if (reset = '1') then
				fnm1 := conv_unsigned(1, W);
				fnm2 := conv_unsigned(1, W);
				Fn_temp := fnm1 + fnm2;
				fi_state <= idle;
				n := 0;
				
				sortieValide <= '0';
				Fn <= (others => '0');
			else
				case fi_state is
					when idle =>
						
						fnm1 := conv_unsigned(1, W);
						fnm2 := conv_unsigned(1, W);
						Fn_temp := fnm1 + fnm2;
						n := conv_integer(entree);
						sortieValide <= '0';
						
						if (go = '1') then
							if (n < 1) then
								n := 1;
							end if;
							fi_state <= calcul;							
						end if;
					when calcul =>
						if (n > 3) then		-- Le calcul n'est pas termnié
							fnm1 := fnm2;
							fnm2 := Fn_temp;
							Fn_temp := fnm1 + fnm2;
							n := n - 1;
						else	-- Quand le calcul est terminé
							if (n = 2 OR n = 1) then	-- Cas  spécial où n = 2 ou à 1
								Fn_temp := fnm1;
							end if;
							fi_state <= terminee;
						end if;
					when terminee =>
						Fn <= Fn_temp;
						sortieValide <= '1';
						fi_state <= idle;
				end case;
			end if;
		end if;
	end process;		
end fibonacci_arch;