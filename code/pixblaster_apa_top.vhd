-----------------------------------------------------------------------------------------------------------
--
-- Copyright 2018-2020 - Pixblasters.com
-- All rights reserved - Sva prava pridr�ana  
--
-----------------------------------------------------------------------------------------------------------
--
-- This file is part of the Pixblasters_Light APA102 LED Demo.

-- Pixblasters_Light APA102 Demo is free software: you can redistribute it and/or
-- modify it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- Pixblasters_Light APA102 Demo is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with Pixblasters_Light Demo.  If not, see <https://www.gnu.org/licenses/>.
--
-----------------------------------------------------------------------------------------------------------
--
-- The design can be implemented with the FREE Xilinx� ISE� WebPack�, the fully featured front-to-back
-- FPGA design solution for Linux, Windows XP, and Windows 7. Design is tested with the version 14.7 that
-- can be downloaded from here: https://www.xilinx.com/products/design-tools/ise-design-suite/ise-webpack.html  
--
--
-- NOTE! The demo design requires the DVI video receiver IP core. The Pixblasters team use the Xilinx 
-- Xilinx DVI receiver code. Check-out the Xilinx Application Note
-- XAPP495: "Implementing a TMDS Video Interface in the Spartan-6 FPGA" at the following link
-- https://www.xilinx.com/support/documentation/application_notes/xapp495_S6TMDS_Video_Interface
-- In your designs you can use other DVI receivers, but make sure to provide parallel RGB video input
-- into Pixblasters_Light IP core.
--
-- Download the xapp495.zip with the necessary DVI RX source code from here: 
-- https://secure.xilinx.com/webreg/clickthrough.do?cid=154258 
--
-- Follow implementation instructions from the readme.txt file distributed with the code.
--
----------------------------------------------------------------------------------------------------------
--  Version   Date          Description
--
--  v1.0    11.11.2018.  Top-level design for the Pixblasters FPGA micro demo
--  v2.0    18.07.2020.  Top-level design adapted for APA102 (4-wire SPI) LED strips                                                           
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Description:
--
--  The top level design of the Pixblasters-Light Demo LED controller. It includes the pixblasters_light
--  IP core, instantiates the DVI video input receiver and the necessary clocking infrastructure.
--  The design is fully compatible with the Pixblasters MS1 Video LED Strip Controller board. It can be also
--  adapted for use with third-party Xilinx FPGA based boards. The supported Pixblasters_Light Demo features:  
--
--    - 16 LED strips controller - 8192 RGB APA102 and compatible 4-wire LEDs
--    - max. 512 LEDs per line
--    - supports 60 fps vertical refresh
--    - RGB888 pixel format - 16M full colors
--    - The LEDs max. display's resolution is 512 x 16 (H x V)
--    - The controller crops the input video and shows the selected cropping window
--    - The top left corner of the LED video output set by TOP_LEFT_X & TOP_LEFT_Y
--    - The length of the LED display line set by LINE_LENGTH (max 512) 
--    - Pixblasters MS1 board's chaining, on-board micro and some other advanced features are not supported  
--    - enables LED brightness control, 4-wire clocking speed and control of the number of trailing 1s
--      that clears out the LED strip
-------------------------------------------------------------------------------
--                               LIBRARIES
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
--                                ENTITY
-------------------------------------------------------------------------------

entity pixblaster_apa_top is
   generic (
   	  TRAILER               : integer := 16;  -- defines the length of the End Frame (TRAILER * 32 clocks)
	                                          -- rule of thumb => add half of clock period per pixel in the strip
	  BRIGTH                : integer := 31;  -- global brightness level; 31 is the brightest!
	  DIVIDE_CLK            : integer :=  3;  -- sets up LED_CLK. Valid values 0-3; Default value 1 => 12MHz SPI intf.
	                                          -- 0 => 24 MHz
											  -- 1 => 12 MHz
											  -- 2 =>  6 MHz
											  -- 3 =>  3 MHz
      LINE_LENGTH           : integer := 400; -- defines the length of the display line in pixels - max 512
   	  TOP_LEFT_X            : integer := 815; -- defines the x coordinate of the LED display's top left pixel
	  TOP_LEFT_Y            : integer := 330  -- defines the y coordinate of the LED display's top left pixel
      );
   port (
 	  osc_24mhz             : in  std_logic;    -- from an on-board quartz oscillator

	  -- DVI Video input
	  tmds_in               : in  std_logic_vector(3 downto 0);
      tmdsb_in              : in  std_logic_vector(3 downto 0);

	  hdmi_present          : in  std_logic;

      -- LED strips out
      led_out               : out std_logic_vector(15 downto 0);
	  led_clk               : out std_logic_vector(15 downto 0)
	  );
end pixblaster_apa_top;

-------------------------------------------------------------------------------
--                             ARCHITECTURE
-------------------------------------------------------------------------------

architecture rtl of pixblaster_apa_top is

-------------------------------------------------------------------------------
--                             COMPONENTS
-------------------------------------------------------------------------------
	
	component pixblaster_apa_light is
	   generic (
	   	  TRAILER               : integer := 31;  -- defines the length of the End Frame (TRAILER * 32 clocks)
	      BRIGTH                : integer := 31;  -- global brightness level; 31 is the brightest!
		  DIVIDE_CLK            : integer :=  1;  -- sets up LED_CLK. Valid values 0-3; Default value 1 => 12MHz SPI intf.
	      LINE_LENGTH           : integer := 512; -- defines the length of the display line in pixels - max 512
	      TOP_LEFT_X            : integer := 0;   -- defines the x coordinate of the LED display's top left pixel
	      TOP_LEFT_Y            : integer := 0    -- defines the y coordinate of the LED display's top left pixel
		  );
	   port (

		  mclk                  : in  std_logic; -- main clock
		  strip_clk             : in  std_logic; -- set to 48 MHz in this demo
		  clock_lock            : in  std_logic; -- high when all DCM modules locked	
 
		  -- Parallel Video Input
		  pix_clk               : in  std_logic;
		  pix_hsync             : in  std_logic;
		  pix_vsync             : in  std_logic;
		  pix_de                : in  std_logic;
		  pix_data              : in  std_logic_vector(23 downto 0);

		  video_valid           : in  std_logic; -- valid signal from the DVI encoder module
		  hdmi_present          : in  std_logic;

		  -- LED strips out
		  led_out               : out std_logic_vector(15 downto 0);
		  led_clk               : out std_logic_vector(15 downto 0)
		  );
	end component pixblaster_apa_light;
 
      -- DVI receiver -- instantiated Xilinx DVI receiver code. Check-out the Xilinx Application
	  -- Note XAPP495: "Implementing a TMDS Video Interface in the Spartan-6 FPGA"
	  -- https://www.xilinx.com/support/documentation/application_notes/xapp495_S6TMDS_Video_Interface.pdf
	  -- Read the readme.txt file for implementation instructions.

    component dvi_rx is
       port (
          rstbtn_n : in  std_logic;
          TMDS     : in  std_logic_vector(3 downto 0);
          TMDSB    : in  std_logic_vector(3 downto 0);

          plllckd  : out std_logic;
          reset    : out std_logic;

          pix_clk  : out std_logic;
          hsync    : out std_logic;
          vsync    : out std_logic;
          de       : out std_logic;
          red      : out std_logic_vector(7 downto 0);
          green    : out std_logic_vector(7 downto 0);
          blue     : out std_logic_vector(7 downto 0);
          data_vld : out std_logic;
          data_rdy : out std_logic
       );
    end component;

    ----------------------------------------------------------------------------
    -- A simple clock module that takes the clock input from the on-PCB quartz
    -- oscillator, de-skews it and doubles the frequency to the targeted
    -- 48 MHz clock signal.
	--
	-- Assumed 24 MHz oscillator from the Pixblasters MS 1 board. Make sure to
	-- properly change the code if you use other clocking source.
    ----------------------------------------------------------------------------	
	

	component osc_clock is
        port (
			in_clk                : in  std_logic; --  24   MHz from the on-board quartz
			sclk_clk              : out std_logic; --  25.6 MHz for the LED strips control (WS2812B)
			main_clk              : out std_logic; --  48   MHz for the main logic operation
			clock_lock            : out std_logic  --  high when all DCM modules locked	
       );
    end component osc_clock;

   ----------------------------------------------------------------------------
   -- SIGNALS
   ----------------------------------------------------------------------------

   signal clock_lock        : std_logic;
   signal strip_clk         : std_logic;
   signal mclk              : std_logic; 
   signal data_vld          : std_logic;
   signal data_rdy          : std_logic;
   signal pix_clk           : std_logic;
   signal pix_data          : std_logic_vector(23 downto 0);
   signal pix_de            : std_logic;
   signal pix_hsync         : std_logic;
   signal pix_vsync         : std_logic;
   signal video_valid       : std_logic := '0';

begin -- architecture

    main_clocker: osc_clock
      port map(
		in_clk            => osc_24mhz,    --  24 MHz from the on-board quartz
		sclk_clk          => open,         --  not used; For APA102 we use 48MHz as sclk_clk
		main_clk          => mclk,         --  48 MHz for the main logic operation
		clock_lock        => clock_lock    --  high when all DCM modules locked	
    );

    ----------------------------------------------------------------------------
	-- DVI RX excepts the dvi input and sources the parallel RGB video interface
	-- into the Pixblasters_Light IP core.
	----------------------------------------------------------------------------

    dvi_receiver: dvi_rx
      port map(
         rstbtn_n         => hdmi_present, -- assumed 0 when the video cable is not connected
         TMDS             => tmds_in,
         TMDSB            => tmdsb_in,

         plllckd          => open,
         reset            => open,

         pix_clk          => pix_clk,
         hsync            => pix_hsync,
         vsync            => pix_vsync,
         de               => pix_de,
         red              => pix_data(23 downto 16),
         green            => pix_data(15 downto 8),
         blue             => pix_data(7 downto 0),
         data_vld         => data_vld,
         data_rdy         => data_rdy
    );
	  
	video_valid <= data_rdy and data_vld;

    ----------------------------------------------------------------------------
	-- Pixblasters LED controller for 8192 RGB LEDs
	-- The controller version for the Micro APA102 LED Demo FPGA design
	----------------------------------------------------------------------------	
	pixi: pixblaster_apa_light
	  generic map(
	  	TRAILER           => TRAILER,
	    BRIGTH            => BRIGTH,
		DIVIDE_CLK        => DIVIDE_CLK,
	    LINE_LENGTH       => LINE_LENGTH,
        TOP_LEFT_X        => TOP_LEFT_X,   
        TOP_LEFT_Y        => TOP_LEFT_Y
		)
	  port map(

		mclk              => mclk,
		strip_clk         => mclk,
		clock_lock        => clock_lock,
 
		-- Parallel Video Input
		pix_clk           => pix_clk,      
		pix_hsync         => pix_hsync,    
		pix_vsync         => pix_vsync,    
		pix_de            => pix_de,       
		pix_data          => pix_data,     
                             
		video_valid       => video_valid,  
		hdmi_present      => hdmi_present, 

		-- LED strips out
		led_out           => led_out,
		led_clk           => led_clk
	);

end rtl;

