local T = {}

co = coroutine.create(function ()
	while true do
		coroutine.yield()
		os.execute('tmux refresh-client -S')
	end
end)

function T.write()
	coroutine.resume(co)
end

return T
