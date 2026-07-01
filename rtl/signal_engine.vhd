------- Signal Engine ----------
--  
-- Currently a simple decision block for the parser
--
-- Inputs:
--  buy_threshold   =   threshold that any ask price below or equal to this ask price triggers Buy 
--  sell_threshold  =   threshold that any bid price above or equal to this bid price triggers sell
--  Ask Price       =   Best current ask price for the instrument
--  Bid Price       =   Best current bid price 
--  
--Output encoding:
--  00 = IGNORE
--  01 = BUY
--  10 = SELL
--
-- The output is registered, then when in_valid is high the engine takes the  
-- prices and thresholds, computes what to do and then finally pulses action_valid
-- high for one clock cycle


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity signal_engine is
    Port (
        clk             : in std_logic;
        rst             : in std_logic;
      
        in_valid        : in std_logic;
        bid_price       : in std_logic_vector (15 downto 0); 
        ask_price       : in std_logic_vector (15 downto 0);
        
        buy_threshold   : in std_logic_vector (15 downto 0);
        sell_threshold  : in std_logic_vector (15 downto 0);      
        
        action_valid    : out std_logic := '0';
        signal_action   : out std_logic_vector (1 downto 0)
    );
end signal_engine;


architecture Behavioral of signal_engine is

    constant ACTION_IGNORE  : std_logic_vector (1 downto 0) := "00";
    constant ACTION_BUY     : std_logic_vector (1 downto 0) := "01"; 
    constant ACTION_SELL    : std_logic_vector (1 downto 0) := "10";    
    
begin

    process(clk)
    begin
        
        if rising_edge(clk) then
            if rst = '1' then  
                action_valid  <= '0';
                signal_action <= ACTION_IGNORE;    
            
            else 
                -- Default State --
                action_valid <= '0';
                
                if in_valid = '1' then
                    action_valid <= '1';
                    
                    if unsigned(ask_price) < unsigned(buy_threshold) then
                        signal_action <= ACTION_BUY;
                
                    elsif unsigned(bid_price) > unsigned(sell_threshold) then
                        signal_action <= ACTION_SELL;
                        
                    else 
                        signal_action <= ACTION_IGNORE;
                
                    end if;
                end if;                     
            end if;        
        end if;
    end process;    
    
end Behavioral;
