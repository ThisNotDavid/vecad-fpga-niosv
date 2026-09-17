	component niosv_system is
		port (
			clk_clk     : in  std_logic                    := 'X'; -- clk
			ledg_export : out std_logic_vector(3 downto 0);        -- export
			ledr_export : out std_logic_vector(3 downto 0)         -- export
		);
	end component niosv_system;

	u0 : component niosv_system
		port map (
			clk_clk     => CONNECTED_TO_clk_clk,     --  clk.clk
			ledg_export => CONNECTED_TO_ledg_export, -- ledg.export
			ledr_export => CONNECTED_TO_ledr_export  -- ledr.export
		);

