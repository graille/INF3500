--
-- processeur.vhd
--
-- processeur à usage général
--
-- Pierre Langlois
-- v. 1.9a 2013/11/07 pour labo 5, INF3500 automne 2013
--
-- Par rapport aux notes de cours (v. 2.5), cette version comporte les changements suivants:
-- 1. inclut le chargement d'une valeur immédiate de 16 bits.
-- OP code: 1010 | registre-destination | - | -
-- 2. reset asynchrone au lieu de synchrone

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processeurv19a is
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
end processeurv19a;

architecture arch of processeurv19a is

-- signaux de la mémoire des instructions
type memoireInstructions_type is array (0 to 2 ** Mi - 1) of std_logic_vector(Wi - 1 downto 0);
constant memoireInstructions : memoireInstructions_type :=
--	(x"0752", x"190b", x"7840", x"8cf0", x"9a1c", x"c102", others => (others => '1')); -- exemple des notes
--	(x"8000", x"8101", x"1C01", x"C406", x"8704", x"1C7C", x"9C03", others => (others => '1')); -- différence absolue M[3] = |M[0] - M[1]|
--  (x"A700", x"0005", x"AC00", x"0003", x"137C", others => (others => '1')); -- chargement valeur immédiate 16 bits 
	(x"D700", x"DC00", x"137C", x"E300", others => (others => '1')); -- Test des nouvelles instructions

-- signaux de la mémoire des données
type memoireDonnees_type is array(0 to 2 ** Md - 1) of signed(Wd - 1 downto 0);
signal memoireDonnees : memoireDonnees_type;
signal sortieMemoireDonnees : signed(Wd - 1 downto 0);
signal adresseMemoireDonnees : integer range 0 to 2 ** Md - 1;
signal lectureEcritureN : std_logic;

-- signaux du bloc des registres
type lesRegistres_type is array(0 to Nreg - 1) of signed(Wd - 1 downto 0);
signal lesRegistres : lesRegistres_type;
signal A : signed(Wd - 1 downto 0);
signal choixA : integer range 0 to Nreg - 1;
signal B : signed(Wd - 1 downto 0);
signal choixB : integer range 0 to Nreg - 1;
signal donnee : signed(Wd - 1 downto 0);
signal choixCharge : integer range 0 to Nreg - 1;
signal charge : std_logic;

-- signaux du multiplexeur contrôlant la source du bloc des registres
signal constante : signed(Wd - 1 downto 0);
signal choixSource : integer range 0 to 3;

-- signaux de l'UAL
signal F : signed(Wd - 1 downto 0);
signal Z : std_logic;
signal N : std_logic;
signal op : integer range 0 to 7;

-- signaux de l'unité de contrôle
type type_etat is
	(depart, querir, decoder, stop, ecrireMemoire, lireMemoire, opUAL, jump, chargeimm16, entrerRegistre, sortirRegistre);
signal etat : type_etat;
signal PC : integer range 0 to (2 ** Mi - 1); -- compteur de programme
signal IR : std_logic_vector(Wi - 1 downto 0); -- registre d'instruction

begin

	-- multiplexeur pour choisir la source du bloc des registres
	process (F, constante, entreeExterne, sortieMemoireDonnees, choixSource)
	begin
		case choixSource is 
			when 0 => donnee <= F; 
			when 1 => donnee <= constante;
			when 2 => donnee <= entreeExterne;
			when 3 => donnee <= sortieMemoireDonnees;
			when others => donnee <= F;
		end case;
	end process;
	constante <= signed(memoireInstructions(PC)); -- chargement de valeur immédiate, 16 bits
	
	-- bloc des registres
	process (CLK, reset)
	begin
		if reset = resetvalue then
			lesRegistres <= (others => (others => '0'));
		elsif rising_edge(CLK) then
			if charge = '1' then
				lesRegistres(choixCharge) <= donnee;
			end if;
		end if;
	end process;
	
	-- signaux de sortie du bloc des registres
	A <= lesRegistres(choixA);
	B <= lesRegistres(choixB);
	sortieExterne <= B;	
	
	-- unité de contrôle
	process (CLK, reset)
	begin
		if reset = resetvalue then
			etat <= depart;
		elsif rising_edge(CLK) then
			case etat is
				when depart =>
					PC <= 0;
					etat <= querir;
				when querir =>
					IR <= memoireInstructions(PC);
					PC <= PC + 1;
					etat <= decoder;
				when decoder =>
					if (IR(15) = '0') then
						etat <= opUAL;
					else
						case IR(14 downto 12) is
							when "000" => etat <= lireMemoire;
							when "001" => etat <= ecrireMemoire;
							when "010" => etat <= chargeImm16;
							when "101" => etat <= entrerRegistre;
							when "110" => etat <= sortirRegistre;
							when "100" => etat <= jump;
							when "111" => etat <= stop;
							when others => etat <= stop;
						end case;
					end if;
				when opUAL | lireMemoire | ecrireMemoire =>
					etat <= querir;
				when jump =>
					if 	(IR(11 downto 8) = "0000") or -- branchement sans condition
						(IR(11 downto 8) = "0001" and Z = '1') or -- si = 0
						(IR(11 downto 8) = "0010" and Z = '0') or -- si /= 0
						(IR(11 downto 8) = "0011" and N = '1') or -- si < 0
						(IR(11 downto 8) = "0100" and N = '0') -- si >= 0
					then
						PC <= to_integer(unsigned(IR(7 downto 0)));
					end if;
					etat <= querir;
				when chargeImm16 =>
					etat <= querir;
					PC <= PC + 1;
				when entrerRegistre =>
					if (entreeExterneValide = '1') then
						etat <= querir;
					end if;
				when sortirRegistre =>
					
				when stop =>
					etat <= stop;
				when others =>
					etat <= depart;
			end case;
		end if;
	end process;

	-- signaux de sortie de l'unité de contrôle
	adresseMemoireDonnees <= to_integer(unsigned(IR(7 downto 0)));
	lectureEcritureN <= '0' when etat = ecrireMemoire else '1';
	with etat select
		choixSource <=
			0 when opUAL,
			1 when chargeImm16,
			2 when entrerRegistre,
			3 when others;
	choixCharge <= to_integer(unsigned(IR(11 downto 8)));
	choixA <= to_integer(unsigned(IR(7 downto 4)));
	choixB <= to_integer(unsigned(IR(11 downto 8))) when etat = ecrireMemoire OR etat = sortirRegistre else
		to_integer(unsigned(IR(3 downto 0)));
	with etat select
		charge <=
		'1' when opUAL | lireMemoire | chargeImm16 | entrerRegistre,
		'0' when others;
	with etat select
		sortieExterneValide <= 
		'1' when sortirRegistre,
		'0' when others;
	op <= to_integer(unsigned(IR(14 downto 12)));
	
	-- UAL
	process(A, B, op)
	begin
		case op is	
			when 0 => F <= A + B;
			when 1 => F <= A - B;
			when 2 => F <= shift_right(A, 1);
			when 3 => F <= shift_left(A, 1);
			when 4 => F <= not(A);
			when 5 => F <= A and B;
			when 6 => F <= A or B;
			when 7 => F <= A;
			when others => F <= (others => 'X');
		end case;
	end process;
	
	-- registre d'état de l'UAL
	process(clk, reset)
	begin
		if reset = resetvalue then
			Z <= '0';
			N <= '0';
		elsif rising_edge(clk) then
			if (etat = opUAL) then
				if F = 0 then Z <= '1'; else Z <= '0'; end if;
				N <= F(F'left);
			end if;
		end if;
	end process;
	
	-- mémoire des données
	process (CLK)
	begin
		if rising_edge(CLK) then
			if lectureEcritureN = '0' then
				memoireDonnees(adresseMemoireDonnees) <= B;
			end if;
		end if;
	end process;
	sortieMemoireDonnees <= memoireDonnees(adresseMemoireDonnees);
	
	-- signaux de sortie pour déboguage
--	PCout <= std_logic_vector(to_unsigned(PC, PCout'length));
--	Fout <= std_logic_vector(F(Fout'length - 1 downto 0));
--	etatout <= std_logic_vector(to_unsigned(type_etat'pos(etat), etatout'length));
--	Zout <= Z;
--	Nout <= N;
	
end arch;
