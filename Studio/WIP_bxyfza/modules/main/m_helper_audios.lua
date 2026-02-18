--!strict
local debris = game:GetService("Debris")
local audios = script.Audios
local activeAudios = script.Active
--
export type __playAudioData = {
	NoDestroy: boolean?,
	Volume: number?,
	PlaybackSpeed: number?,
}
local function GetAudio(name: string): Sound
	return audios:FindFirstChild(name:lower()) :: Sound
end
local function PlayAudio(name: string, data: __playAudioData?): Sound
	local data : __playAudioData = data or {}
	--
	local audio = GetAudio(name)
	assert(audio, "Audio not found: "..name)
	assert(audio.IsLoaded, "Audio failed to load: "..name)
	--
	local newAudio = audio:Clone()
	if not data.NoDestroy then
		debris:AddItem(newAudio, audio.TimeLength)
	end
	--
	newAudio.Volume = data.Volume or newAudio.Volume
	newAudio.PlaybackSpeed = data.PlaybackSpeed or newAudio.PlaybackSpeed
	newAudio.Parent = activeAudios
	--
	newAudio:Play()
	return newAudio
end
local function ClearAllAudios(keepPlayOnRemove: boolean?): nil
	local keepPlayOnRemove: boolean = keepPlayOnRemove or false 
	for _,v : Sound in next, audios:GetChildren() do
		v.PlayOnRemove = keepPlayOnRemove and v.PlayOnRemove
		v:Destroy()
	end
	return
end
local function ClearAudio(name: string, keepPlayOnRemove: boolean?)
	local keepPlayOnRemove: boolean = keepPlayOnRemove or false 
	name = name:lower()
	--
	for _,v : Sound in next, audios:GetChildren() do
		if v.Name ~= name then continue end
		--
		v.PlayOnRemove = keepPlayOnRemove and v.PlayOnRemove
		v:Destroy()
	end
	return
end
local module = {
	GetAudio = GetAudio,
	PlayAudio = PlayAudio,
	ClearAllAudios = ClearAllAudios,
	ClearAudio = ClearAudio
}

return module
