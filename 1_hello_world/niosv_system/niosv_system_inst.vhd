	component niosv_system is
		port (
			clk_clk : in std_logic := 'X'  -- clk
		);
	end component niosv_system;

	u0 : component niosv_system
		port map (
			clk_clk => CONNECTED_TO_clk_clk  -- clk.clk
		);

