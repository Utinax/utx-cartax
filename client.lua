ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

Citizen.CreateThread(function()
    while true do
        local sleep = 2000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local distance = Vdist2(pCoords, Config.VergiDairesi.x, Config.VergiDairesi.y, Config.VergiDairesi.z)
        if distance < 125 then
            sleep = 5
            DrawMarker(2, Config.VergiDairesi.x, Config.VergiDairesi.y, Config.VergiDairesi.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.2, 255, 255, 255, 255, 0, 0, 0, 1, 0, 0, 0)
            if distance < 2 then
                DrawText3D(Config.VergiDairesi.x, Config.VergiDairesi.y, Config.VergiDairesi.z + 0.4, '[E] - Vergi Dairesi')
                if IsControlJustPressed(0, 38) then
                    VergiKontrol()
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

function VergiKontrol()
    ESX.UI.Menu.Open(
        'dialog', GetCurrentResourceName(), 'vergi_kontrol',
        {
            title = ('Lütfen araç plakası giriniz.'),
        },
        function(data, menu)
            menu.close()
            --TriggerServerEvent('utx-cartax:returncar', data.value)
            ESX.TriggerServerCallback('utx-cartax:carinfo3', function(vergi)
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vergi_kontrol2',
                {
                    title    = 'Aracınızın '..vergi..'$ borcu var. Ödemek istiyor musunuz?',
                    align    = 'top-left',
                    elements = {
                        {label = 'Evet', value = 'evet'},
                        {label = 'Hayır', value = 'hayir'}
                    }
                },
                function(data2, menu2)
                    if data2.current.value == 'evet' then
                        menu2.close()
                        TriggerServerEvent('utx-cartax:returncar', data.value)
                    elseif data2.current.value == 'hayir' then
                        menu2.close()
                    end
                end,
                function(data2, menu2)
                    menu2.close()
                end)
            end, data.value)
        end,
        function(data, menu)
        menu.close()
    end)
end

RegisterCommand('vergi', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local plate = GetVehicleNumberPlateText(vehicle)
    local name = GetEntityModel(vehicle)
    ESX.TriggerServerCallback('utx-cartax:carinfo2', function(vergi)
        if Config.Mythic_SendAlert then
            exports['mythic_notify']:SendAlert('inform', 'Aracın mevcut vergisi: '..vergi..'$')
        else
            exports['mythic_notify']:DoHudText('inform', 'Aracın mevcut vergisi: '..vergi..'$')
        end
        --ESX.ShowNotification('Aracın mevcut vergisi: '..vergi..'$')
    end, plate)
    ESX.TriggerServerCallback('utx-cartax:carinfo', function(vergi, sinirvergi)
        if Config.Mythic_SendAlert then
            exports['mythic_notify']:SendAlert('inform', 'Aracın günlük vergisi: '..vergi..'$')
            exports['mythic_notify']:SendAlert('inform', 'Aracın sınır vergisi: '..sinirvergi..'$')
        else
            exports['mythic_notify']:DoHudText('inform', 'Aracın günlük vergisi: '..vergi..'$')
            exports['mythic_notify']:DoHudText('inform', 'Aracın sınır vergisi: '..sinirvergi..'$')
        end
        --ESX.ShowNotification('Aracın günlük vergisi: '..vergi..'$')
        --ESX.ShowNotification('Aracın sınır vergisi: '..sinirvergi..'$')
    end, name)
end)

Citizen.CreateThread(function()
    local blip = AddBlipForCoord(vector3(Config.VergiDairesi.x, Config.VergiDairesi.y, Config.VergiDairesi.z))

    SetBlipSprite (blip, Config.Blip.sprite)
    SetBlipScale  (blip, Config.Blip.scale)
    SetBlipColour (blip, Config.Blip.colour)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Vergi Dairesi')
    EndTextCommandSetBlipName(blip)
end)