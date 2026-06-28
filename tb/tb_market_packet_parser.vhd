library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_market_packet_parser is
end tb_market_packet_parser;

architecture Behavioral of tb_market_packet_parser is

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal in_valid   : std_logic := '0';
    signal in_data    : std_logic_vector(7 downto 0) := (others => '0');

    signal out_valid  : std_logic;
    signal instrument : std_logic_vector(7 downto 0);
    signal bid_price  : std_logic_vector(15 downto 0);
    signal ask_price  : std_logic_vector(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: entity work.market_packet_parser
        port map (
            clk        => clk,
            rst        => rst,
            in_valid   => in_valid,
            in_data    => in_data,
            out_valid  => out_valid,
            instrument => instrument,
            bid_price  => bid_price,
            ask_price  => ask_price
        );

    -- Clock generator: 100 MHz clock
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stim_process : process

        -- Reset the parser before each test.
        procedure reset_dut is
        begin
            rst      <= '1';
            in_valid <= '0';
            in_data  <= x"00";

            wait for 3 * CLK_PERIOD;

            wait until rising_edge(clk);
            wait for 1 ns;
            rst <= '0';

            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        -- Send one byte into the parser.
        -- The byte is held stable until the next rising clock edge.
        procedure send_byte(byte_value : in std_logic_vector(7 downto 0)) is
        begin
            in_valid <= '1';
            in_data  <= byte_value;

            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        -- Send one byte and check that out_valid did'nt pulse.
        -- Used for invalid-packet tests.
        procedure send_byte_expect_no_valid(
            byte_value : in std_logic_vector(7 downto 0);
            test_name  : in string
        ) is
        begin
            send_byte(byte_value);

            assert out_valid = '0'
                report "ERROR: " & test_name & " produced unexpected out_valid while sending packet"
                severity error;
        end procedure;

        -- Wait for out_valid, but only for a finite number of cycles.
        -- This stops the simulation hanging forever if the parser is not working.
        procedure wait_for_out_valid(
            max_cycles : in natural;
            test_name  : in string
        ) is
            variable seen_valid : boolean := false;
        begin
            for i in 1 to max_cycles loop
                wait until rising_edge(clk);
                wait for 1 ns;

                if out_valid = '1' then
                    seen_valid := true;
                    exit;
                end if;
            end loop;

            assert seen_valid
                report "ERROR: " & test_name & " did not produce out_valid"
                severity error;
        end procedure;

        -- Check that out_valid stays low for a number of cycles.
        procedure check_no_out_valid_for_cycles(
            cycles    : in natural;
            test_name : in string
        ) is
        begin
            for i in 1 to cycles loop
                wait until rising_edge(clk);
                wait for 1 ns;

                assert out_valid = '0'
                    report "ERROR: " & test_name & " produced unexpected out_valid"
                    severity error;
            end loop;
        end procedure;

    begin

        --------------------------------------------------------------------
        -- Test 1: valid packet
        --------------------------------------------------------------------
        reset_dut;

        report "TEST 1: valid packet";

        -- Packet: AB CD 07 12 34 12 50
        -- Meaning:
        -- instrument = 0x07
        -- bid_price  = 0x1234
        -- ask_price  = 0x1250
        send_byte(x"AB");
        send_byte(x"CD");
        send_byte(x"07");
        send_byte(x"12");
        send_byte(x"34");
        send_byte(x"12");
        send_byte(x"50");

        in_valid <= '0';
        in_data  <= x"00";

        wait_for_out_valid(5, "valid packet test");

        assert instrument = x"07"
            report "ERROR: valid packet instrument incorrect"
            severity error;

        assert bid_price = x"1234"
            report "ERROR: valid packet bid price incorrect"
            severity error;

        assert ask_price = x"1250"
            report "ERROR: valid packet ask price incorrect"
            severity error;

        report "TEST 1 PASSED: valid packet parsed correctly";


        --------------------------------------------------------------------
        -- Test 2: bad first header byte
        --------------------------------------------------------------------
        reset_dut;

        report "TEST 2: bad first header byte";

        -- Invalid packet: first byte should be AB.
        send_byte_expect_no_valid(x"AA", "bad first header test");
        send_byte_expect_no_valid(x"CD", "bad first header test");
        send_byte_expect_no_valid(x"07", "bad first header test");
        send_byte_expect_no_valid(x"12", "bad first header test");
        send_byte_expect_no_valid(x"34", "bad first header test");
        send_byte_expect_no_valid(x"12", "bad first header test");
        send_byte_expect_no_valid(x"50", "bad first header test");

        in_valid <= '0';
        in_data  <= x"00";

        check_no_out_valid_for_cycles(5, "bad first header test");

        report "TEST 2 PASSED: bad first header rejected";


        --------------------------------------------------------------------
        -- Test 3: bad second header byte
        --------------------------------------------------------------------
        reset_dut;

        report "TEST 3: bad second header byte";

        -- Invalid packet: second byte should be CD, but is CC.
        send_byte_expect_no_valid(x"AB", "bad second header test");
        send_byte_expect_no_valid(x"CC", "bad second header test");
        send_byte_expect_no_valid(x"07", "bad second header test");
        send_byte_expect_no_valid(x"12", "bad second header test");
        send_byte_expect_no_valid(x"34", "bad second header test");
        send_byte_expect_no_valid(x"12", "bad second header test");
        send_byte_expect_no_valid(x"50", "bad second header test");

        in_valid <= '0';
        in_data  <= x"00";

        check_no_out_valid_for_cycles(5, "bad second header test");

        report "TEST 3 PASSED: bad second header rejected";


        --------------------------------------------------------------------
        -- End simulation
        --------------------------------------------------------------------
        report "ALL TESTS PASSED";

        wait for 5 * CLK_PERIOD;
        assert false report "Simulation finished" severity failure;

    end process;

end Behavioral;
