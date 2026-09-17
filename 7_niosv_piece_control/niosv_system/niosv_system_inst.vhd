	component niosv_system is
		port (
			clk_clk          : in  std_logic                    := 'X'; -- clk
			piece_col_export : out std_logic_vector(2 downto 0);        -- export
			piece_row_export : out std_logic_vector(2 downto 0)         -- export
		);
	end component niosv_system;

	u0 : component niosv_system
		port map (
			clk_clk          => CONNECTED_TO_clk_clk,          --       clk.clk
			piece_col_export => CONNECTED_TO_piece_col_export, -- piece_col.export
			piece_row_export => CONNECTED_TO_piece_row_export  -- piece_row.export
		);

