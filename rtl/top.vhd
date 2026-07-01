
-- market_data_top
--
-- Top-level connecting:
--   1. market_packet_parser
--   2. signal_engine
--
-- Data flow:
--   input byte stream -> packet_parser -> bid/ask prices -> signal engine -> action
--
-- The parser parses:
--   instrument
--   bid_price
--   ask_price
--
-- The signal engine uses:
--   bid_price
--   ask_price
--   buy_threshold
--   sell_threshold
--
-- outputs:
--   00 = IGNORE
--   01 = BUY
--   10 = SELL


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity market_data_top is
    Port ( 
        clk             : in std_logic;
        rst             : in std_logic;
        
        in_valid        : in std_logic;    
        in_data         : in std_logic_vector( 7 downto 0);
        
        buy_threshold   : in std_logic_vector ( 15 downto 0);
        sell_threshold  : in std_logic_vector ( 15 downto 0);
        
        
        parsed_valid   : out std_logic;
        instrument     : out std_logic_vector(7 downto 0);
        bid_price      : out std_logic_vector(15 downto 0);
        ask_price      : out std_logic_vector(15 downto 0);
        
        action_valid   : out std_logic;
        signal_action  : out std_logic_vector(1 downto 0) 

    );
end market_data_top;

architecture Behavioral of market_data_top is
    signal parser_instrument    : std_logic_vector (7 downto 0);
    signal parser_bid_price     : std_logic_vector (15 downto 0);
    signal parser_ask_price     : std_logic_vector (15 downto 0);
    signal parser_out_valid     : std_logic; 
    
begin

    u_parser : entity work.market_packet_parser 
        port map(
            clk         => clk,
            rst         => rst,
            
            in_valid    => in_valid,
            in_data     => in_data,
            
            out_valid   => parser_out_valid, 
            instrument  => parser_instrument,
            bid_price   => parser_bid_price,
            ask_price   => parser_ask_price
        );    
            
    u_signal_engine : entity work.signal_engine
        port map(
            clk => clk,
            rst => rst,
            
            in_valid => parser_out_valid,
            bid_price => parser_bid_price,
            ask_price => parser_ask_price,
            
            buy_threshold => buy_threshold,
            sell_threshold => sell_threshold,
            action_valid => action_valid,
            signal_action => signal_action
        );
        
        

parsed_valid    <= parser_out_valid;
instrument      <= parser_instrument;
bid_price       <= parser_bid_price;
ask_price       <= parser_ask_price;
        
                    

end Behavioral;
