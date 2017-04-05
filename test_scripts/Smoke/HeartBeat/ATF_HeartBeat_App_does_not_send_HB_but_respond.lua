--  Requirement summary:
--  [HeartBeat][Genivi]: SDL must track sending of HeartBeat_request from/to mobile app
--
--  Description:
--  Check that no heartbeat occurs if App uses v3 protocol version and doesn't send HB to SDL, 
--  but response to SDL heartbeat requests in time or less than HB timeout.

--  1. Used precondition
--  SDL, HMI are running.
--  Mobile device is connected.
--  HeartBeatTimeout = 5000
--
--  2. Performed steps
--  Start SPT, select transport, specify protocols = 3
--  sendHeartbeatToSDL = false
--  answerHeartbeatFromSDL = true
--  Wait 15 sec.
--
--  Expected behavior:
--  1. App has successfully registered.
--  2. App is still registered on HU, no unexpected disconnect occurs.

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 3
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()
commonPreconditions:BackupFile("smartDeviceLink.ini")

function Test:StartSDL_And_Connect_Mobile()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Start_Session_And_Register_App()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", 5000)
  self.mobileSession.sendHeartbeatToSDL = false
  self.mobileSession.answerHeartbeatFromSDL = true
  self.mobileSession.ignoreSDLHeartBeatACK = false
  self.mobileSession:StartRPC():Do(function()
    local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
      { application = { appName = default_app_params.appName}}):Do(function(_,data)
      default_app_params.hmi_app_id = data.params.application.appID
    end)
    self.mobileSession:ExpectResponse(correlation_id, {success = true, resultCode = "SUCCESS"})
    self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    self.mobileSession:ExpectNotification("OnPermissionsChange", {})  
  end)
end

function Test.Wait_15_seconds()
  commonTestCases:DelayedExp(15000)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered"):Times(0)
end

function Test:Verify_That_App_Still_Registered()
  local cor_id = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params)
  self.mobileSession:ExpectResponse(cor_id, { success = false, resultCode = "APPLICATION_REGISTERED_ALREADY"})
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
  StopSDL()
end

return Test