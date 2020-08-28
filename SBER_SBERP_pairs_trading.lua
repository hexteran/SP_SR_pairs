function LOGGER_data_write()
end

function LOGGER_trade_write(type)
end

function OnStop()
	is_run = false
	DATALOG:close()
	TRADESLOG:close()
	return 1000
end

function OnQuote(class, code)
	if class == "SPBFUT" and code == LOWER_SECCODE then 
		table = getQuoteLevel2(class,code)
		for j = tonumber(table.bid_count), 1, -1 do
			if table.bid[j].price~=nil and table.bid[j].price~=0 then
				LOWER_BID_PRICE = tonumber(table.bid[j].price)
				LOWER_BID_QUANTITY = tonumber(table.bid[j].quantity) 
				break
			end
		end
		for j =  1, tonumber(table.bid_count) do
			if table.offer[j].price~=nil and table.offer[j].price~=0 then
				LOWER_ASK_PRICE = tonumber(table.offer[j].price)
				LOWER_ASK_QUANTITY = tonumber(table.offer[j].quantity) 
				break
			end
		end
		logic()
	end

	if class == "SPBFUT" and code == UPPER_SECCODE then 
		table = getQuoteLevel2(class,code)
		for j = tonumber(table.bid_count), 1, -1 do
			if table.bid[j].price~=nil and table.bid[j].price~=0 then
				UPPER_BID_PRICE = tonumber(table.bid[j].price)
				UPPER_BID_QUANTITY = tonumber(table.bid[j].quantity) 
				break
			end
		end
		for j =  1, tonumber(table.bid_count) do
			if table.offer[j].price~=nil and table.offer[j].price~=0 then
				UPPER_ASK_PRICE = tonumber(table.offer[j].price)
				UPPER_ASK_QUANTITY = tonumber(table.offer[j].quantity) 
				break
			end
		end
	end
end


function get_candles(Identifier, n)
	num = getNumCandles(Identifier)
	t, n, b = getCandlesByIndex(Identifier, 0, num-n, n);
	return t
end

function mean(array, n)
	local sum = 0
	for i = 0, n-1 do
		sum = sum + array[i]
	end
	return sum/(n)
end

function std(array,n,mn)
	local sum = 0
	for i = 0, n-1 do
		sum = sum + (array[i]-mn)*(array[i]-mn)
	end
	return math.sqrt(sum/(n-1))
end

function logic()
	if UPPER_ASK_PRICE==0 or UPPER_BID_PRICE == 0 then return end
	stime = GetInfoParam("SERVERTIME")
	--message(stime)
	DATALOG:write(stime..","..tostring(LOWER_BID_PRICE)..","..tostring(LOWER_BID_QUANTITY)..","..tostring(LOWER_ASK_PRICE)..","..tostring(LOWER_ASK_QUANTITY)..",")
	DATALOG:write(tostring(UPPER_BID_PRICE)..","..tostring(UPPER_BID_QUANTITY)..","..tostring(UPPER_ASK_PRICE)..","..tostring(UPPER_ASK_QUANTITY)..",")
	DATALOG:write(tostring(stdiv)..","..tostring(average).."\n")
	if LOWER_ASK_PRICE - UPPER_BID_PRICE <= average - stdiv - price_threshold and LOWER_ASK_QUANTITY >= quantity_threshold and isPositionOpened_long == false then
		buy_LOWER()
		sell_UPPER()
		message("LONG IS OPENED")
		isPositionOpened_long = true
		flagmem = io.open(flagmem_path, "w")
		flagmem:write("1")
		flagmem:close()
	end
	if LOWER_BID_PRICE - UPPER_ASK_PRICE >= average + price_threshold and LOWER_BID_QUANTITY >= quantity_threshold and isPositionOpened_long == true then
		sell_LOWER()
		buy_UPPER()
		message("LONG IS CLOSED")
		isPositionOpened_long = false
		flagmem = io.open(flagmem_path, "w")
		flagmem:write("0")
		flagmem:close()
	end
	if LOWER_BID_PRICE - UPPER_ASK_PRICE >= average + stdiv + price_threshold and LOWER_BID_QUANTITY >= quantity_threshold and isPositionOpened_short == false then
		sell_LOWER()
		buy_UPPER()
		message("SHORT IS OPENED")
		isPositionOpened_short = true
		flagmem = io.open(flagmem_path, "w")
		flagmem:write("-1")
		flagmem:close()
	end
	if LOWER_ASK_PRICE - UPPER_BID_PRICE <= average - price_threshold and LOWER_ASK_QUANTITY >= quantity_threshold and isPositionOpened_short == true then
		buy_LOWER()
		sell_UPPER()
		message("SHORT IS CLOSED")
		isPositionOpened_short = false
		flagmem = io.open(flagmem_path, "w")
		flagmem:write("0")
		flagmem:close()
	end
end
function buy_LOWER()
	TRADESLOG:write(stime..",".."LOWER"..","..tostring(LOWER_ASK_PRICE)..",".."1".."\n")
end
function buy_UPPER()
	TRADESLOG:write(stime..",".."UPPER"..","..tostring(UPPER_ASK_PRICE)..",".."1".."\n")
end
function sell_LOWER()
	TRADESLOG:write(stime..",".."LOWER"..","..tostring(LOWER_BID_PRICE)..",".."-1".."\n")
end
function sell_UPPER()
	TRADESLOG:write(stime..",".."UPPER"..","..tostring(UPPER_BID_PRICE)..",".."-1".."\n")
end

function main()
	flagmem_path = "C:\\Buffer\\Trading\\scripts\\Pairs_trading\\flagmem.txt"
	tradeslog_path = "C:\\Buffer\\Trading\\scripts\\Pairs_trading\\trades.csv"
	datalog_path = "C:\\Buffer\\Trading\\scripts\\Pairs_trading\\data.csv"
	
	period = 200
	quantity_threshold = 5
	price_threshold = 5
	UPPER_SECCODE = "SRU0"
	LOWER_SECCODE = "SPU0"

	local last = 0
	flagmem = io.open(flagmem_path, "r")
	for line in flagmem:lines() do 
		--message(tostring(line))
		last = (tonumber(line))
	end
	isPositionOpened_long = false
	isPositionOpened_short = false
	if last == 1 then
		isPositionOpened_long = true
	end
	if last == -1 then
		isPositionOpened_short = true
	end
	if last ~= -1 and last ~= 1 and last ~= 0 then
		message("flagmem Error")
		return
	end
	flagmem:close()
	message(tostring(isPositionOpened_long)..tostring(isPositionOpened_short))
	DATALOG = io.open(datalog_path,"a")
	TRADESLOG = io.open(tradeslog_path,"a")
	--TRADESLOG:write("UPPER")

	UPPER_BID_PRICE = 0
	LOWER_BID_PRICE = 0
	UPPER_ASK_PRICE = 0
	LOWER_ASK_PRICE = 0
	UPPER_BID_QUANTITY = 0
	LOWER_BID_QUANTITY = 0
	UPPER_ASK_QUANTITY = 0
	LOWER_ASK_QUANTITY = 0
	
	-- использовать стакан для определения цены покупки\продажи, а не свечи
	-- использовать файл для переноса позиции через ночь\
	-- логгирование
	is_run = true
	while is_run == true do
		SP = get_candles("SP", 3*period) 
		SR = get_candles("SR", 3*period)
		SIRPIVO = {}
		counter = 0
		k = 0
		for i = 3*period - 1, 0, -1  do --проверять количество свечей обязательно!
			if SP[i]["close"] ~= 0 and SR[i]["close"] ~= 0 then
				if  SP[i]["datetime"]["min"] == SR[i]["datetime"]["min"] and SP[i]["datetime"]["hour"] == SR[i]["datetime"]["hour"] then
					SIRPIVO[k] = SP[i]["close"]-SR[i]["close"] 
					k = k+1
					if (k>period) then 
						break
					end
				end
			end 
		end
		if pcall(mean, SIRPIVO, period) then
			average = mean(SIRPIVO, period)
		end
		if pcall(std, SIRPIVO, period, average) then
			stdiv = std(SIRPIVO, period, average)
		end
		--message(tostring(stdiv))
		sleep(2000)
	end
end