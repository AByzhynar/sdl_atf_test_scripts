--Note: Update PendingRequestsAmount =3 in .ini file
-------------------------------------------------------------------------------------------------
------------------------------------------- Automated preconditions -----------------------------
-------------------------------------------------------------------------------------------------
local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

  
function DeleteLog_app_info_dat_policy()
    commonSteps:CheckSDLPath()
    local SDLStoragePath = config.pathToSDL .. "storage/"

    --Delete app_info.dat and log files and storage
    if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
      os.remove(config.pathToSDL .. "app_info.dat")
    end

    if commonSteps:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
      os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
    end

    if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
      os.remove(SDLStoragePath .. "policy.sqlite")
    end

    if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      os.remove(config.pathToSDL .. "policy.sqlite")
    end
print("path = " .."rm -r " ..config.pathToSDL .. "storage")
    os.execute("rm -r " ..config.pathToSDL .. "storage")
end


function Precondition_ArchivateINI()
    commonPreconditions:BackupFile("smartDeviceLink.ini")
end

function Precondition_PendingRequestsAmount()
    local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")
    local StringToReplace = "PendingRequestsAmount = 3\n"
    f = assert(io.open(SDLini, "r"))
    if f then
        fileContent = f:read("*all")

        fileContentUpdated  =  string.gsub(fileContent, "%p?PendingRequestsAmount%s-=%s?[%w%d;]-\n", StringToReplace)

        if fileContentUpdated then
          f = assert(io.open(SDLini, "w"))
          f:write(fileContentUpdated)
        else 
          userPrint(31, "Finding of 'PendingRequestsAmount = value' is failed. Expect string finding and replacing of value to true")
        end
        f:close()
    end
end
DeleteLog_app_info_dat_policy()
Precondition_ArchivateINI()
Precondition_PendingRequestsAmount()
-------------------------------------------------------------------------------------------------
------------------------------------------- END Automated preconditions -------------------------
-------------------------------------------------------------------------------------------------

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
APIName = "ListFiles" -- use for above required scripts.

local TooManyPenReqCount = 0

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end


--///////////////////////////////////////////////////////////////////////////--
--Script cheeks TOO_MANY_PENDING_REQUEST resultCode in SetGlobalProperties response from SDL
--///////////////////////////////////////////////////////////////////////////--

--1. Activate application
commonSteps:ActivationApp()
	
--2. PutFiles	
commonSteps:PutFile("FutFile_action_png", "action.png")


local function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 100)
end

--///////////////////////////////////////////////////////////////////////////--
--Check TOO_MANY_PENDING_REQUEST resultCode in SetGlobalProperties response from HMI
  function Test:SetGlobalProperties_TooManyPendingRequest()

  	--Sending 15 SetGlobalProperties requests
  	for n = 1, 15 do
		--mobile side: SetGlobalProperties request  
		local cid = self.mobileSession:SendRPC("SetGlobalProperties",
		{
			menuTitle = "Menu Title",
			timeoutPrompt = 
			{
				{
					text = "Timeout prompt",
					type = "TEXT"
				}
			},
			vrHelp = 
			{
				{
					position = 1,
					image = 
					{
						value = "action.png",
						imageType = "DYNAMIC"
					},
					text = "VR help item"
				}
			},
			menuIcon = 
			{
				value = "action.png",
				imageType = "DYNAMIC"
			},
			helpPrompt = 
			{
				{
					text = "Help prompt",
					type = "TEXT"
				}
			},
			vrHelpTitle = "VR help title",
			keyboardProperties = 
			{
				keyboardLayout = "QWERTY",
				keypressMode = "SINGLE_KEYPRESS",
				limitedCharacterList = 
				{
					"a"
				},
				language = "EN-US",
				autoCompleteText = "Daemon, Freedom"
			}
		})
		
	  end

    --expect response SetGlobalProperties
    EXPECT_RESPONSE("SetGlobalProperties")
    	:ValidIf(function(exp,data)
			if 
				data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
		    		TooManyPenReqCount = TooManyPenReqCount+1
		    		print(" \27[32m SetGlobalProperties response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
					return true
			elseif 
			   	exp.occurences == 15 and TooManyPenReqCount == 0 then 
			  		print(" \27[36m Response SetGlobalProperties with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
		  			return false
			elseif 
		  		data.payload.resultCode == "GENERIC_ERROR" then
		    		print(" \27[32m SetGlobalProperties response came with resultCode GENERIC_ERROR \27[0m")
		    		return true
			else
		    	print(" \27[36m SetGlobalProperties response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
		    	return false
			end
		end)
		:Times(15)
		:Timeout(15000)
 

    --expect absence of OnAppInterfaceUnregistered
    EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
    :Times(0)

    --expect absence of BasicCommunication.OnAppUnregistered
    EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
    :Times(0)

   DelayedExp()
  end

function Test:Postcondition_RestoreINI()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
end