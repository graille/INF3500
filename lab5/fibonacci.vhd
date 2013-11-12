---------------------------------------------------
--  Polyechnique de Montréal
--  Processeur spécifique de calcule de la série de Fibonacci
--  Auteur: Christian Artin, Benjamin O'Connell-Armand
--  Inf3500
---------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;  

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
begin
	process(clk, reset)
		
	begin  
	
	end process;		
	
end fibonacci_arch;