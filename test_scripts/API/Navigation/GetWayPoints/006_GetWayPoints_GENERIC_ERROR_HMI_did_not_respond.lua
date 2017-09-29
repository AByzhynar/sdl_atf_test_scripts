---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Exception 5: HMI did not respond during default timeout
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid and allowed by Policies GetWayPoints_request to SDL
--    and HMI did not respond during default timeout
-- SDL must:
-- 1) SDL responds GENERIC_ERROR, success:false to mobile application

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function getWayPoints(self)
  local params = {
    wayPointType = "ALL"
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
      return data.params.appID == commonNavigation.getHMIAppId()
    end)
  :Do(function()
     -- HMI does not respond
    end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})
  commonTestCases:DelayedExp(11000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints, HMI did not respond", getWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
