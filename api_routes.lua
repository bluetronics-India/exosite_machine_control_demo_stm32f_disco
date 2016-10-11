--#ENDPOINT GET /device/data
-- Description: Get timeseries data for specific device
-- Parameters: ?identifier=<uniqueidentifier>&window=<number>
local identifier = tostring(request.parameters.identifier) -- ?identifier=<uniqueidentifier>
local window = tostring(request.parameters.window) -- in minutes,if ?window=<number>
local getts = tonumber(request.parameters.getts) or 1
local getkv = tonumber(request.parameters.getkv) or 1

if true then
  local data = {}

  if getts == 1 then
    data['timeseries'] = virt_dev_ts_query(identifier, "SELECT value FROM temperature,tempset", "time > now() - "..window.."m LIMIT 5000")
  end

  if getkv == 1 then
    local virtual_device = virt_dev(identifier)
    data['keyvalue'] = virtual_device
  end

  response.message = data
  response.code = 200
  return data
else
  response.message = "Conflict - Identifier Incorrect"
  response.code = 404
  return
end

--#ENDPOINT POST /device
-- Description Sets threshold for device
-- Body: identifier=<uniqueid>&threshold=<threshold>&control=<control>&tempset=<tempset>
local identifier = tostring(request.body.identifier) or nil
if identifier == nil then
  response.message = "Conflict - Identifier Incorrect"
  response.code = 404
  return response
else
  --print('api-route-request:write:'..identifier..':'..to_json(request.body))
  if request.body.control and tonumber(request.body.control) >= 0 and tonumber(request.body.control) <= 1 then
    virt_device_cloud_write(identifier, {alias='control',value=request.body.control})
  end

  if request.body.tempset and tonumber(request.body.tempset) >= 30 and tonumber(request.body.tempset) <= 120 then
    virt_device_cloud_write(identifier, {alias='tempset',value=request.body.tempset})
  end

  response.message = 'success'
  response.code = 200
  return response
end

--#ENDPOINT WEBSOCKET /realtime
-- Parameters: ?identifier=<uniqueidentifier>
--local identifier = tostring(request.parameters.identifier) or nil-- ?identifier=<uniqueidentifier>
local identifier = '00:02:f7:f0:00:00'
print('subscribe-ws-'..tostring(identifier))
if identifier ~= nil then
  return virt_dev_ws_subscriptions(identifier, websocketInfo)
else
  return '{"type":"info","message":"subscription not opened for device: '..tostring(identifier)..'"}'
end

--#ENDPOINT GET /debug/keyvalueclean
-- Description: Show current key-value data for a specific unique device or for full solution
-- Parameters: ?device=<uniqueidentifier>
if true then
  local resp = "not available"
  local resp = Keystore.clear()
  response.message = 'clearing keyvalue,'..to_json(resp)
  response.code = 200
  return response
end


--#ENDPOINT GET /debug/test
if true then
  return 'Hello World! \r\nI am a test Murano Solution API Route entpoint - v2'
end


--#ENDPOINT GET /debug/storage/keyvalue
-- Description: Show current key-value for full solution DEBUG USE ONLY

if true then
  local response_text = 'Getting Key Value Raw Data for: Full Solution: \r\n'
  local resp = Keystore.list()
  --response_text = response_text..'Solution Keys\r\n'..to_json(resp)..'\r\n'
  if resp['keys'] ~= nil then
    local num_keys = #resp['keys']
    local n = 1 --remember Lua Tables start at 1.
    while n <= num_keys do
      local id = resp['keys'][n]
      local response = Keystore.get({key = id})
      response_text = response_text..id..'\r\n'
      response_text = response_text..'KeyValue: '..to_json(response['value'])..'\r\n'
      --[[
      -- print out each value on new line
      local item_json,err = from_json(response['value'])
      if err == nil and type(item_json)=='table' then

        for key,val in pairs(item_json) do
          response_text = response_text.. '   '..key..' : '.. tostring(val) ..'\r\n'
        end
      else
        response_text = response_text..'KeyValue: '..to_json(response['value'])..'\r\n'
      end
      --]]
      n = n + 1
    end
  end
  return response_text
end
