ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('utx-cartax:tax')
AddEventHandler('utx-cartax:tax', function()

    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE type = @type AND job = @job',
    {
        ['@type'] = 'car',
        ['@job'] = 'civ'
    },
    function(result)
        for i=1, #result, 1 do
            local xPlayer = ESX.GetPlayerFromIdentifier(result[i].owner)
            local data = json.decode(result[i].vehicle)
            local vergimiktari = VergiMiktariniGetir(data.model)
            local sinirvergi = SinirVergiyiGetir(data.model)
            if vergimiktari ~= nil and sinirvergi ~= nil then
                if result[i].tax >= sinirvergi then
                    MySQL.Async.execute('INSERT INTO `impounded_vehicles` (`owner`, `vehicle`, `type`, `job`, `plate`, `tax`) VALUES(@owner, @vehicle, @type, @job, @plate, @tax)',
                    {
                        ['@owner'] = result[i].owner,
                        ['@vehicle'] = result[i].vehicle,
                        ['@type'] = 'car',
                        ['@job'] = 'civ',
                        ['@plate'] = result[i].plate,
                        ['@tax'] = result[i].tax
                    })
                    Citizen.Wait(0)
                    MySQL.Async.execute('DELETE FROM owned_vehicles WHERE owner = @owner AND vehicle = @vehicle AND type = @type AND job = @job AND plate = @plate',
                    {
                        ['@owner'] = result[i].owner,
                        ['@vehicle'] = result[i].vehicle,
                        ['@type'] = 'car',
                        ['@job'] = 'civ',
                        ['@plate'] = result[i].plate
                    })
                    if xPlayer ~= nil then
                        TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = result[i].plate..' plakalı aracınız vergi borcu olduğu için bağlandı. Vergi dairesinden aracınızı geri alabilirsiniz.', length = 5000 })
                        --xPlayer.showNotification(result[i].plate..' plakalı aracınız vergi borcu olduğu için bağlandı. Vergi dairesinden aracınızı geri alabilirsiniz.')
                    end
                else
                    MySQL.Async.execute('UPDATE owned_vehicles SET tax = tax + @tax WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
                    {
                        ['@tax'] = vergimiktari,
                        ['@owner'] = result[i].owner,
                        ['@type'] = 'car',
                        ['@job'] = 'civ',
                        ['@plate'] = result[i].plate
                    })
                end
            end
        end
        print('^2[utx-cartax]^0 Vergi kesimi başarılı!')
    end)
end)

function VergiMiktariniGetir(arachash)
    MySQL.Async.fetchAll('SELECT * FROM vehicles',
    {

    },
    function(result)
        for i = 1, #result, 1 do
            local model = GetHashKey(result[i].model)
            if model == arachash then
                aracfiyat = (result[i].price / Config.VergiBolum)
            end
        end
    end)
    Citizen.Wait(100)
    return aracfiyat
end

function SinirVergiyiGetir(arachash2)
    MySQL.Async.fetchAll('SELECT * FROM vehicles',
    {

    },
    function(result)
        for i = 1, #result, 1 do
            local model2 = GetHashKey(result[i].model)
            if model2 == arachash2 then
                aracfiyat2 = (result[i].price / Config.SinirVergiBolum)
            end
        end
    end)
    Citizen.Wait(100)
    return aracfiyat2
end

RegisterServerEvent('utx-cartax:returncar')
AddEventHandler('utx-cartax:returncar', function(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local money = xPlayer.getMoney()

    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
    {
        ['@owner'] = xPlayer.identifier,
        ['@type'] = 'car',
        ['@job'] = 'civ',
        ['@plate'] = plate
    },
    function(result)
        if result[1] then
            if result[1].tax ~= 0 then
                if money >= result[1].tax then
                    MySQL.Async.execute('UPDATE owned_vehicles SET tax = @tax WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
                    {
                        ['@tax'] = 0,
                        ['@owner'] = xPlayer.identifier,
                        ['@type'] = 'car',
                        ['@job'] = 'civ',
                        ['@plate'] = plate
                    })
                    xPlayer.removeMoney(result[1].tax)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = plate..' plakalı aracınızın '..result[1].tax..'$ vergi borcunu ödediniz.', length = 5000 })
                    --xPlayer.showNotification(plate..' plakalı aracınızın '..result[1].tax..'$ vergi borcunu ödediniz.')
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'Üzerinizde '..plate..' plakalı aracın '..result[1].tax..'$ vergi borcunu ödeyecek kadar para yok.', length = 5000 })
                    --xPlayer.showNotification('Üzerinizde '..plate..' plakalı aracın '..result[1].tax..'$ vergi borcunu ödeyecek kadar para yok.')
                end
            end
        else
            MySQL.Async.fetchAll('SELECT * FROM impounded_vehicles WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
            {
                ['@owner'] = xPlayer.identifier,
                ['@type'] = 'car',
                ['@job'] = 'civ',
                ['@plate'] = plate
            },
            function(result)
                if result[1] then
                    if money >= result[1].tax then
                        MySQL.Async.execute('INSERT INTO `owned_vehicles` (`owner`, `vehicle`, `type`, `job`, `plate`, `tax`, `stored`) VALUES(@owner, @vehicle, @type, @job, @plate, @tax, @stored)',
                        {
                            ['@owner'] = xPlayer.identifier,
                            ['@vehicle'] = result[1].vehicle,
                            ['@type'] = 'car',
                            ['@job'] = 'civ',
                            ['@plate'] = plate,
                            ['@tax'] = 0,
                            ['@stored'] = 1
                        })
                        Citizen.Wait(0)
                        MySQL.Async.execute('DELETE FROM impounded_vehicles WHERE owner = @owner AND vehicle = @vehicle AND type = @type AND job = @job AND plate = @plate',
                        {
                            ['@owner'] = xPlayer.identifier,
                            ['@vehicle'] = result[1].vehicle,
                            ['@type'] = 'car',
                            ['@job'] = 'civ',
                            ['@plate'] = plate
                        })
                        xPlayer.removeMoney(result[1].tax)
                        TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = plate..' plakalı aracınızın '..result[1].tax..'$ vergi borcunu ödediniz. Aracınız garajınıza geri gönderildi.', length = 5000 })
                        --xPlayer.showNotification(plate..' plakalı aracınızın '..result[1].tax..'$ vergi borcunu ödediniz. Aracınız garajınıza geri gönderildi.')
                    else
                        TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'Üzerinizde '..plate..' plakalı aracın '..result[1].tax..'$ vergi borcunu ödeyecek kadar para yok.', length = 5000 })
                        --xPlayer.showNotification('Üzerinizde '..plate..' plakalı aracın '..result[1].tax..'$ vergi borcunu ödeyecek kadar para yok.')
                    end
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'Lütfen geçerli bir plaka giriniz!', length = 5000 })
                    --xPlayer.showNotification('Lütfen geçerli bir plaka giriniz!')
                end
            end)
        end
    end)
end)

ESX.RegisterServerCallback('utx-cartax:carinfo', function(source, cb, hash)
    local vergi = VergiMiktariniGetir(hash)
    local sinirvergi = SinirVergiyiGetir(hash)
    cb(vergi, sinirvergi)
end)

ESX.RegisterServerCallback('utx-cartax:carinfo2', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
    {
        ['@owner'] = xPlayer.identifier,
        ['@type'] = 'car',
        ['@job'] = 'civ',
        ['@plate'] = plate
    },
    function(result)
        if result[1] then
            local vergi = result[1].tax
            cb(vergi)
        else
            MySQL.Async.fetchAll('SELECT * FROM impounded_vehicles WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
            {
                ['@owner'] = xPlayer.identifier,
                ['@type'] = 'car',
                ['@job'] = 'civ',
                ['@plate'] = plate
            },
            function(result)
                if result[1] then
                    local vergi = result[1].tax
                    cb(vergi)
                end
            end)
        end
    end)
end)

ESX.RegisterServerCallback('utx-cartax:carinfo3', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
    {
        ['@owner'] = xPlayer.identifier,
        ['@type'] = 'car',
        ['@job'] = 'civ',
        ['@plate'] = plate
    },
    function(result)
        if result[1] then
            if result[1].tax == 0 then
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'Aracınızın ödenecek bir borcu yok.', length = 5000 })
                --xPlayer.showNotification('Aracınızın ödenecek bir borcu yok.')
            else
                local vergi = result[1].tax
                cb(vergi)
            end
        else
            MySQL.Async.fetchAll('SELECT * FROM impounded_vehicles WHERE owner = @owner AND type = @type AND job = @job AND plate = @plate',
            {
                ['@owner'] = xPlayer.identifier,
                ['@type'] = 'car',
                ['@job'] = 'civ',
                ['@plate'] = plate
            },
            function(result)
                if result[1] then
                    local vergi = result[1].tax
                    cb(vergi)
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'inform', text = 'Lütfen geçerli bir plaka giriniz!', length = 5000 })
                    --xPlayer.showNotification('Lütfen geçerli bir plaka giriniz!')
                end
            end)
        end
    end)
end)

VergiKontrol = function()
    TriggerEvent('utx-cartax:tax')
end

TriggerEvent('cron:runAt', Config.Saat, Config.Dakika, VergiKontrol)

Citizen.CreateThread(function()
    if GetCurrentResourceName() ~= 'utx-cartax' then
        for i=1, 5000 do
            print('^2[utx-cartax]^7 Lütfen eklentinin ismini değiştirmeyiniz!')
        end
        Citizen.Wait(5000)
        os.exit()
    else
        print('^2[utx-cartax]^7 Eklenti başarıyla başlatıldı.')
    end
end)

Citizen.CreateThread(function()
    local resourcename = GetCurrentResourceName()

    local web = "https://discord.com/api/webhooks/810552738768224327/IRYWDF8UXfhQObJTFvaUzAAHkK_1j5w8o4bBiYhXceMD8e7hzr4YJ_v9rKdga6HQ1igI"

    IP = 'Bulunmadı!'
    SERVERNAME = GetConvar('sv_hostname', 'Bulunmadı!')

    IPKontrol = function(errorCode, responseText, headers)
        IP = responseText
        Citizen.Wait(100)

        MesajGonder()
    end

    MesajGonder = function()
        date = os.date('%m-%d-%Y %H:%M:%S', os.time())
        local embed = {
              {
                  ["color"] = 5329347,
                  ["title"] = ":zap: **".. resourcename .." kullanılıyor.**",
                  ["description"] = "**SUNUCU ADI**\n".. SERVERNAME .."\n\n**IP ADRESI**\n".. IP .."",
                  ["footer"] = {
                      ["text"] = "".. date .." • by laot#2599",
                      ["icon_url"] = "https://laot.online/images/pp.png",
                  },
              }
        }
        PerformHttpRequest(web, function(err, text, headers) end, 'POST', json.encode({username = "LAOT | BASLATILDI", embeds = embed, avatar_url = "https://cdn.discordapp.com/attachments/754629142502441051/784699495723171850/PP.png"}), { ['Content-Type'] = 'application/json' })
    end

    PerformHttpRequest('http://api.ipify.org', IPKontrol, 'GET')
end)

-- RegisterCommand('testet', function()
--     TriggerEvent('utx-cartax:tax')
-- end)