-- NUKES old VFXClient and creates a clean one
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local old=SPS:FindFirstChild("VFXClient")
if old then
	print("💣 Found old VFXClient — destroying it!")
	old:Destroy()
else
	print("ℹ️ No old VFXClient found")
end
task.wait(0.2)
local s=Instance.new("LocalScript")
s.Name="VFXClient"
s.Parent=SPS
s.Source=[==[
local P=game:GetService("Players") local RS=game:GetService("ReplicatedStorage") local TS=game:GetService("TweenService")
local pl=P.LocalPlayer local R=RS:WaitForChild("Remotes") local CVF=RS:WaitForChild("CustomVFX") local ECE=R:WaitForChild("EquippedChangedEvent")
local TAG="AuraVFX"
local AD local ok1=pcall(function() AD=require(RS:WaitForChild("AuraData")) end)
if not ok1 then warn("VFX: AuraData error!") return end
local VD local ok2=pcall(function() VD=require(RS:WaitForChild("VFXData")) end)
if not ok2 then warn("VFX: VFXData error!") return end
print("✨ VFXClient LOADED! CustomVFX has "..#CVF:GetChildren().." items:")
for _,i in ipairs(CVF:GetChildren()) do print("   - "..i.Name.." ("..i.ClassName..")") end
local function clear(ch) if not ch then return end for _,o in ipairs(ch:GetDescendants()) do if o:GetAttribute(TAG) then if o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") then o.Enabled=false end o:Destroy() end end end
local function cP(p,c) local e=Instance.new("ParticleEmitter") if c.Color then e.Color=c.Color end if c.Size then e.Size=c.Size end if c.Transparency then e.Transparency=c.Transparency end if c.Lifetime then e.Lifetime=c.Lifetime end if c.Rate then e.Rate=c.Rate end if c.Speed then e.Speed=c.Speed end if c.SpreadAngle then e.SpreadAngle=c.SpreadAngle end if c.Acceleration then e.Acceleration=c.Acceleration end if c.Rotation then e.Rotation=c.Rotation end if c.LightEmission then e.LightEmission=c.LightEmission end if c.Texture and c.Texture~="" then e.Texture=c.Texture end e.Enabled=true e:SetAttribute(TAG,true) e.Parent=p return e end
local function cF(p,c) local f=Instance.new("Fire") f.Color=c.Color or Color3.fromRGB(255,100,30) f.SecondaryColor=c.SecondaryColor or Color3.fromRGB(255,200,50) f.Size=c.Size or 2 f.Heat=c.Heat or 15 f.Enabled=true f:SetAttribute(TAG,true) f.Parent=p return f end
local function cS(p,c) local s=Instance.new("Smoke") s.Color=c.Color or Color3.fromRGB(150,150,150) s.Size=c.Size or 1.2 s.Opacity=c.Opacity or 0.4 s.RiseVelocity=c.RiseAcceleration or 1.5 s.Enabled=true s:SetAttribute(TAG,true) s.Parent=p return s end
local function cL(p,c) local l=Instance.new("PointLight") l.Color=c.Color or Color3.fromRGB(255,255,255) l.Brightness=c.Brightness or 1 l.Range=c.Range or 10 l:SetAttribute(TAG,true) l.Parent=p return l end
local function cM(ch,c)
	local t=CVF:FindFirstChild(c.TemplateName)
	if not t then warn("VFX: Rig '"..tostring(c.TemplateName).."' NOT in CustomVFX!") return nil end
	print("VFX: Cloning rig '"..c.TemplateName.."'...")
	local cl=t:Clone() local parts={} local pp=nil
	for _,o in ipairs(cl:GetDescendants()) do
		if o:IsA("BasePart") then
			table.insert(parts,o) if not pp then pp=o end
			o.Transparency=1 o.CanCollide=false o.CanQuery=false o.CanTouch=false o.Massless=true o.Anchored=false
		end
		if o:IsA("ParticleEmitter") or o:IsA("Fire") or o:IsA("Smoke") then o.Enabled=true end
		o:SetAttribute(TAG,true)
	end
	if not pp then warn("VFX: No parts in rig!") cl:Destroy() return nil end
	cl.PrimaryPart=pp
	local offs={}
	for _,p in ipairs(parts) do if p~=pp then offs[p]=pp.CFrame:Inverse()*p.CFrame end end
	local bp=ch:FindFirstChild(c.Part or "HumanoidRootPart") or ch:FindFirstChild("HumanoidRootPart")
	if not bp then cl:Destroy() return nil end
	pp.CFrame=bp.CFrame cl:SetAttribute(TAG,true) cl.Parent=ch
	local mw=Instance.new("Weld") mw.Part0=bp mw.Part1=pp mw.C0=CFrame.new() mw.Parent=pp
	for p,o in pairs(offs) do local w=Instance.new("Weld") w.Part0=pp w.Part1=p w.C0=o w.Parent=p end
	print("VFX: Rig attached! ("..#parts.." parts)")
	return cl
end
local function apply(ch,vc) if not ch or not vc then return end print("VFX: Applying '"..vc.Name.."'...") for _,e in ipairs(vc.Effects) do if e.Type=="Model" then cM(ch,e) else local p=ch:FindFirstChild(e.Part) or ch:FindFirstChild("HumanoidRootPart") if not p then continue end if e.Type=="Particle" then cP(p,e) elseif e.Type=="Fire" then cF(p,e) elseif e.Type=="Smoke" then cS(p,e) elseif e.Type=="Light" then cL(p,e) end end end end
local function parse(s) local sep=string.find(s,"|") if sep then return string.sub(s,sep+1) end return s end
local ce=nil
local function update()
	local ch=pl.Character if not ch then return end clear(ch)
	if not ce or ce=="" then return end
	local bn=parse(ce) local a=AD.GetByName(bn) local t=a and a.Tier or nil
	local vc=VD.GetVFXForAura(bn,t) if vc then apply(ch,vc) else print("VFX: No VFX for '"..bn.."'. Put a rig named '"..bn.."' in CustomVFX!") end
end
ECE.OnClientEvent:Connect(function(n) ce=n update() end)
pl.CharacterAdded:Connect(function() task.wait(1) update() end)
]==]
print("✅✅✅ VFXClient NUKED AND REBUILT! ✅✅✅")
