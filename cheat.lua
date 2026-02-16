local menuVisible = false
local currentCategory = 1
local selectedItem = 1
local currentMode = 'none'
local espActive = false
local espBox = true
local espSkeleton = true
local espDistance = true
local espPseudo = true
local espArme = true
local espPnj = false
local espBoxColor = {r=0, g=0, b=255, a=220} -- Blue neon
local espSkeletonColor = {r=0, g=255, b=255, a=220} -- Cyan neon
local aimbotActive = false
local aimbotFov = 50 -- FOV modifiable (pixels)
local aimbotPnj = false
local silentAim = false
local magicBullet = false
local fastRun = false
local acceleration = 0 -- 0-100 for vehicle accel boost
local carriedVeh = nil
local lastVehicleUpdate = 0
local lastPlayerUpdate = 0
local lastResourceUpdate = 0
local updateInterval = 3000
local maxItemsPerPage = 9
local subMenuActive = false
local subMenuType = nil -- "veh" or "player" or "resource"
local subSelected = 1
local highlightedVeh = nil
local highlightedPlayer = nil
local vehActions = {"Lock", "Unlock", "Steal"}
local playerActions = {"Launch", "Explosion", "Steal Tenue"}
local resourceActions = {"Stop", "Start"}
local godmodeActive = false
local superJumpActive = false
local carryActive = false
local menuLoaded = true -- For unload
local magnitoActive = false
local magnitoPoint = nil
local noclipV2Active = false
local categories = {
{name = "Modes", items = {
{name = "Noclip v2", type = "toggle", mode = "noclip_v2"},
{name = "Godmode", type = "toggle", mode = "godmode"},
{name = "Super Jump", type = "toggle", mode = "superjump"},
{name = "TP Waypoint", type = "button", mode = "tp_waypoint"},
{name = "Carry Vehicle (Y)", type = "toggle", mode = "carry"},
{name = "Fast Run", type = "toggle", mode = "fastrun"},
{name = "Acceleration (0-100)", type = "input_accel"},
{name = "Repair Vehicle", type = "button", mode = "repair_veh"},
{name = "Heal", type = "button", mode = "heal"},
{name = "Magnito", type = "toggle", mode = "magnito"},
{name = "Unload Menu", type = "button", mode = "unload"}
}},
{name = "Give Arme", items = {}},
{name = "Véhicules", items = {}},
{name = "Players", items = {}}, -- Dynamique joueurs 200m
{name = "Resources", items = {}}, -- Dynamique resources
{name = "Aimbot", items = {
{name = "Activer Aimbot", type = "toggle_aimbot"},
{name = "FOV (Input)", type = "input_fov"},
{name = "Silent Aim", type = "toggle_silent"},
{name = "Magic Bullet", type = "toggle_magic"},
{name = "PNJ Option", type = "toggle_aimpnj"}
}},
{name = "ESP", items = {
{name = "Activer ESP", type = "toggle_esp"},
{name = "Box 3D", type = "toggle_box"},
{name = "Squelette", type = "toggle_skeleton"},
{name = "Distance", type = "toggle_distance"},
{name = "Pseudo", type = "toggle_pseudo"},
{name = "Arme", type = "toggle_arme"},
{name = "Voir PNJ", type = "toggle_pnj"}
}}
}

local allWeapons = {
{name="Give All",type="give_all"},
{name="Give All Ammo",type="give_ammo"},
{name="Pistol .50",hash=GetHashKey("WEAPON_PISTOL50")},
{name="AP Pistol",hash=GetHashKey("WEAPON_APPISTOL")},
{name="Assault Rifle",hash=GetHashKey("WEAPON_ASSAULTRIFLE")},
{name="Special Carbine",hash=GetHashKey("WEAPON_SPECIALCARBINE")},
{name="SMG",hash=GetHashKey("WEAPON_SMG")}
}
categories[2].items = allWeapons

Citizen.CreateThread(function()
while menuLoaded do
Citizen.Wait(0)
if IsControlJustPressed(0, 167) then -- F6
menuVisible = not menuVisible
subMenuActive = false
subMenuType = nil
if menuVisible then
SetMouseCursorVisible(true)
SetMouseCursorStyle(0)
SetCursorLocation(0.5, 0.5)
else
SetMouseCursorVisible(false)
if highlightedVeh then
SetEntityDrawOutline(highlightedVeh, false)
highlightedVeh = nil
end
if highlightedPlayer then
highlightedPlayer = nil
end
end
end
end
end)

Citizen.CreateThread(function()
while menuLoaded do
Citizen.Wait(0)
if not menuVisible then goto continue end
SetMouseCursorVisible(true)

DrawRect(0.15, 0.5, 0.32, 0.82, 0, 0, 0, 245) -- fond noir profond
DrawRect(0.15, 0.5, 0.324, 0.824, 0, 0, 255, 130) -- bord néon bleu
DrawRect(0.15, 0.5, 0.328, 0.828, 0, 0, 255, 70) -- glow extérieur bleu
DrawRect(0.15, 0.5, 0.332, 0.832, 255, 0, 0, 40) -- glow secondaire rouge (pour variété)
DrawRect(0.15, 0.28, 0.32, 0.12, 5, 5, 10, 230) -- header sombre + gradient

SetTextFont(7)
SetTextScale(0.78, 0.78)
SetTextColour(0, 0, 255, 255) -- Bleu néon
SetTextDropShadow(0, 0, 0, 0, 255)
SetTextEdge(2, 0, 0, 0, 240)
SetTextEntry("STRING")
AddTextComponentString("~b~MAYZOXE ~b~cheat")
DrawText(0.04, 0.18)

SetTextFont(4)
SetTextScale(0.35, 0.35)
SetTextColour(220, 220, 255, 220)
SetTextEntry("STRING")
AddTextComponentString("↑↓ sélection | ←→ catégories | E activer | Q off")
DrawText(0.04, 0.26)

SetTextFont(4)
SetTextScale(0.50, 0.50)
SetTextColour(0, 0, 255, 255) -- Bleu néon
SetTextDropShadow(0, 0, 0, 0, 180)
SetTextEntry("STRING")
AddTextComponentString(categories[currentCategory].name)
DrawText(0.04, 0.32)
DrawRect(0.15, 0.37, 0.3, 0.008, 0, 0, 255, 200) -- séparateur néon bleu

if subMenuActive then
DrawRect(0.42, 0.5, 0.22, 0.35, 0, 0, 0, 245)
DrawRect(0.42, 0.5, 0.224, 0.354, 0, 0, 255, 130)
local title = (subMenuType == "veh") and "Actions Véhicule" or (subMenuType == "player") and "Actions Joueur" or "Actions Resource"
SetTextFont(4)
SetTextScale(0.48, 0.48)
SetTextColour(255, 255, 255, 255)
SetTextEntry("STRING")
AddTextComponentString(title)
DrawText(0.34, 0.38)
local actions = (subMenuType == "veh") and vehActions or (subMenuType == "player") and playerActions or resourceActions
local baseY = 0.44
local lineH = 0.06
local mouseX, mouseY = GetNuiCursorPosition()
local resX, resY = GetActiveScreenResolution()
local nX = mouseX / resX
local nY = mouseY / resY
for i, act in ipairs(actions) do
local y = baseY + (i-1) * lineH
local sel = (i == subSelected)
local hov = (nX >= 0.34 and nX <= 0.5) and (nY >= y - 0.025 and nY <= y + 0.025)
if hov then
SetMouseCursorStyle(5)
DrawRect(0.42, y + 0.01, 0.2, 0.05, 0, 0, 255, 100) -- Bleu hover
end
if sel then
DrawRect(0.42, y + 0.01, 0.2, 0.05, 0, 0, 255, 140)
end
SetTextFont(4)
SetTextScale(0.42, 0.42)
local r,g,b = 220,220,255
if sel or hov then r,g,b = 255,255,100 end
SetTextColour(r,g,b,255)
SetTextEntry("STRING")
AddTextComponentString((sel and "> " or " ") .. act)
DrawText(0.34, y)
if hov and IsDisabledControlJustPressed(0, 24) then
subSelected = i
if subMenuType == "veh" then
ExecuteVehAction(subSelected)
elseif subMenuType == "player" then
ExecutePlayerAction(subSelected)
else
ExecuteResourceAction(subSelected)
end
end
end
if IsControlJustPressed(0, 172) then -- Up
subSelected = subSelected - 1
if subSelected < 1 then subSelected = #actions end
end
if IsControlJustPressed(0, 173) then -- Down
subSelected = subSelected + 1
if subSelected > #actions then subSelected = 1 end
end
if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 38) then -- Enter/E
if subMenuType == "veh" then
ExecuteVehAction(subSelected)
elseif subMenuType == "player" then
ExecutePlayerAction(subSelected)
else
ExecuteResourceAction(subSelected)
end
end
goto continue
end

local items = categories[currentCategory].items
local baseY = 0.39
local lineHeight = 0.055
local mouseX, mouseY = GetNuiCursorPosition()
local resX, resY = GetActiveScreenResolution()
local normX = mouseX / resX
local normY = mouseY / resY
local start = 1
if #items > maxItemsPerPage then
start = math.floor((selectedItem - 1) / maxItemsPerPage) * maxItemsPerPage + 1
end
for off = 0, math.min(maxItemsPerPage - 1, #items - start) do
local i = start + off
local opt = items[i]
if opt then
local y = baseY + off * lineHeight
local sel = (i == selectedItem)
local hov = (normX >= 0.04 and normX <= 0.26) and (normY >= y - 0.025 and normY <= y + 0.025)
if hov then
SetMouseCursorStyle(5)
DrawRect(0.15, y + 0.01, 0.3, 0.05, 0, 0, 255, 100) -- Bleu hover
end
if sel then
DrawRect(0.15, y + 0.01, 0.3, 0.05, 0, 0, 255, 140)
end
SetTextFont(4)
SetTextScale(0.42, 0.42)
local r,g,b = 220,220,255
if sel or hov then r,g,b = 255,255,100 end
SetTextColour(r,g,b,255)
SetTextEntry("STRING")
local status = ""
if opt.type == "toggle" then
if opt.mode == "noclip_v2" then status = noclipV2Active and "~g~[X]" or "~r~[ ]"
elseif opt.mode == "godmode" then status = godmodeActive and "~g~[X]" or "~r~[ ]"
elseif opt.mode == "superjump" then status = superJumpActive and "~g~[X]" or "~r~[ ]"
elseif opt.mode == "carry" then status = carryActive and "~g~[X]" or "~r~[ ]"
elseif opt.mode == "fastrun" then status = fastRun and "~g~[X]" or "~r~[ ]"
elseif opt.mode == "magnito" then status = magnitoActive and "~g~[X]" or "~r~[ ]"
end
elseif opt.type == "toggle_aimbot" then status = aimbotActive and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_silent" then status = silentAim and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_magic" then status = magicBullet and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_aimpnj" then status = aimbotPnj and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_esp" then status = espActive and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_box" then status = espBox and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_skeleton" then status = espSkeleton and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_distance" then status = espDistance and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_pseudo" then status = espPseudo and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_arme" then status = espArme and "~g~[X]" or "~r~[ ]"
elseif opt.type == "toggle_pnj" then status = espPnj and "~g~[X]" or "~r~[ ]"
elseif opt.type == "input_accel" then status = "~y~" .. acceleration
elseif opt.type == "input_fov" then status = "~y~" .. aimbotFov
end
AddTextComponentString((sel and "> " or " ") .. opt.name .. " " .. status)
DrawText(0.04, y)
if hov and IsDisabledControlJustPressed(0, 24) then -- Mouse click
selectedItem = i
ActivateOption(currentCategory, i)
end
end
end

if #items > maxItemsPerPage then
local pg = "~y~Page " .. math.floor((start - 1) / maxItemsPerPage + 1) .. "/" .. math.ceil(#items / maxItemsPerPage)
SetTextFont(4)
SetTextScale(0.32, 0.32)
SetTextColour(200,200,200,200)
SetTextEntry("STRING")
AddTextComponentString(pg)
DrawText(0.04, 0.76)
end

local st = "~w~Mode: ~y~" .. currentMode .. " ~w~ESP: " .. (espActive and "~g~ON" or "~r~OFF")
SetTextFont(4)
SetTextScale(0.34, 0.34)
SetTextColour(255,255,255,220)
SetTextEntry("STRING")
AddTextComponentString(st)
DrawText(0.04, 0.82)

if IsControlJustPressed(0, 172) then -- Up
selectedItem = selectedItem - 1
if selectedItem < 1 then selectedItem = #items end
UpdateHighlight()
end
if IsControlJustPressed(0, 173) then -- Down
selectedItem = selectedItem + 1
if selectedItem > #items then selectedItem = 1 end
UpdateHighlight()
end
if IsControlJustPressed(0, 174) then -- Left
currentCategory = currentCategory - 1
if currentCategory < 1 then currentCategory = #categories end
selectedItem = 1
UpdateHighlight()
end
if IsControlJustPressed(0, 175) then -- Right
currentCategory = currentCategory + 1
if currentCategory > #categories then currentCategory = 1 end
selectedItem = 1
UpdateHighlight()
end
if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 38) then -- Enter/E
ActivateOption(currentCategory, selectedItem)
end
if IsControlJustPressed(0, 44) then -- Q
currentMode = 'none'
godmodeActive = false
superJumpActive = false
carryActive = false
fastRun = false
espActive = false
aimbotActive = false
end
if currentCategory == 3 and GetGameTimer() - lastVehicleUpdate > updateInterval then
UpdateVehicles()
lastVehicleUpdate = GetGameTimer()
end
if currentCategory == 4 and GetGameTimer() - lastPlayerUpdate > updateInterval then
UpdatePlayers()
lastPlayerUpdate = GetGameTimer()
end
if currentCategory == 5 and GetGameTimer() - lastResourceUpdate > updateInterval then
UpdateResources()
lastResourceUpdate = GetGameTimer()
end
::continue::
end
end)

function UpdateHighlight()
if highlightedVeh then
SetEntityDrawOutline(highlightedVeh, false)
highlightedVeh = nil
end
if highlightedPlayer then
highlightedPlayer = nil
end
if currentCategory == 3 then
local it = categories[3].items[selectedItem]
if it then highlightedVeh = it.veh end
elseif currentCategory == 4 then
local it = categories[4].items[selectedItem]
if it then highlightedPlayer = it.ped end
end
end
Citizen.CreateThread(function()
while menuLoaded do
Citizen.Wait(0)
if highlightedVeh then
SetEntityDrawOutline(highlightedVeh, true)
SetEntityDrawOutlineColor(255, 0, 0, 255)
SetEntityDrawOutlineShader(1)
local vCoords = GetEntityCoords(highlightedVeh)
DrawMarker(1, vCoords.x, vCoords.y, vCoords.z + 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 255, false, true, 2, false, nil, nil, false)
end
if highlightedPlayer then
local pCoords = GetEntityCoords(highlightedPlayer)
DrawMarker(1, pCoords.x, pCoords.y, pCoords.z + 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 255, false, true, 2, false, nil, nil, false)
end
end
end)

function ExecuteVehAction(idx)
local it = categories[3].items[selectedItem]
local veh = it.veh
if veh then
local ch = vehActions[idx]
if ch == "Lock" then
SetVehicleDoorsLocked(veh, 2)
elseif ch == "Unlock" then
SetVehicleDoorsLocked(veh, 1)
elseif ch == "Steal" then
TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
end
end
subMenuActive = false
subMenuType = nil
end

function ExecutePlayerAction(idx)
local it = categories[4].items[selectedItem]
local targetPed = it.ped
if targetPed then
local ch = playerActions[idx]
if ch == "Launch" then
ApplyForceToEntity(targetPed, 1, 0.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
elseif ch == "Explosion" then
local coords = GetEntityCoords(targetPed)
AddExplosion(coords.x, coords.y, coords.z, 2, 1.0, true, false, 1.0)
elseif ch == "Steal Tenue" then
CopyOutfit(targetPed, PlayerPedId())
end
end
subMenuActive = false
subMenuType = nil
end

function ExecuteResourceAction(idx)
local it = categories[5].items[selectedItem]
local res = it.resource
if res then
local ch = resourceActions[idx]
if ch == "Stop" then
ExecuteCommand("stop " .. res)
elseif ch == "Start" then
ExecuteCommand("start " .. res)
end
end
subMenuActive = false
subMenuType = nil
end

function CopyOutfit(sourcePed, targetPed)
local components = {}
for i = 0, 11 do
components[i] = {drawable = GetPedDrawableVariation(sourcePed, i), texture = GetPedTextureVariation(sourcePed, i), palette = GetPedPaletteVariation(sourcePed, i)}
end
local props = {}
for i = 0, 7 do
props[i] = {prop = GetPedPropIndex(sourcePed, i), texture = GetPedPropTextureIndex(sourcePed, i)}
end
for i = 0, 11 do
SetPedComponentVariation(targetPed, i, components[i].drawable, components[i].texture, components[i].palette)
end
for i = 0, 7 do
SetPedPropIndex(targetPed, i, props[i].prop, props[i].texture, true)
end
end

function UpdateVehicles()
local p = PlayerPedId()
local c = GetEntityCoords(p)
local vlist = {}
for _, v in ipairs(GetGamePool('CVehicle')) do
if #(c - GetEntityCoords(v)) < 50 then
local n = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(v))) or "Veh"
table.insert(vlist, {name = n, veh = v})
end
end
categories[3].items = vlist
end

function UpdatePlayers()
local p = PlayerPedId()
local c = GetEntityCoords(p)
local plist = {}
for _, pl in ipairs(GetActivePlayers()) do
local ped = GetPlayerPed(pl)
if ped and #(c - GetEntityCoords(ped)) < 200 and ped ~= p then
local n = GetPlayerName(pl) or "Player inconnu"
table.insert(plist, {name = n, ped = ped, id = GetPlayerServerId(pl)})
end
end
categories[4].items = plist
end

function UpdateResources()
local rlist = {
{name = "Désactiver All", type = "button", mode = "disable_all"}
}
for i = 0, GetNumResources() - 1 do
local res = GetResourceByFindIndex(i)
if res then
table.insert(rlist, {name = res, type = "resource", resource = res})
end
end
categories[5].items = rlist
end

function ActivateOption(cat, idx)
local c = categories[cat]
local it = c.items[idx]
if not it then return end
if c.name == "Modes" then
if it.type == "toggle" then
if it.mode == "noclip_v2" then
noclipV2Active = not noclipV2Active
currentMode = noclipV2Active and "noclip_v2" or "none"
elseif it.mode == "godmode" then
godmodeActive = not godmodeActive
currentMode = godmodeActive and "godmode" or "none"
TriggerEvent('txcl:setPlayerMode', "godmode", godmodeActive)
if not godmodeActive then
TriggerEvent('txcl:setPlayerMode', 'none', false)
end
elseif it.mode == "superjump" then
superJumpActive = not superJumpActive
currentMode = superJumpActive and "superjump" or "none"
elseif it.mode == "carry" then
carryActive = not carryActive
currentMode = carryActive and "carry" or "none"
elseif it.mode == "fastrun" then
fastRun = not fastRun
currentMode = fastRun and "fastrun" or "none"
elseif it.mode == "magnito" then
magnitoActive = not magnitoActive
currentMode = magnitoActive and "magnito" or "none"
end
elseif it.type == "button" then
if it.mode == "repair_veh" then
local veh = GetVehiclePedIsIn(PlayerPedId(), false)
if veh then SetVehicleFixed(veh) end
elseif it.mode == "tp_waypoint" then
local waypoint = GetFirstBlipInfoId(8)
if DoesBlipExist(waypoint) then
local coord = GetBlipInfoIdCoord(waypoint)
SetEntityCoords(PlayerPedId(), coord.x, coord.y, coord.z + 1.0, false, false, false, true)
end
elseif it.mode == "unload" then
menuVisible = false
espActive = false
aimbotActive = false
godmodeActive = false
superJumpActive = false
carryActive = false
fastRun = false
SetMouseCursorVisible(false)
elseif it.mode == "heal" then
TriggerEvent('txcl:heal', GetPlayerServerId(PlayerId()))
end
elseif it.type == "input_accel" then
    acceleration = (acceleration + 50) % 2050  -- Cycle 0 → 50 → ... → 2000 → 0
end
elseif c.name == "Give Arme" then
local ped = PlayerPedId()
if it.type == "give_all" then
for _, wep in ipairs(allWeapons) do
if wep.hash then
GiveWeaponToPed(ped, wep.hash, 999, false, false)
end
end
elseif it.type == "give_ammo" then
for _, wep in ipairs(allWeapons) do
if wep.hash then
SetPedAmmo(ped, wep.hash, 9999)
end
end
else
GiveWeaponToPed(ped, it.hash, 999, false, true)
end
elseif c.name == "Véhicules" then
subMenuActive = true
subMenuType = "veh"
subSelected = 1
elseif c.name == "Players" then
subMenuActive = true
subMenuType = "player"
subSelected = 1
elseif c.name == "Resources" then
if it.type == "resource" then
subMenuActive = true
subMenuType = "resource"
subSelected = 1
elseif it.type == "button" and it.mode == "disable_all" then
local currentRes = GetCurrentResourceName()
for i = 0, GetNumResources() - 1 do
local res = GetResourceByFindIndex(i)
if res and res ~= currentRes and GetResourceState(res) == "started" then
ExecuteCommand("stop " .. res)
end
end
end
elseif c.name == "Aimbot" then
if it.type == "toggle_aimbot" then
aimbotActive = not aimbotActive
elseif it.type == "toggle_silent" then
silentAim = not silentAim
elseif it.type == "toggle_magic" then
magicBullet = not magicBullet
elseif it.type == "toggle_aimpnj" then
aimbotPnj = not aimbotPnj
elseif it.type == "input_fov" then
aimbotFov = (aimbotFov + 10) % 200 -- Cycle for simplicity
end
elseif c.name == "ESP" then
if it.type == "toggle_esp" then espActive = not espActive
elseif it.type == "toggle_box" then espBox = not espBox
elseif it.type == "toggle_skeleton" then espSkeleton = not espSkeleton
elseif it.type == "toggle_distance" then espDistance = not espDistance
elseif it.type == "toggle_pseudo" then espPseudo = not espPseudo
elseif it.type == "toggle_arme" then espArme = not espArme
elseif it.type == "toggle_pnj" then espPnj = not espPnj
end
end
end

Citizen.CreateThread(function()
    while menuLoaded do
        Citizen.Wait(0)
        if not espActive then goto continue end

        local mp = PlayerPedId()
        if not mp or not DoesEntityExist(mp) then goto continue end

        local mc = GetEntityCoords(mp)
        local cam = GetGameplayCamCoord()
        local peds = espPnj and GetGamePool('CPed') or GetActivePlayers()

        for _, p in ipairs(peds) do
            local ped = type(p) == "number" and GetPlayerPed(p) or p
            if not ped or ped == mp or not DoesEntityExist(ped) then goto next_ped end

            local c = GetEntityCoords(ped)
            local d = #(mc - c)
            if d > 200 then goto next_ped end

            -- BOX ESP
            local head = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
            local onHead, sx, sy = World3dToScreen2d(head.x, head.y, head.z + 0.30)
            local onFeet, ex, ey = World3dToScreen2d(c.x, c.y, c.z - 1.0)
            if not (onHead and onFeet and sx and sy and ex and ey) then goto next_ped end

            local height = math.abs(ey - sy)
            local width = height / 2.2
            local centerY = (sy + ey) / 2

            if espBox then
                local r,g,b,a = 200,255,200,220
                DrawRect(sx, sy, width, 0.002, r,g,b,a)
                DrawRect(sx, ey, width, 0.002, r,g,b,a)
                DrawRect(sx - width/2, centerY, 0.002, height, r,g,b,a)
                DrawRect(sx + width/2, centerY, 0.002, height, r,g,b,a)
            end

            -- SKELETON ESP VISIBLE A TRAVERS LE PERSONNAGE
            if espSkeleton then
                local skelColor = {255,255,255,255}
                local bones = {
                    {31086,39317},{39317,24818},{24818,24817},{24817,24816},{24816,23553},{23553,11816},
                    {39317,64729},{64729,45509},{45509,61163},{61163,18905},
                    {39317,10706},{10706,40269},{40269,28252},{28252,57005},
                    {11816,58271},{58271,63931},{63931,14201},
                    {11816,51826},{51826,36864},{36864,52301}
                }

                for _, pair in ipairs(bones) do
                    local b1 = GetPedBoneCoords(ped, pair[1], 0.0,0.0,0.0)
                    local b2 = GetPedBoneCoords(ped, pair[2], 0.0,0.0,0.0)

                    if b1 and b2 then
                        -- direction vers la caméra
                        local dir1 = vector3(b1.x - cam.x, b1.y - cam.y, b1.z - cam.z)
                        local dir2 = vector3(b2.x - cam.x, b2.y - cam.y, b2.z - cam.z)

                        -- normalisation
                        dir1 = dir1 / #(dir1)
                        dir2 = dir2 / #(dir2)

                        -- OFFSET PLUS GRAND pour passer devant le modèle
                        local offset = 0.20  -- augmente si toujours caché
                        local nb1 = vector3(b1.x - dir1.x * offset, b1.y - dir1.y * offset, b1.z - dir1.z * offset)
                        local nb2 = vector3(b2.x - dir2.x * offset, b2.y - dir2.y * offset, b2.z - dir2.z * offset)

                        DrawLine(nb1.x, nb1.y, nb1.z, nb2.x, nb2.y, nb2.z, skelColor[1], skelColor[2], skelColor[3], skelColor[4])
                    end
                end
            end

            local name = type(p)=="number" and GetPlayerName(p) or "PNJ"
            local weapon = GetSelectedPedWeapon(ped)
            local weaponName = (weapon and weapon ~= -1569615261) and GetLabelText(GetWeapontypeModel(weapon)) or "Aucune"

            if espPseudo then
                SetTextFont(4); SetTextScale(0.0,0.30)
                SetTextColour(255,255,255,255); SetTextCentre(true); SetTextOutline()
                SetTextEntry("STRING"); AddTextComponentString(name)
                DrawText(sx, sy - 0.035)
            end

            if espDistance or espArme then
                SetTextFont(4); SetTextScale(0.0,0.26)
                SetTextColour(255,255,255,255); SetTextOutline()
                local txt = espDistance and (math.floor(d).."m") or ""
                if espArme then txt = txt .. (txt~="" and " - " or "") .. weaponName end
                SetTextEntry("STRING"); AddTextComponentString(txt)
                DrawText(sx - width/2 + 0.005, ey + 0.008)
            end

            local health,maxHealth = GetEntityHealth(ped),GetEntityMaxHealth(ped)
            if health and maxHealth and maxHealth > 0 then
                local pct = health/maxHealth
                local barX = sx + width/2 + 0.010
                DrawRect(barX, centerY, 0.003, height, 0,0,0,220)
                DrawRect(barX, centerY - (height*(1-pct))/2, 0.003, height*pct, 50,255,50,255)
            end

            ::next_ped::
        end
        ::continue::
    end
end)
Citizen.CreateThread(function()
    while menuLoaded do
        Citizen.Wait(0)
        if not aimbotActive then goto continue end

        local screenW, screenH = GetActiveScreenResolution()
        local centerX, centerY = screenW / 2.0, screenH / 2.0
        local fovRadius = (aimbotFov * screenW) / 120.0

        -- Cercle FOV (léger)
        local segments = 64
        for i = 0, segments - 1 do
            local a1 = (i / segments) * 2 * math.pi
            local a2 = ((i + 1) / segments) * 2 * math.pi
            local x1 = centerX + math.cos(a1) * fovRadius
            local y1 = centerY + math.sin(a1) * fovRadius
            local x2 = centerX + math.cos(a2) * fovRadius
            local y2 = centerY + math.sin(a2) * fovRadius
            DrawRect((x1+x2)/2/screenW, (y1+y2)/2/screenH, math.abs(x2-x1)/screenW, math.abs(y2-y1)/screenH, 255,255,255,70)
        end

        local ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then goto continue end
        local pedCoords = GetEntityCoords(ped)

        local weapon = GetSelectedPedWeapon(ped)
        if weapon == -1569615261 then goto continue end

        local boneName = "SKEL_Head"  -- Principal
        local offsetX = 0.0
        local offsetY = 0.0
        local offsetZ = -0.12         -- Ajuste ici : -0.08 / -0.12 / -0.15 / -0.20 jusqu'à ce que le debug montre pile centre tête

        local targets = aimbotPnj and GetGamePool('CPed') or GetActivePlayers()
        local closestPed = nil
        local closestDist = fovRadius

        for _, entry in ipairs(targets) do
            local target = type(entry) == "number" and GetPlayerPed(entry) or entry

            if target ~= ped 
            and DoesEntityExist(target) 
            and not IsPedDeadOrDying(target, true) 
            and #(pedCoords - GetEntityCoords(target)) <= 120.0 then

                local boneIndex = GetEntityBoneIndexByName(target, boneName)
                if boneIndex == -1 then
                    -- Fallback si SKEL_Head foire (rare)
                    boneIndex = GetEntityBoneIndexByName(target, "SKEL_Neck_1")
                    offsetZ = 0.15  -- Pour neck → offset positif
                end

                if boneIndex ~= -1 then
                    local bone = GetPedBoneCoords(target, boneIndex, offsetX, offsetY, offsetZ)
                    local onScreen, sx, sy = World3dToScreen2d(bone.x, bone.y, bone.z)

                    if onScreen then
                        local dx = (sx - 0.5) * screenW
                        local dy = (sy - 0.5) * screenH
                        local pxDist = math.sqrt(dx*dx + dy*dy)

                        if pxDist < closestDist then
                            closestDist = pxDist
                            closestPed = target
                        end
                    end
                end
            end
        end

        -- DEBUG VISUEL (supprime après test)
        if closestPed then
            local boneIndex = GetEntityBoneIndexByName(closestPed, boneName)
            if boneIndex == -1 then boneIndex = GetEntityBoneIndexByName(closestPed, "SKEL_Neck_1") end
            if boneIndex ~= -1 then
                local bone = GetPedBoneCoords(closestPed, boneIndex, offsetX, offsetY, offsetZ)
                -- Ligne verte verticale sur le point lock
                DrawLine(bone.x, bone.y, bone.z - 2.0, bone.x, bone.y, bone.z + 2.0, 0, 255, 0, 255, 3.0)
                -- Sphere rouge au point exact
                DrawMarker(28, bone.x, bone.y, bone.z, 0,0,0, 0,0,0, 0.08, 0.08, 0.08, 255, 0, 0, 180, false, true, 2, false, false, false, false)
            else
                -- Bone pas trouvé → carré rouge écran
                DrawRect(0.5, 0.5, 0.15, 0.15, 255, 0, 0, 220)
            end
        end

        if closestPed and IsControlPressed(0, 25) then
            local boneIndex = GetEntityBoneIndexByName(closestPed, boneName)
            if boneIndex == -1 then boneIndex = GetEntityBoneIndexByName(closestPed, "SKEL_Neck_1") end
            if boneIndex ~= -1 then
                local targetBone = GetPedBoneCoords(closestPed, boneIndex, offsetX, offsetY, offsetZ)
                local dx = targetBone.x - pedCoords.x
                local dy = targetBone.y - pedCoords.y
                local dz = targetBone.z - pedCoords.z

                local hypot = math.sqrt(dx*dx + dy*dy + dz*dz)
                if hypot < 1.0 then goto continue end

                local targetHeading = GetHeadingFromVector_2d(dx, dy)
                local targetPitch = math.deg(math.asin(dz / hypot))

                SetGameplayCamRelativeHeading(targetHeading - GetEntityHeading(ped))
                SetGameplayCamRelativePitch(targetPitch, 1.0)
            end
        end

        ::continue::
    end
end)
Citizen.CreateThread(function() -- Godmode
while menuLoaded do
Citizen.Wait(0)
if godmodeActive then
SetEntityInvincible(PlayerPedId(), true)
else
SetEntityInvincible(PlayerPedId(), false)
end
end
end)
Citizen.CreateThread(function() -- Super Jump
while menuLoaded do
Citizen.Wait(0)
if superJumpActive then
SetSuperJumpThisFrame(PlayerId())
end
end
end)
Citizen.CreateThread(function() -- Carry Vehicle
while menuLoaded do
Citizen.Wait(0)
if carryActive then
if IsControlJustPressed(0, 246) then -- Y
if carriedVeh then

DetachEntity(carriedVeh, false, true)
ApplyForceToEntity(carriedVeh, 1, 0.0, 50.0, 20.0, 0.0, 0.0, 0.0, 0, true, true, true, true, true)
carriedVeh = nil
else

local ped = PlayerPedId()
local coords = GetEntityCoords(ped)
local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
if veh and veh ~= 0 then
AttachEntityToEntity(veh, ped, GetPedBoneIndex(ped, 0x796e), 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
carriedVeh = veh
end
end
end
elseif carriedVeh then
DetachEntity(carriedVeh, false, true)
carriedVeh = nil
end
end
end)
Citizen.CreateThread(function() -- Fast Run
while menuLoaded do
Citizen.Wait(0)
if fastRun then
SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
else
SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end
end
end)
Citizen.CreateThread(function()
    while menuLoaded do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            SetVehicleEnginePowerMultiplier(veh, acceleration * 10)
            ModifyVehicleTopSpeed(veh, acceleration / 10.0)
        end
    end
end)
Citizen.CreateThread(function()
    while menuLoaded do
        Citizen.Wait(0)
        if magnitoActive then
            local ped = PlayerPedId()
            local currentAimPoint = nil

            if IsControlPressed(0, 47) then -- G maintenu
                local camRot = GetGameplayCamRot(2)
                local camCoord = GetGameplayCamCoord()
                local dir = RotationToDirection(camRot)
                currentAimPoint = vector3(
                    camCoord.x + dir.x * 100.0,
                    camCoord.y + dir.y * 100.0,
                    camCoord.z + dir.z * 100.0
                )

                DrawMarker(1,
                    currentAimPoint.x, currentAimPoint.y, currentAimPoint.z - 0.5,
                    0, 0, 0, 0, 0, 0,
                    20.0, 20.0, 0.1,   -- diamètre 20m, très fin en hauteur
                    255, 0, 0, 220,
                    false, false, 2, false, nil, nil, false
                )

                local entities = {}
                for _, veh in ipairs(GetGamePool('CVehicle')) do
                    if #(GetEntityCoords(veh) - currentAimPoint) < 150.0 then
                        table.insert(entities, veh)
                    end
                end
                for _, p in ipairs(GetGamePool('CPed')) do
                    if #(GetEntityCoords(p) - currentAimPoint) < 150.0 then
                        table.insert(entities, p)
                    end
                end
                for _, ent in ipairs(entities) do
                    if ent ~= ped and DoesEntityExist(ent) then
                        local eCoords = GetEntityCoords(ent)
                        local dir = currentAimPoint - eCoords
                        local dist = #dir
                        if dist > 4.0 then
                            local force = (dir / dist) * 8.0  -- douce attraction
                            ApplyForceToEntity(ent, 1, force.x, force.y, force.z, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                        end
                    end
                end
            end

            if IsControlJustPressed(0, 38) then -- E
                local camRot = GetGameplayCamRot(2)
                local camCoord = GetGameplayCamCoord()
                local dir = RotationToDirection(camRot)
                local explosionPoint = vector3(
                    camCoord.x + dir.x * 100.0,
                    camCoord.y + dir.y * 100.0,
                    camCoord.z + dir.z * 100.0
                )

                local entities = {}
                for _, veh in ipairs(GetGamePool('CVehicle')) do
                    if #(GetEntityCoords(veh) - explosionPoint) < 150.0 then
                        table.insert(entities, veh)
                    end
                end
                for _, p in ipairs(GetGamePool('CPed')) do
                    if #(GetEntityCoords(p) - explosionPoint) < 150.0 then
                        table.insert(entities, p)
                    end
                end
                for _, ent in ipairs(entities) do
                    if ent ~= ped and DoesEntityExist(ent) then
                        local eCoords = GetEntityCoords(ent)
                        local dir = eCoords - explosionPoint
                        local force = (dir / #dir) * 200.0 -- ultra puissant
                        ApplyForceToEntity(ent, 1, force.x, force.y, force.z + 80.0, 0.0, 0.0, 0.0, 0, true, true, true, true, true)
                    end
                end

                BeginTextCommandThefeedPost('STRING')
                AddTextComponentSubstringPlayerName("~r~Explosion Magnito !")
                EndTextCommandThefeedPostTicker(true, false)
            end
        end
    end
end)
function RayCastGamePlayCamera(distance)
    local camRot = GetGameplayCamRot()
    local camCoord = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = vector3(camCoord.x + dir.x * distance, camCoord.y + dir.y * distance, camCoord.z + dir.z * distance)
    local _, hit, endCoords = GetShapeTestResult(StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0))
    return hit, endCoords
end
function RotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end
Citizen.CreateThread(function()
while menuLoaded do
Citizen.Wait(0)
if noclipV2Active then
local ped = PlayerPedId()
SetEntityVisible(ped, false, false)
SetEntityInvincible(ped, true)
local forward = GetGameplayCamRot(2).z
local heading = math.rad(forward + 90.0)
local speed = 0.1 -- Slower for "undetectable"
if IsControlPressed(0, 21) then speed = 0.5 end
local pos = GetEntityCoords(ped)
local newPos = pos
if IsControlPressed(0, 32) then -- W
newPos = vector3(pos.x + speed * math.cos(heading), pos.y + speed * math.sin(heading), pos.z)
end
if IsControlPressed(0, 33) then -- S
newPos = vector3(pos.x - speed * math.cos(heading), pos.y - speed * math.sin(heading), pos.z)
end
if IsControlPressed(0, 44) then -- Q down
newPos = vector3(pos.x, pos.y, pos.z - speed)
end
if IsControlPressed(0, 38) then -- E up
newPos = vector3(pos.x, pos.y, pos.z + speed)
end
SetEntityCoordsNoOffset(ped, newPos.x, newPos.y, newPos.z, true, true, true)
else
local ped = PlayerPedId()
SetEntityVisible(ped, true, false)
SetEntityInvincible(ped, false)
end
end
end)
Citizen.CreateThread(function()
Citizen.Wait(300)
BeginTextCommandThefeedPost('STRING')
AddTextComponentSubstringPlayerName("~g~Mayzoxe Menu chargé ! ~b~F6 ~s~ouvrir")
EndTextCommandThefeedPostTicker(true, false)
end)
