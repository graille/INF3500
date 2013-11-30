---------------------------------------------------
--  Polyechnique de Montréal
--  Processeur spécifique de calcule de la série de Fibonacci
--  Auteur: Christian Artin, Benjamin O'Connell-Armand
--  Inf3500
---------------------------------------------------

library ieee;
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
		sortieValide : out std_logic
		);
end fibonacci;

architecture fibonacci_arch of fibonacci is
type fi_state_type is (idle, calcul, terminee);
signal fi_state : fi_state_type := idle;	

begin
	process( clk, reset )
	variable fnm1 : unsigned(W - 1 downto 0) := "1";
	variable fnm2 : unsigned(W - 1 downto 0) := "1";
	variable Fn_temp : unsigned(W - 1 downto 0) := fnm1 + fnm2;
	variable n : integer;

	begin
		if ( rising_edge(clk) ) then
			if (reset = '1') then
				fnm1:= "1";
				fnm2 := "1";
				Fn_temp := fnm1 + fnm2;
				fi_state <= idle;
				n := 0;
				
				sortieValide <= '0';
				Fn <= "0";
			else
				case fi_state is
					when idle =>
					if (go = '1') then
						sortieValide <= '0';
						n := conv_integer(entree);
						if (n > 1) then
							n := 1;
						end if;
						fi_state <= calcul;
					end if;
					when calcul =>
					-- calcul TODO
					if (n > 3) then		-- Le calcul d'est pas termnié
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
				end case;
			end if;
		end if;
	end process;		
end fibonacci_arch;