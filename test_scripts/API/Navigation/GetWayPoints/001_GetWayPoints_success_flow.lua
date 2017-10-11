---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid and allowed by Policies GetWayPoints_request to SDL
-- SDL must:
-- 1) Transfer GetWayPoints_request to HMI
-- 2) Respond with <resultCode> received from HMI to mobile application
-- 3) Provide the requested parameters at the same order as received from HMI
--    to mobile application (in case of successfull response)

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

local response = {
  wayPoints = {
    {
      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      },
      locationName = "Hotel",
      addressLines =
      {
        "Hotel Bora",
        "Hotel 5 stars"
      },
      locationDescription = "VIP Hotel",
      phoneNumber = "Phone39300434",
      locationImage =
      {
        value ="icon.png",
        imageType ="DYNAMIC",
      },
      searchAddress =
      {
        countryName = "countryName",
        countryCode = "countryCode",
        postalCode = "postalCode",
        administrativeArea = "administrativeArea",
        subAdministrativeArea = "subAdministrativeArea",
        locality = "locality",
        subLocality = "subLocality",
        thoroughfare = "thoroughfare",
        subThoroughfare = "subThoroughfare"
      }
    },
    {
      coordinate =
      {
        latitudeDegrees = 88,
        longitudeDegrees = 176
      },
      locationName = "Home",
      addressLines =
      {
        "Street, 36"
      },
      locationDescription = "Home",
      phoneNumber = "46788974",
      locationImage =
      {
        value ="icon.png",
        imageType ="DYNAMIC",
      },
      searchAddress =
      {
        countryName = "countryname",
        countryCode = "countrycode",
        postalCode = "postalcode",
        administrativeArea = "administrativearea",
        subAdministrativeArea = "subAdministrativearea",
        locality = "locality",
        subLocality = "sublocality",
        thoroughfare = "thoroughfare",
        subThoroughfare = "subthoroughfare"
      }
    }
  }
}

--[[ Local Functions ]]
local function GetWayPoints(pWayPointType, self)
  local params = {
    wayPointType = pWayPointType
  }

  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  response.appID = common.getHMIAppId()

  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
      return data.params.appID == common.getHMIAppId()
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function(_, data) -- checking order of wayPoints
      for k in pairs(data.payload.wayPoints) do
        local actualCoordinate = data.payload.wayPoints[k].coordinate
        local expectedCoordinate = response.wayPoints[k].coordinate
        if (actualCoordinate.latitudeDegrees ~= expectedCoordinate.latitudeDegrees) or
          (actualCoordinate.longitudeDegrees ~= expectedCoordinate.longitudeDegrees) then
          return false, "WayPoints order is not as expected"
        end
      end
      return true
    end)
  :ValidIf(function(_, data) -- checking data of wayPoints
      for k in pairs(data.payload.wayPoints) do
        if not commonFunctions:is_table_equal(data.payload.wayPoints[k], response.wayPoints[k]) then
          return false, "Waypoints data is not as expected"
        end
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, wayPointType in pairs({ "ALL", "DESTINATION" }) do
  runner.Step("GetWayPoints, wayPointType " .. wayPointType, GetWayPoints, { wayPointType })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)