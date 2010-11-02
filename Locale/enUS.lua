-- ------------------------------------------------------------------------------------- --
-- 					Scroll Master - AddOn by Sapu (sapu94@gmail.com)			 		 --
--             http://wow.curse.com/downloads/wow-addons/details/slippy.aspx             --
-- ------------------------------------------------------------------------------------- --

-- Scroll Master Locale - enUS
-- Please use the Localization App on CurseForge to Update this
-- http://wow.curseforge.com/addons/slippy/localization/

local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("TradeSkillMaster", "enUS", true)
if not L then return end

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ New TSM Strings ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["No modules are currently loaded.  Enable or download some for full functionality!"] = true
L["No help provided"] = true
L["<command name>"] = true
L["Help for commands specific to this module"] = true
L["Shows this help listing"] = true


-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ General Prases ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["Slash Commands"] = true
L["opens the main Scroll Master window to the 'Enchants' main page."] = true
L["scans the AH for scrolls and materials to calculate profits."] = true
L["opens the main Scroll Master window to the 'Options' page."] = true
L["opens the main Scroll Master window to the 'Help' page."] = true
L["scan"] = true
L["config"] = true
L["help"] = true

L["Enchants"] = true
L["Enchant"] = true
L["Scroll"] = true
L["2H Weapon"] = true
L["Boots"] = true
L["Bracers"] = true
L["Bracer"] = true
L["Chest"] = true
L["Cloak"] = true
L["Gloves"] = true
L["Shield"] = true
L["Staff"] = true
L["Weapon"] = true
L["Wands"] = true

L["Scroll Master - Run Scan"] = true
L["Selected enchant costs were successfully exported to APM3."] = true
L["Percent to subtract from buyout when calculating profits (5% will compensate for AH cut)."] = true
L["Profit Deduction"] = true


-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ GUI Module ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["Are you sure you want to delete the selected profile?"] = true
L["Accept"] = true
L["Cancel"] = true
L["This will overwrite your current settings. Are you sure you want to do this?"] = true

L["Totals"] = true
L["Materials"] = true
L["Totals / Queue"] = true
L["Options"] = true
L["Profiles"] = true
L["Add Enchants"] = true
L["Remove Enchants"] = true
L["Help"] = true
L["About"] = true

L["Links (clickable)"] = true
L["How many of this scroll would you like to craft?"] = true
L["Craft:"] = true
L["You have %s%s|r of this scroll on the AH, %s%s|r in your bags, and %s%s|r in your alts' bags."] = true
L["None on AH"] = true
L["Cost to Craft: "] = true
L["Lowest Buyout on AH: "] = true
L["Profit: "] = true
L["All enchants for this slot have been hidden. Go to the options to change this."] = true
L["Show enchants with '???' profit in main 'Enchants' page."] = true
L["Estimate cost of all materials you do not have: "] = true

L["Status"] = true
L["%sScroll scan last run at %s local time.%s"] = true
L["Scroll scan has not been run yet this session. As a result, the lowest buyouts and profits will not be shown within the 'Enchants' pages."] = true
L["%sMaterial scan last run at %s local time.%s"] = true
L["Material scan has not been run yet this session."] = true
L["Material scanning has been disabled in the options."] = true
L["Use the links on the left to select which page to show."] = true
L["Export Enchant Costs to APM3"] = true
L["Scroll Master can export its data to APM3's threshold and fallback prices as well as create groups inside of APM3 with the push of a button."] = true
L["Scroll Master use Auctioneer's data for material prices. You can select to use Market Price, Appraiser, or Lowest Buyout from Auctioneer."] = true
L["Scroll Master can get data from DataStore about what items you have in your alts bags / banks as well as your guild banks."] = true

L["Reset Craft Queue"] = true
L["Show Queue"] = true
L["Grand Master Enchanting not found! Craft Queue Disabled!"] = true
L["Your craft queue is empty!"] = true

L["If you add the names of your alts below, Scroll Master will include any auctions by them as your own auctions and include their inventory in the 'Enchants' summaries. Note: You must enter the names before you scan."] = true
L["Show Minimap Icon"] = true
L["Include Vellums in Costs"] = true
L["Sort Enchants by Profit"] = true
L["Layout of 'Enchants' Section"] = true
L["Show Links / Number Crafted in Enchants Section of Scroll Master"] = true
L["Add Alt Name"] = true
L["List of Alt Names Stored"] = true
L["<No Alts Stored>"] = true
L["Delete Character"] = true

L["Default"] = true
L["You can change the active database profile, so you can have different settings for every character."] = true
L["Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."] = true
L["Reset Profile"] = true
L["You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."] = true
L["New"] = true
L["Create a new empty profile."] = true
L["Existing Profiles"] = true
L["Copy the settings from one existing profile into the currently active profile."] = true
L["Copy From"] = true
L["Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."] = true
L["Delete a Profile"] = true
L["Delete"] = true
L["Profiles"] = true
L["Current Profile: "] = true
L["Manage Enchants"] = true

L["Automatically open Scroll Master when the scan is complete."] = true
L["Smart Average (recommended)"] = true
L["Lowest Buyout"] = true

L["Enchanting was not found so this page has not been loaded."] = true
L["Use the 'Add' buttons below to add enchants to Scroll Master."] = true
L["Add Enchant"] = true
L["%s crafted to date"] = true
L["Queue Enchants Automatically"] = true
L["Maximum Number to Queue"] = true
L["Build Craft Queue"] = true
L["Include Scrolls on AH When Restocking"] = true
L["Characters to include:"] = true
L["Guilds to include:"] = true

L["Set Minimum Profit (in gold)"] = true
L["Minimum Profit (in gold)"] = true
L["Clicking on the button below will add all enchants with a profit of at least %s gold to the craft queue. Enough will be added to the queue in order to restock you to a total of %s of each scroll. These values can be changed in the options."] = true
L["Clicking on the button below will add enough of every enchant to the craft queue in order to restock you to a total of %s of each scroll. These values can be changed in the options."] = true
L["%sYou need %s out of %s."] = true
L["Lock Cost"] = true
L["Here, you can view and change the material prices. If scanning for materials is enabled in the options, Scroll Master will update these values with the results of the scan. If you lock the cost of a material it will not be changed by Scroll Master."] = true
L["Filters and searches have been cleared in order to craft this enchant."] = true
L["On this page you can change the settings Scroll Master uses with interacting with addons that is integrates with."] = true
L["Percent Increase"] = true
L["Here, you can set options for exporting to APM3. Hover over each setting for more information."] = true
L["The 'Percent Increase' slider is for setting a minimum profit you want to make as a percent. A 5% increase will compensate for AH cut. For example, if it cost 95g to make an item and you sell it for 100g, you will break even after AH cut. Setting an increase of 5% would set the threshold of an item that costs 95g to make to 100g."] = true
L["All thresholds will be set to at least the value of this slider. For example, if the slider is set to 50, anything that costs less than 50g to make will have its threshold set to 50g. Use 1 if you don't want this option applied."] = true
L["Minimum Threshold (in gold)"] = true
L["Scroll Master can set fallback prices as well as threshold prices when exporting to APM3 if this option is enabled."] = true
L["This is the percent of threshold prices that fallbacks will be set to. For example, if the threshold is 50g for an item and this slider is set to 200%, the fallback will be set to 100g."] = true
L["Not Loaded"] = true
L["Loaded"] = true
L["Select which enchant costs you would like to export and then when you click on the button Scroll Master will automatically set APM3's thresholds (and fallbacks if enabled) for the chosen enchants to Scroll Master's cost values according to the options set in the 'Auction Profit Master 3' part of the 'External Options' page."] = true
L["If Auctioneer is selected in the main 'Options' page, this Auctioneer method will be used. The default method is Market Price."] = true
L["Auctioneer Price Method"] = true
L["You can choose to have Scroll Master use data from Auctioneer for material costs (not scrolls) in the main 'Options' page. Use the dropdown below to select which Auctioneer price to use if Auctioneer is selected in the main 'Options' page."] = true
L["If Auctioneer is selected in the main 'Options' page, this Auctioneer method will be used. The default method is Market Value."] = true
L["Market Value"] = true
L["Appraiser Price"] = true
L["Minimum Buyout"] = true
L["General Settings"] = true
L["Enchant / Scroll Data Settings"] = true
L["Appearance Settings"] = true
L["Alternate Character Settings"] = true
L["Build Craft Queue Settings"] = true
L["The main enchants page will display any enchants with a profit over this amount of gold. For example, if the slider is set to 30, any enchant with a profit above 30g will be shown in the main 'Enchants' page."] = true
L["Get Mat Prices From:"] = true
L["Manual Entry"] = true
L["If unchecked, enchants will be sorted by spellID."] = true
L["This is how Scroll Master will get material prices. Smart Average will use Scroll Master's scan data and average functions to determine the prices (recommneded). Lowest buyout will use Scroll Master's scan data and set mat prices to the lowest buyout for each mat on the AH. You can also manually set mat prices or use Auctioneer (if Auc-Advanced is enabled) for mat prices. Chooseing either Manual or Auctioneer will cause Scroll Master to not scan the AH for mats."] = true
L["Checking this will include the cost of vellums when calculating scroll costs."] = true
L["Automatically go to 'Totals / Queue' page after building the craft queue."] = true
L["When you use the Build Craft Queue button, it will queue enough of each enchant so that you will have the desired maximum quantity on hand. If you check this checkbox, anything that you have on the AH as of the last scan will be included in the number you currently have on hand."] = true
L["Enables / Disables the Minimum Profit (in gold) slider below."] = true
L["When you click on the 'Build Craft Queue' button enough of each enchant will be queued so that you have this maximum number on hand. For example, if you have 2 of scroll X on hand and you set this to 4, 2 more will be added to the craft queue."] = true
L["Include Bags"] = true
L["Include Banks"] = true
L["Include Guild Banks"] = true
L["Includes the bags of all your alts."] = true
L["Includes the banks of all your alts."] = true
L["Includes the guild banks of all your alts."] = true
L["Scroll Master can use DataStore_Containers to provide data for a number of different places inside Scroll Master. Use the settings below to set up how you want DataStore used."] = true
L["If checked, Scroll Master will include scrolls on your alts (through datastore) when determining how many of each scroll to queue."] = true
L["Use DataStore for the 'Build Craft Queue' button."] = true
L["Use DataStore when calculating totals."] = true
L["If checked, any materials you have on your alts will be subtracted from the number needed."] = true
L["Use DataStore on the enchant pages."] = true
L["If checked, DataStore will be used to determine how many scrolls you have on your alts to be be shown in the enchant pages."] = true
L["Lowest Profit for Main 'Enchants' Page (in gold)"] = true
L["Lowest Profit for Main 'Enchants' Page (% of profit)"] = true
L["The main enchants page will display any enchant with a profit over this percent of the cost. For example, if the slider is set to 50, and an enchant cost 100g to make, it would only be shown if the profit were 50g or higher."] = true
L["Percent of Cost"] = true
L["Gold Amount"] = true
L["Minimum Profit Method"] = true
L["You can select to set the minimum profit for the main 'Enchants' page as either a gold amount or as a percent of the cost of the enchant."] = true
L["Clicking on the button below will add all enchants with a profit of at least %s percent of the cost to the craft queue. Enough will be added to the queue in order to restock you to a total of %s of each scroll. These values can be changed in the options."] = true
L["Minimum Profit (in %)"] = true
L["If enabled, any enchant with a profit over this value will be added to the craft queue when you use the 'Build Craft Queue' button."] = true
L["If enabled, any enchant with a profit over this percent of the cost will be added to the craft queue when you use the 'Build Craft Queue' button."] = true
L["No Minimum"] = true
L["You can choose to specify a minimum profit amount (in gold or by percent of cost) for what enchants should be added to the craft queue."] = true
L["The number you need accounts for how many you have on alts through DataStore. You can turn this off in the 'External Settings' page."] = true
L["Click on the 'Delete' button next to any enchant you would like to remove from Scroll Master. You can always re-add any enchant you have deleted."] = true
L["(or higher)"] = true
L["You have not trained %s. It has been removed from Scroll Master."] = true

L["This part of Scroll Master is not compatible with Skillet. You must disable Skillet while adding new enchants to Scroll Master."] = true
L["Scroll Master is not completely compatible with ATSW so the craft queue may need to be moved manually. You can turn this warning off in the options."] = true

L["How to use Scroll Master:"] = true
L["Go to the %sauction house%s and type %s then wait for the scan to finish. Once the scan is done, you can view / change the resulting material costs in the %s section of the main window."] = true
L["Click on the various enchant groups and scroll through to find which ones are profitable."] = true
L["Type %s to open up the main window."] = true
L["Check the boxes of the enchants you want to add to the queue."] = true
L["Visit the %s section of the main window to make sure the prices have been set reasonably and completely."] = true
L["Click on the %s section to view the total number of materials needed."] = true
L["Once you have all of a certain material in your bag, that line should turn from red to green."] = true
L["Click the %s button to show the craft queue."] = true
L["Simply click on the name of each enchant inside the queue to make each scroll."] = true
L["Craft away!"] = true

L["Scroll Master is an %s addon."] = true
L["Author"] = true
L["Hosted @ http://wow.curse.com/downloads/wow-addons/details/slippy.aspx (or search curse for scroll master)."] = true
L["If you have a question / suggestion / error to report please do so as either a curse comment at the above url or a message to me @ http://www.mmo-champion.com (username is Sapu94)."] = true
L["Items in Craft Queue: "] = true
L["Estimated Total Profit from Queued Items: "] = true

L["Adding New Groups to APM3"] = true
L["APM3 was not found so this page did not load to prevent errors."] = true
L["The following enchants do not have groups setup for them inside APM3. Using the 'Add' buttons below will have Scroll Master create a group automatically for that enchant. The name of the group will be the name of the enchant and no settings will be be set for the enchant."] = true
L["Add Group"] = true
L["Uncheck All"] = true
L["Check All"] = true
L["Set Fallback Prices to a % of Threshold Prices"] = true
L["Enable Exporting of Fallback Prices"] = true

L["Please clear all filters from your enchanting tradeskill window and try showing the craft queue again."] = true
L["Status Page"] = true
L["Craft Next Enchant"] = true
L["Combine / Split Essences"] = true
L["Percent and Gold Amount"] = true
L["opens Scroll Master's craft queue."] = true
L["craft"] = true
L["3rd Party Addons"] = true
L["General"] = true
L["Data"] = true
L["Queue Maximum Profit"] = true
L["Clicking on the button below will add enchants to the craft queue that will make you the most possible profit for a total mat cost of %s gold or under. No enchant with a profit under %s gold will be included."] = true
L["Queue Maximum Profit for Set Gold Amount"] = true
L["Queue Maximum Profit Settings"] = true
L["These options control the 'Queue Maximum Profit' button on the Status page."] = true
L["These options control the 'Build Craft Queue' button on the Status page."] = true
L["The Minimum Profit must be lower than the Maxium Total Cost!"] = true
L["Maximum Total Cost (in gold)"] = true
L["Minimum Profit to Include"] = true
L["When you click on the 'Queue Maximum Profit' button, the most profitable enchants will be added to the craft queue up to this amount of gold in total mat costs."] = true
L["No enchant below this minimum profit will be added to the craft queue when you hit the 'Queue Maximum Profit' button. This value must be lower than the Maximum Total Cost."] = true
L["Clicking on the button below will add all enchants with a profit of at least %s gold and atleast %s percent of the cost to the craft queue. Enough will be added to the queue in order to restock you to a total of %s of each scroll. These values can be changed in the options."] = true
L["Use Advanced Totals Page."] = true
L["If checked, the totals page will show additional information obtained from DataStore."] = true
L["Material Name (clickable link)           Have:[%s][%s][%s]  Need:%s  Total:%s (%s = This character's bags and bank; %s = Alts bags and banks; %s = Guild Banks)"] = true
L["Extra data from DataStore is being shown according to the following format:"] = true
L["%sHave:%s[%s][%s][%s]   %sNeed:%s   Total:%s"] = true

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ Enchanting Module ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["Craft Queue"] = true
L["ERROR: Could not update queue after craft! Please report this error!"] = true


-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ Data Module ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["Craft Queue Reset"] = true


-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ Scan Module ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["Auction house must be open in order to scan."] = true
L["Error: AuctionHouse window busy."] = true
L["Scan interupted due to auction house being closed."] = true
L["Scan complete!"] = true
L["Scroll Master - Scanning"] = true
L["AM"] = true
L["PM"] = true


-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ Main Module ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["%sLeft-Click%s to open the main window"] = true
L["%sRight-click%s to open the options menu"] = true
L["%sDrag%s to move this button"] = true
L["%s/sm%s for a list of slash commands"] = true
L["Loaded %s successfully!"] = true