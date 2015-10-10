if SERVER then
	print('[CaG] Loading server files')
	AddCSLuaFile()
	
	AddCSLuaFile('sh_cag1.lua')
	AddCSLuaFile('cl_cag1.lua')
	
	include('sh_cag1.lua')
	include('sv_cag1.lua')
end

if CLIENT then
	print('[CaG] Loading client files')
	
	include('sh_cag1.lua')
	include('cl_cag1.lua')
end