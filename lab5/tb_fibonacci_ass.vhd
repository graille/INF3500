-------------------------------------------------------------------------------
--
-- banc d'essai de fibonacci
-- Lab5, INF3500
-- Benjamin O'Connell-Armand
-- Christian Artin
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fibonacci_ass is
	port(
		signal clk : in std_logic;
		signal reset : in std_logic
		);
end tb_fibonacci_ass;

architecture tb_assembleur of tb_fibonacci_ass is
	signal entreeExterne : signed(15 downto 0);
	signal entreeExterneValide : std_logic := '0';
	signal sortieExterne : signed(15 downto 0);
	signal sortieExterneValide : std_logic;
	type INT_ARRAY is array (integer range <>) of integer;
	signal vecteur_test : INT_ARRAY(1 to 11) := (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55);

component processeurv19a is
	generic (
		Nreg : integer := 16; -- nombre de registres
		Wd : integer := 16; -- largeur du chemin des données en bits
		Wi : integer := 16; -- largeur des instructions en bits
		Mi : integer := 8; -- nombre de bits d'adresse de la mémoire d'instructions
		Md : integer := 8; -- nombre de bits d'adresse de la mémoire des données
		resetvalue : std_logic := '1'
	);
	port(
		reset : in std_logic;
		CLK : in std_logic;
		entreeExterne : in signed(Wd - 1 downto 0);
		entreeExterneValide : in std_logic;
		sortieExterne : out signed(Wd - 1 downto 0);
		sortieExterneValide : out std_logic
	);
end component;

begin
	UUT: processeurv19a
	port map(
		CLK                 => clk,
		reset               => reset,
		entreeExterne       => entreeExterne,
		entreeExterneValide => entreeExterneValide,
		sortieExterne       => sortieExterne,
		sortieExterneValide => sortieExterneValide
	);
	process
		variable n : integer := 1;
	begin
		while(n <= 12) loop
			entreeExterne <= to_signed(n-1, 16);
			entreeExterneValide <= '1';
			
			wait until sortieExterneValide = '1';
			entreeExterneValide <= '0';
			
			assert sortieExterne = to_signed(vecteur_test(n), 16)
			report "Erreur" severity FAILURE;
			
			n := n + 1;
		end loop;
		assert false
		report "Fin de la simulation" severity FAILURE;
	end process;
end tb_assembleur;