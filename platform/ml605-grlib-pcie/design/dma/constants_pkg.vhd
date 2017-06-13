-- Common DMA constants as defined in the Northwest DMA verilog description.
package constants is
  -- ---------------
  -- -- Constants --
  -- ---------------

  -- Note: None of the following constant values are intended to be modified by the user
  constant  CORE_DATA_WIDTH         : integer := 64;    -- Width of input and output data
  constant  CORE_BE_WIDTH           : integer := 8;     -- Width of input and output K
  constant  CORE_REMAIN_WIDTH       : integer := 3;     -- 2^CORE_REMAIN_WIDTH represents the number of bytes in CORE_DATA_WIDTH

  constant  XIL_DATA_WIDTH          : integer := CORE_DATA_WIDTH;
  constant  XIL_STRB_WIDTH          : integer := CORE_BE_WIDTH;

  constant  RQ_TAG_WIDTH            : integer := 3;                        -- Number of tag bits implemented by the S2C DMA Engine Reorder Queues
  constant  TAG_WIDTH               : integer := RQ_TAG_WIDTH + 1;         -- Number of tags bits implemented by Completion Monitor
  constant  NUM_TAGS                : integer := (2 ** RQ_TAG_WIDTH) + 2;  -- Number of tags implemented by Completion Monitor; must be 2^RQ_TAG_WIDTH+2

  constant  CARD_ADDR_WIDTH         : integer := 64;   -- Maximum DMA Card address width
  constant  BYTE_COUNT_WIDTH        : integer := 13;
  constant  DESC_ADDR_WIDTH         : integer := 64;   -- Maximum Descriptor Pointer address width

  constant  DESC_STATUS_WIDTH       : integer := 160;

  constant  DESC_WIDTH              : integer := 256;

  -- Register byte addresses 0x1FFF-0x0000 are reserved for up to 32 System to Card DMA Register Blocks;
  --   Each Register Block is 256 bytes; the first Register Block must be placed at 0x0000; subsequent
  --   Register Blocks are placed every 256 bytes; software can determine the number of present
  --   Register Blocks by reading the Capabilities register at all of the possible locations
  -- reg_wr_addr and reg_rd_addr are CORE_DATA_WIDTH addresses rather than byte addresses;
  --   define the Register Block offsets in terms of CORE_DATA_WIDTH
  constant  REG_BASE_ADDR_S2C0_0    : integer := 16#00#;
  constant  REG_BASE_ADDR_S2C1_0    : integer := 16#20#;
  constant  REG_BASE_ADDR_S2C2_0    : integer := 16#40#;
  constant  REG_BASE_ADDR_S2C3_0    : integer := 16#60#;

  -- Register byte addresses 0x3FFF-0x2000 are reserved for up to 32 Card to System DMA Register Blocks;
  --   Each Register Block is 256 bytes; the first Register Block must be placed at 0x2000; subsequent
  --   Register Blocks are placed every 256 bytes; software can determine the number of present
  --   Register Blocks by reading the Capabilities register at all of the possible locations
  -- reg_wr_addr and reg_rd_addr are CORE_DATA_WIDTH addresses rather than byte addresses;
  --   define the Register Block offsets in terms of CORE_DATA_WIDTH
  constant  REG_BASE_ADDR_C2S0_0    : integer := 16#400#;
  constant  REG_BASE_ADDR_C2S1_0    : integer := 16#420#;
  constant  REG_BASE_ADDR_C2S2_0    : integer := 16#440#;
  constant  REG_BASE_ADDR_C2S3_0    : integer := 16#460#;
  constant  REG_BASE_ADDR_C2S4_0    : integer := 16#480#;
  constant  REG_BASE_ADDR_C2S5_0    : integer := 16#4A0#;

  -- The DMA Common Register Block is at 0x4000 offset into BAR0
  constant  REG_BASE_ADDR_COMMON    : integer := 16#800#;

  -- User Registers are located at BAR0: Byte Address 0x8000 and above
  constant  REG_BASE_ADDR_USER      : integer := 16#1000#;

  --
  constant DEVICE_SN               : integer := 0;

  constant REG_ADDR_WIDTH          : integer := 12 + (4 - CORE_REMAIN_WIDTH);
end constants;
