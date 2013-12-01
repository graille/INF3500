-------------------------------------------------------------------------------
--
-- convertisseur de nombre à 10 bits non signé à décimal
-- Pierre Langlois
-- École Polytechnique de Montréal
--
-- 2009/10/13 v. 1.0
-- Le module accepte en entrée un nombre non signé.
-- Il a trois sorties:
--	a. les centaines (0 à 9)
--	b. les dizaines (0 à 9)
-- 	c. les unités (0 à 9) 
-- Un signal d'erreur est activé si la valeur abs(nombre) >= 1000.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unsigned2dec is
	port(
		nombre : in unsigned(15 downto 0);
		milliersBCD, centainesBCD, dizainesBCD, unitesBCD : out unsigned(3 downto 0)
	);
end unsigned2dec;

architecture arch of unsigned2dec is
begin

	process(nombre)
--	variable n, c, d, u : natural range 0 to 999 := 0;
--	variable n, c, d, u : natural range 0 to 1023 := 0;
	variable n, m, c, d, u : natural := 0;
	begin
		
		n := to_integer(nombre);
		
		m := 0;
		for milliers in 9 downto 1 loop
			if n >= milliers * 1000 then
				m := milliers;
				exit;
			end if;
		end loop;

		n := n - m * 1000;
		
		c := 0;
		for centaines in 9 downto 1 loop
			if n >= centaines * 100 then
				c := centaines;
				exit;
			end if;
		end loop;

		n := n - c * 100;

		d := 0;
		for dizaines in 9 downto 1 loop
			if n >= dizaines * 10 then
				d := dizaines;
				exit;
			end if;
		end loop;
		
		u := n - d * 10;
		
		milliersBCD <= to_unsigned(m, 4);
		centainesBCD <= to_unsigned(c, 4);
		dizainesBCD <= to_unsigned(d, 4);
		unitesBCD <= to_unsigned(u, 4);
	end process;
end arch;