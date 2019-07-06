if SERVER then
    util.AddNetworkString('ttt2_net_aspectator_change_weapon')
    util.AddNetworkString('ttt2_net_aspectator_update_weapon')
    util.AddNetworkString('ttt2_net_aspectator_update_role')
    util.AddNetworkString('ttt2_net_aspectator_add_player')
    util.AddNetworkString('ttt2_net_aspectator_remove_player')

    ASPECTATOR = {}
    ASPECTATOR.player = {}

    function ASPECTATOR:ChangeWeapon(ply, weapon)
        if not self.player[ply:UserID()] then return end

        self.player[ply:UserID()].weapon = weapon
        self.player[ply:UserID()].wep_clip = weapon:Clip1()
        self.player[ply:UserID()].wep_clip_max = weapon:GetMaxClip1()
        self.player[ply:UserID()].wep_ammo = weapon:Ammo1()

        net.Start('ttt2_net_aspectator_change_weapon')
        net.WriteEntity(ply)
        net.WriteEntity(weapon)
        net.WriteInt(weapon:Clip1(), 16)
        net.WriteInt(weapon:GetMaxClip1(), 16)
        net.WriteInt(weapon:Ammo1(), 16)
        net.Send(player.GetAll())
    end

    function ASPECTATOR:CheckForChange(pobj)
        local ply, weapon = pobj.ply, pobj.weapon

        if not ply or not weapon then return end

        local wep_clip, wep_clip_max, wep_ammo = pobj.wep_clip, pobj.wep_clip_max, pobj.wep_ammo
        local wep_clip_new, wep_clip_max_new, wep_ammo_new = pobj.weapon:Clip1(), pobj.weapon:GetMaxClip1(), pobj.weapon:Ammo1()

        if not wep_clip or not wep_clip_max or not wep_ammo then return end

        -- a value has changed
        if wep_clip ~= wep_clip_new or wep_clip_max ~= wep_clip_max_new or wep_ammo ~= wep_ammo_new then

            if not self.player[ply:UserID()] then return end

            self.player[ply:UserID()].wep_clip = weapon:Clip1()
            self.player[ply:UserID()].wep_clip_max = weapon:GetMaxClip1()
            self.player[ply:UserID()].wep_ammo = weapon:Ammo1()
            
            net.Start('ttt2_net_aspectator_update_weapon')
            net.WriteEntity(ply)
            net.WriteInt(weapon:Clip1(), 16)
            net.WriteInt(weapon:GetMaxClip1(), 16)
            net.WriteInt(weapon:Ammo1(), 16)
            net.Send(player.GetAll())
        end
    end

    function ASPECTATOR:AddPlayer(ply)
        self.player[ply:UserID()] = {}
        self.player[ply:UserID()].ply = ply

        net.Start('ttt2_net_aspectator_add_player')
        net.WriteUInt(ply:UserID(), 16)
        net.WriteEntity(ply)
        net.Send(player.GetAll())
    end

    function ASPECTATOR:RemovePlayer(ply)
        self.player[ply:UserID()] = nil

        net.Start('ttt2_net_aspectator_remove_player')
        net.WriteEntity(ply)
        net.Send(player.GetAll())
    end

    function ASPECTATOR:UpdateRole(ply, role)
        if not self.player[ply:UserID()] then return end

        self.player[ply:UserID()].role = role

        net.Start('ttt2_net_aspectator_update_role')

        net.WriteEntity(ply)
        net.WriteUInt(role, ROLE_BITS)

        -- killer role color has to be read on server since the sidekick gets a dynamic color
        local role_color = ply:GetRoleColor()
        net.WriteUInt(role_color.r, 8)
        net.WriteUInt(role_color.g, 8)
        net.WriteUInt(role_color.b, 8)
        net.WriteUInt(role_color.a, 8)

        net.Send(player.GetAll())
    end

    -- HOOKS
    hook.Add('PlayerSpawn', 'ttt2_aspectator_add_player', function(ply) 
        ASPECTATOR:AddPlayer(ply)
        --ASPECTATOR:UpdateRole(ply, ply:GetSubRole())
    end)
    
    hook.Add('PlayerDeath', 'ttt2_aspectator_add_player', function(ply) 
        ASPECTATOR:RemovePlayer(ply)
    end)
    
    hook.Add('PlayerDisconnected', 'ttt2_aspectator_change_remove_player', function(ply) 
        ASPECTATOR:RemovePlayer(ply)
    end)
    
    hook.Add('PlayerSwitchWeapon', 'ttt2_aspectator_change_weapon_switch', function(ply, old_weapon, new_weapon) 
        ASPECTATOR:ChangeWeapon(ply, new_weapon)
    end)

    hook.Add('TTT2UpdateSubrole', 'ttt2_aspectator_role_update', function(ply, old_role, new_role)
        timer.Simple(0.05, function() -- add a short delay since the rolecolor is set after this hook is called
            ASPECTATOR:UpdateRole(ply, new_role)
        end)
    end)

    -- TIMER
    timer.Create('ttt2_aspectator_recheck_weapon', 0.5, 0, function() 
        for _, pobj in pairs(ASPECTATOR.player) do
            ASPECTATOR:CheckForChange(pobj)
        end
    end)
end