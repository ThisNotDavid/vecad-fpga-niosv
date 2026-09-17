	component niosv_system is
		port (
			clk_clk    : in  std_logic                    := 'X'; -- clk
			vga_export : out std_logic_vector(2 downto 0)         -- export
		);
	end component niosv_system;

	u0 : component niosv_system
		port map (
			clk_clk    => CONNECTED_TO_clk_clk,    -- clk.clk
			vga_export => CONNECTED_TO_vga_export  -- vga.export
		);

