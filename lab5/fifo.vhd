library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
   generic (
      N : positive := 1024; -- la profondeur (le nombre d'éléments) dans la file
      W : positive := 8     -- la largeur (en bits) de la file
   );
   port (
      clk   : in std_logic;
      reset : in std_logic;                           -- actif haut: un '1' réinitialise la file
      din   : in std_logic_vector(W - 1 downto 0);    -- données entrant dans la file
      dout  : out std_logic_vector(W - 1 downto 0);   -- données sortant de la file
      wr_en : in std_logic;              -- write-enable: si actif, une donnée sera lue de din et
                                         -- entrée dans la file au prochain front montant de clk
      rd_en : in std_logic;              -- read-enable: si actif, une donnée sera sortie de la file
                                         -- et placée sur dout au prochain front montant de clk
      empty : out std_logic;             -- indique que la file est vide
      full  : out std_logic              -- indique que la file est pleine
   );
end fifo;

architecture arch of fifo is


begin

	 -- Memory Pointer Process
    fifo_proc : process (clk)
	 
        type FIFO_Memory is array (0 to N - 1) of STD_LOGIC_VECTOR (w-1 downto 0);
        variable Memory : FIFO_Memory;
        variable Head : natural range 0 to N-1;
        variable Tail : natural range 0 to N-1;
        variable Looped : boolean;
		  
    begin
        if rising_edge(clk) then
            if reset = '1' then
                Head := 0;
                Tail := 0;
                
                Looped := false;
                Full  <= '0';
                Empty <= '1';
            else
                if (rd_en = '1') then
                    if ((Looped = true) or (Head /= Tail)) then
                        -- Update data output
                        dout <= Memory(Tail);
                        
                        -- Update Tail pointer as needed
                        if (Tail = N-1) then
                            Tail := 0;
                            Looped := false;
                        else
                            Tail := Tail + 1;
                        end if;
                    end if;
                end if;
                
                if (wr_en = '1') then
                    if ((Looped = false) or (Head /= Tail)) then
                        -- Write Data to Memory
                        Memory(Head) := din;
                        
                        -- Increment Head pointer as needed
                        if (Head = N-1) then
                            Head := 0;
                            
                            Looped := true;
                        else
                            Head := Head + 1;
                        end if;
                    end if;
                end if;
                
                -- Update Empty and Full flags
                if (Head = Tail) then
                    if Looped then
                        full <= '1';
                    else
                        empty <= '1';
                    end if;
                else
                    empty    <= '0';
                    full    <= '0';
                end if;
            end if;
        end if;
    end process;

end arch;