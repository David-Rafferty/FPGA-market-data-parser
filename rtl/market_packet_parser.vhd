-- market_packet_parser
--
-- Parses a simple market-data packet from an 8-bit input stream.
--
-- Packet format, one byte per clock cycle:
--
--   Byte 0: 0xAB          -- magic/header byte 1
--   Byte 1: 0xCD          -- magic/header byte 2
--   Byte 2: instrument ID -- 8-bit instrument identifier
--   Byte 3: bid high byte
--   Byte 4: bid low byte
--   Byte 5: ask high byte
--   Byte 6: ask low byte
--
-- Example packet:
--
--   AB CD 07 12 34 12 50
--
-- Expected parsed output:
--
--   instrument = 0x07
--   bid_price  = 0x1234
--   ask_price  = 0x1250
--
-- out_valid pulses high for one clock cycle after the full packet has been
-- received and the output fields are valid.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity market_packet_parser is
    Port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        in_valid   : in  std_logic;
        in_data    : in  std_logic_vector(7 downto 0);

        out_valid  : out std_logic;
        instrument : out std_logic_vector(7 downto 0);
        bid_price  : out std_logic_vector(15 downto 0);
        ask_price  : out std_logic_vector(15 downto 0)
    );
end market_packet_parser;

architecture Behavioral of market_packet_parser is

-- List of all states in the FSM, need 2 states
-- for the Prices as they are 16 bits long each.
    type state_type is (
        IDLE,
        READ_MAGIC,
        READ_INSTRUMENT,
        READ_BID_HIGH,
        READ_BID_LOW,
        READ_ASK_HIGH,
        READ_ASK_LOW,
        OUTPUT_RESULT,
        ERROR_STATE
    );

    signal state : state_type := IDLE;

    signal instrument_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal bid_price_reg  : std_logic_vector(15 downto 0) := (others => '0');
    signal ask_price_reg  : std_logic_vector(15 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
        
            if rst = '1' then
                state          <= IDLE;
                out_valid      <= '0';
                instrument_reg <= (others => '0');
                bid_price_reg  <= (others => '0');
                ask_price_reg  <= (others => '0');

            else
                out_valid <= '0';

                case state is

                    when IDLE =>
                        if in_valid = '1' then
                            if in_data = x"AB" then
                                state <= READ_MAGIC;
                            else
                                state <= ERROR_STATE;
                            end if;
                        end if;

                    when READ_MAGIC =>
                        if in_valid = '1' then
                            if in_data = x"CD" then
                                state <= READ_INSTRUMENT;
                            else
                                state <= ERROR_STATE;
                            end if;
                        end if;

                    when READ_INSTRUMENT =>
                        if in_valid = '1' then
                            instrument_reg <= in_data;
                            state <= READ_BID_HIGH;
                        end if;
                        
                    when READ_BID_HIGH =>
                        if in_valid = '1' then
                            bid_price_reg(15 downto 8) <= in_data;
                            state <= READ_BID_LOW;
                        end if;
                        
                    when READ_BID_LOW =>
                        if in_valid = '1' then
                            bid_price_reg(7 downto 0) <= in_data;
                            state <= READ_ASK_HIGH;
                        end if;
                    
                    when READ_ASK_HIGH =>
                        if in_valid = '1' then 
                            ask_price_reg(15 downto 8) <= in_data;
                            state <= READ_ASK_LOW;
                        end if;
                        
                    when READ_ASK_LOW =>
                        if in_valid = '1' then 
                            ask_price_reg(7 downto 0) <= in_data;
                            state <= OUTPUT_RESULT;
                        end if;

                    when OUTPUT_RESULT =>
                        out_valid <= '1';
                        state <= IDLE;

                    -- if an error is detected discard current packet and go back to the idle state
                    when ERROR_STATE =>
                        state <= IDLE;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

    instrument <= instrument_reg;
    bid_price  <= bid_price_reg;
    ask_price  <= ask_price_reg;
    
end Behavioral;
