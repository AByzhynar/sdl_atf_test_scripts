---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/28
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Notification_about_changes_to_Destination_or_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [OnWayPointChange] As a mobile application I want to be able to be notified on changes
-- to Destination or Waypoints based on my subscription
--
-- Description:
-- In case:
-- 1) SDL and HMI are started, Navi interface and embedded navigation source are available on HMI,
--    mobile applications are registered on SDL and subscribed on destination and waypoints changes notification
-- 2) Any change in destination or waypoints is registered on HMI (user set new route, canselled the route,
--    arrived at destination point or crossed a waypoint) with parameters upper boundary values

-- SDL must:
-- 1) Transfer the notification about changes to destination or waypoints to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local string200 = string.rep("LA", 100)
local string500 = string.rep("LA", 250)
local string65535 = string.rep("L", 65535)

local notification = {
    wayPoints = {
        {
            coordinate = {
                longitudeDegrees = 180.0,
                latitudeDegrees = 90.0
                        },
            locationName = string500,
            addressLines = { string500, string500,
                             string500, string500
                           },
            locationDescription = string500,
            phoneNumber = string500,
            locationImage = {
                value = string65535,
                imageType = "DYNAMIC",
                        },
            searchAddress = {
                countryName = string200,
                countryCode = string200,
                postalCode = string200,
                administrativeArea = string200,
                subAdministrativeArea = string200,
                locality = string200,
                subLocality = string200,
                thoroughfare = string200,
                subThoroughfare = string200
                        }
                }
        }
}


    --[[ Local Functions ]]
    local function onWayPointChange(self)
        self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
        self.mobileSession1:ExpectNotification( "OnWayPointChange", notification )
    end

    --[[ Scenario ]]
    runner.Title("Preconditions")
    runner.Step("Clean environment", common.preconditions)
    runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
    runner.Step("RAI, PTU", common.registerAppWithPTU)
    runner.Step("Activate App", common.activateApp)
    runner.Step("Subscribe OnWayPointChange", common.subscribeWayPoints)

    runner.Title("Test")
    runner.Step("OnWayPointChange", onWayPointChange)

    runner.Title("Postconditions")
    runner.Step("Stop SDL", common.postconditions)


