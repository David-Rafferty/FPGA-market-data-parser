library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_signal_engine is
end tb_signal_engine;

architecture Behavioral of tb_signal_engine is
    
    signal clk              : std_logic := '0';
    signal rst              : std_logic := '0';
    
    signal in_valid         : std_logic := '0';
    signal ask_price        : std_logic_vector (15 downto 0) := (others => '0');
    signal bid_price        : std_logic_vector (15 downto 0) := (others => '0');
    
    signal buy_threshold    : std_logic_vector (15 downto 0) := (others => '0');
    signal sell_threshold   : std_logic_vector (15 downto 0) := (others => '0');
    
    signal action_valid     : std_logic := '0';
    signal signal_action    : std_logic_vector (1 downto 0) := "00";
    
    constant CLK_PERIOD     : time := 10 ns;
    constant ACTION_IGNORE  : std_logic_vector (1 downto 0) := "00";
    constant ACTION_BUY     : std_logic_vector (1 downto 0) := "01";
    constant ACTION_SELL    : std_logic_vector  (1 downto 0) := "10";
    
begin


    uut: entity work.signal_engine
        port map (
            clk             => clk,
            rst             => rst,
            in_valid        => in_valid,
            buy_threshold   => buy_threshold,
            sell_threshold  => sell_threshold,
            bid_price       => bid_price,
            ask_price       => ask_price, 
            action_valid    => action_valid,
            signal_action   => signal_action
        );
        
    --------------------------------------------------------------------
    -- Clock generator at 100MHz 
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
        rst             <= '1';
        in_valid        <= '0';
        bid_price       <= x"0000";
        ask_price       <= x"0000";
        buy_threshold   <= x"0000";
        sell_threshold  <= x"0000";
        
        wait for 3 * CLK_PERIOD;
        
        wait until rising_edge(clk);
        wait for 1ns;
        rst <= '0';
        
        wait until rising_edge(clk);
        wait for 1ns;
        
        assert action_valid = '0'
            report "ERROR: actiob_valid should be low after a reset."
            severity error;
        
        assert signal_action = ACTION_IGNORE
            report "ERROR: signal_action should hold a value of ACTION_IGNORE after reset."
            severity error;
    end procedure;   
     
     
    procedure apply_test_case( 
        test_name           : in string;
        bid_in              : in std_logic_vector (15 downto 0);
        ask_in              : in std_logic_vector (15 downto 0);
        buy_thr_in          : in std_logic_vector (15 downto 0);
        sell_thr_in         : in std_logic_vector (15 downto 0);
        expected_action     : in std_logic_vector (1 downto 0)
    ) is 
    begin
        report "Running" & test_name; 
        
        bid_price       <= bid_in;
        ask_price       <= ask_in;
        buy_threshold   <= buy_thr_in;
        sell_threshold  <= sell_thr_in;
        in_valid        <= '1';
        
        wait until rising_edge(clk);
        wait for 1ns;
        
        assert action_valid = '1'
            report "ERROR: " & test_name & " did not set action_valid high"
            severity error;
            
        assert signal_action = expected_action
            report "ERROR: " & test_name & " did produce expected signal_action"
            severity error;
            
        in_valid <= '0';
        
        wait until rising_edge(clk);
        wait for 1 ns;
        
        assert action_valid = '0'
            report "ERROR: " & test_name & " did not set action_valid back to low"
            severity error;
            
        report test_name & "PASSED";
    end procedure;
        
begin

    --------------------------------------------------------------------
    -- Reset Test
    --------------------------------------------------------------------
    reset_dut;
    report "RESET TEST PASSED";
    
    
    --------------------------------------------------------------------
    -- Buy test
    --------------------------------------------------------------------
    apply_test_case(
        "TEST 1: BUY case",
        x"1234",
        x"1250",
        x"1260",
        x"1300",
        ACTION_BUY
    );
    
    --------------------------------------------------------------------
    -- Sell test
    --------------------------------------------------------------------
          
    apply_test_case(
        "TEST 2: SELL case",
        x"1350",
        x"1360",
        x"1200",
        x"1300",
        ACTION_SELL
    );
    
    
    --------------------------------------------------------------------
    -- Ignore test
    --------------------------------------------------------------------
    apply_test_case(
            "TEST 3: IGNORE case",
            x"1234",        -- bid_price
            x"1250",        -- ask_price
            x"1200",        -- buy_threshold
            x"1300",        -- sell_threshold
            ACTION_IGNORE
    );
    
    
    --------------------------------------------------------------------
    -- priority test
    --------------------------------------------------------------------
    apply_test_case(
            "TEST 4: BUY priority case",
            x"1400",        -- bid_price, above sell threshold
            x"1100",        -- ask_price, below buy threshold
            x"1200",        -- buy_threshold
            x"1300",        -- sell_threshold
            ACTION_BUY
    );
    
    --------------------------------------------------------------------
    -- End stimulation
    --------------------------------------------------------------------
    report "ALL SIGNAL ENGINE TESTS PASSED";
    
    wait for 5 * CLK_PERIOD;
    
    assert false
        report "Simulation finished"
        severity failure;
    
  end process;
    
end Behavioral;
