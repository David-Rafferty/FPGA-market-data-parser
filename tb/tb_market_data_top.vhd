library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_market_data_top is
end tb_market_data_top;

architecture Behavioral of tb_market_data_top is

    signal clk            : std_logic := '0';
    signal rst            : std_logic := '0';

    signal in_valid       : std_logic := '0';
    signal in_data        : std_logic_vector(7 downto 0) := (others => '0');

    signal buy_threshold  : std_logic_vector(15 downto 0) := (others => '0');
    signal sell_threshold : std_logic_vector(15 downto 0) := (others => '0');

    signal parsed_valid   : std_logic;
    signal instrument     : std_logic_vector(7 downto 0);
    signal bid_price      : std_logic_vector(15 downto 0);
    signal ask_price      : std_logic_vector(15 downto 0);

    signal action_valid   : std_logic;
    signal signal_action  : std_logic_vector(1 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    constant ACTION_IGNORE : std_logic_vector(1 downto 0) := "00";
    constant ACTION_BUY    : std_logic_vector(1 downto 0) := "01";
    constant ACTION_SELL   : std_logic_vector(1 downto 0) := "10";

begin

    --------------------------------------------------------------------
    -- Unit under test: full parser + signal engine system
    --------------------------------------------------------------------
    uut: entity work.market_data_top
        port map (
            clk            => clk,
            rst            => rst,

            in_valid       => in_valid,
            in_data        => in_data,

            buy_threshold  => buy_threshold,
            sell_threshold => sell_threshold,

            parsed_valid   => parsed_valid,
            instrument     => instrument,
            bid_price      => bid_price,
            ask_price      => ask_price,

            action_valid   => action_valid,
            signal_action  => signal_action
        );


    --------------------------------------------------------------------
    -- Clock generator
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;


    --------------------------------------------------------------------
    -- Test stimulus
    --------------------------------------------------------------------
    stim_process : process

        procedure reset_dut is
        begin
            rst            <= '1';
            in_valid       <= '0';
            in_data        <= x"00";
            buy_threshold  <= x"0000";
            sell_threshold <= x"0000";

            wait for 3 * CLK_PERIOD;

            wait until rising_edge(clk);
            wait for 1 ns;
            rst <= '0';

            wait until rising_edge(clk);
            wait for 1 ns;

            assert parsed_valid = '0'
                report "ERROR: parsed_valid should be low after reset"
                severity error;

            assert action_valid = '0'
                report "ERROR: action_valid should be low after reset"
                severity error;

            assert signal_action = ACTION_IGNORE
                report "ERROR: signal_action should be IGNORE after reset"
                severity error;
        end procedure;


        procedure send_byte(
            byte_value : in std_logic_vector(7 downto 0)
        ) is
        begin
            in_data  <= byte_value;
            in_valid <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;


        procedure send_valid_packet(
            instr_in : in std_logic_vector(7 downto 0);
            bid_in   : in std_logic_vector(15 downto 0);
            ask_in   : in std_logic_vector(15 downto 0)
        ) is
        begin
            send_byte(x"AB");
            send_byte(x"CD");
            send_byte(instr_in);
            send_byte(bid_in(15 downto 8));
            send_byte(bid_in(7 downto 0));
            send_byte(ask_in(15 downto 8));
            send_byte(ask_in(7 downto 0));

            in_valid <= '0';
            in_data  <= x"00";
        end procedure;


        procedure wait_for_parsed_valid(
            max_cycles : in natural;
            test_name  : in string
        ) is
            variable cycles_waited : natural := 0;
        begin
            while parsed_valid /= '1' and cycles_waited < max_cycles loop
                wait until rising_edge(clk);
                wait for 1 ns;
                cycles_waited := cycles_waited + 1;
            end loop;

            assert parsed_valid = '1'
                report "ERROR: " & test_name & " timed out waiting for parsed_valid"
                severity error;
        end procedure;


        procedure wait_for_action_valid(
            max_cycles : in natural;
            test_name  : in string
        ) is
            variable cycles_waited : natural := 0;
        begin
            while action_valid /= '1' and cycles_waited < max_cycles loop
                wait until rising_edge(clk);
                wait for 1 ns;
                cycles_waited := cycles_waited + 1;
            end loop;

            assert action_valid = '1'
                report "ERROR: " & test_name & " timed out waiting for action_valid"
                severity error;
        end procedure;


        procedure check_no_valid_for_cycles(
            cycles    : in positive;
            test_name : in string
        ) is
        begin
            for i in 1 to cycles loop
                wait until rising_edge(clk);
                wait for 1 ns;

                assert parsed_valid = '0'
                    report "ERROR: " & test_name & " unexpectedly asserted parsed_valid"
                    severity error;

                assert action_valid = '0'
                    report "ERROR: " & test_name & " unexpectedly asserted action_valid"
                    severity error;
            end loop;
        end procedure;


        procedure run_top_test(
            test_name       : in string;
            instr_expected  : in std_logic_vector(7 downto 0);
            bid_expected    : in std_logic_vector(15 downto 0);
            ask_expected    : in std_logic_vector(15 downto 0);
            buy_thr_in      : in std_logic_vector(15 downto 0);
            sell_thr_in     : in std_logic_vector(15 downto 0);
            expected_action : in std_logic_vector(1 downto 0)
        ) is
        begin
            report "Running " & test_name;

            buy_threshold  <= buy_thr_in;
            sell_threshold <= sell_thr_in;

            send_valid_packet(
                instr_expected,
                bid_expected,
                ask_expected
            );

            wait_for_parsed_valid(10, test_name);

            assert instrument = instr_expected
                report "ERROR: " & test_name & " parsed wrong instrument"
                severity error;

            assert bid_price = bid_expected
                report "ERROR: " & test_name & " parsed wrong bid_price"
                severity error;

            assert ask_price = ask_expected
                report "ERROR: " & test_name & " parsed wrong ask_price"
                severity error;

            wait_for_action_valid(10, test_name);

            assert signal_action = expected_action
                report "ERROR: " & test_name & " produced wrong signal_action"
                severity error;

            wait until rising_edge(clk);
            wait for 1 ns;

            assert action_valid = '0'
                report "ERROR: " & test_name & " action_valid should return low"
                severity error;

            report test_name & " PASSED";
        end procedure;

    begin

        ----------------------------------------------------------------
        -- Test 1: full system BUY case
        ----------------------------------------------------------------
        reset_dut;

        -- Packet:
        -- AB CD 07 12 34 12 50
        --
        -- Parsed:
        -- instrument = 0x07
        -- bid_price  = 0x1234
        -- ask_price  = 0x1250
        --
        -- BUY condition:
        -- ask_price 0x1250 < buy_threshold 0x1260
        run_top_test(
            "TEST 1: TOP BUY case",
            x"07",
            x"1234",
            x"1250",
            x"1260",
            x"1300",
            ACTION_BUY
        );


        ----------------------------------------------------------------
        -- Test 2: full system SELL case
        ----------------------------------------------------------------
        reset_dut;

        -- SELL condition:
        -- bid_price 0x1350 > sell_threshold 0x1300
        run_top_test(
            "TEST 2: TOP SELL case",
            x"08",
            x"1350",
            x"1360",
            x"1200",
            x"1300",
            ACTION_SELL
        );


        ----------------------------------------------------------------
        -- Test 3: full system IGNORE case
        ----------------------------------------------------------------
        reset_dut;

        -- Neither condition is true:
        -- ask_price 0x1250 is not below buy_threshold 0x1200
        -- bid_price 0x1234 is not above sell_threshold 0x1300
        run_top_test(
            "TEST 3: TOP IGNORE case",
            x"09",
            x"1234",
            x"1250",
            x"1200",
            x"1300",
            ACTION_IGNORE
        );


        ----------------------------------------------------------------
        -- Test 4: bad first header byte
        ----------------------------------------------------------------
        reset_dut;

        report "Running TEST 4: TOP bad first header case";

        buy_threshold  <= x"1260";
        sell_threshold <= x"1300";

        send_byte(x"AA"); -- bad first header byte
        send_byte(x"CD");
        send_byte(x"07");
        send_byte(x"12");
        send_byte(x"34");
        send_byte(x"12");
        send_byte(x"50");

        in_valid <= '0';
        in_data  <= x"00";

        check_no_valid_for_cycles(10, "TEST 4: TOP bad first header case");

        report "TEST 4: TOP bad first header case PASSED";


        ----------------------------------------------------------------
        -- End simulation
        ----------------------------------------------------------------
        report "ALL TOP MODULE TESTS PASSED";

        wait for 5 * CLK_PERIOD;
        assert false report "Simulation finished" severity failure;

    end process;

end Behavioral;