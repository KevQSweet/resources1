--[[ MySQL Class

--]]

MySQL = setmetatable({}, MySQL)
MySQL.__index = MySQL

function MySQL.open(self, server, database, userid, password)

	local reflection = clr.System.Reflection
	local assembly = reflection.Assembly.LoadFrom('resources/toast/lib/MySql.Data.dll')
	self.mysql = clr.MySql.Data.MySqlClient
	self.connection = self.mysql.MySqlConnection("server="..server..";database="..database..";userid="..userid..";password="..password.."")
	self.connection.Open()
end

function MySQL.executeQuery(self, command, params)
	local c = self.connection.CreateCommand()
	c.CommandText = command

	if type(params) == "table" then
		for param in pairs(params) do
			c.CommandText = string.gsub(c.CommandText, param, self:escape(params[param]))
		end
	end
	
	local res = c.ExecuteNonQuery()
	print("Query Executed("..res.."): " .. c.CommandText)

	return {mySqlCommand = c, result = res}
end

function MySQL.getResults(self, mySqlCommand, fields, byField)
	if type(fields) ~= "table" or #fields == 0 then
		return nil
	end
	if type(mySqlCommand) == "table" and mySqlCommand['mySqlCommand'] ~= nil then
		mySqlCommand = mySqlCommand['mySqlCommand']
	end
	
	local reader = mySqlCommand:ExecuteReader()
	local result = {}
	local c = nil
	
	while reader:Read() do
		if byField == nil then
			c = #result+1
		else 
			c = self:_getFieldByName(reader, byField)
		end
		result[c] = {}
		
		for field in pairs(fields) do
			result[c][fields[field]] = self:_getFieldByName(reader, fields[field])
		end
	end
	reader:Close()
	return result
end

function MySQL.escape(self, str)
	return self.mysql.MySqlHelper.EscapeString(str)
end

function MySQL._getFieldByName(self, reader, name)
	local typ = reader:GetFieldType(name)
	if typ == "System.Single" then
		return reader:GetFloat(name)
	elseif typ == "System.String" then
		return reader:GetString(name)
	elseif typ == "System.Int32" then
		return reader:GetInt32(name)
	end
	print("MySQL._getFieldByName: " .. typ .. " is not defined.")
	return nil
end