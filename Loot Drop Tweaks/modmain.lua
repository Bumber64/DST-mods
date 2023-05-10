
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

-----------------------
-- Utility functions --
-----------------------

local function ensure_loot(ld, item, chance) --make sure lootdropper has item as chance loot with given minimum chance
    if not ld or chance <= 0.0 then
        return
    end

    local shared_table --if found in chanceloottable
    local found_entry
    local found_value = 0.0

    local lt = ld.chanceloottable and _G.LootTables[ld.chanceloottable] or nil
    if lt then
        for _, t in ipairs(lt) do
            if t[1] == item and t[2] > found_value then --better than previous
                if t[2] >= chance then
                    return --requirement satisfied
                else
                    shared_table = true
                    found_entry = t
                    found_value = t[2]
                end
            end
        end
    end

    if ld.chanceloot then
        for _, t in pairs(ld.chanceloot) do
            if t.prefab == item and t.chance > found_value then --better than previous
                if t.chance >= chance then
                    return --requirement satisfied
                else
                    shared_table = nil
                    found_entry = t
                    found_value = t.chance
                end
            end
        end
    end

    if shared_table then
        found_entry[2] = chance --modify chanceloottable
    elseif found_entry then
        found_entry.chance = chance --modify chanceloot
    else
        ld:AddChanceLoot(item, chance) --insert into chanceloot
    end
end

local function reduce_loot(ld, item, chance) --reduce chanceloot drop rate on first drop exceeding rate
    if ld and ld.chanceloot and chance > 0 then
        for _, t in pairs(ld.chanceloot) do
            if t.prefab == item and t.chance > chance then --found one
                t.chance = chance
                return
            end
        end
    end
end

local function convert_rand_loot(ld) --convert lootdropper's randomloot into chanceloot
    if not ld or not ld.randomloot then
        return
    end

    local n, w = ld.numrandomloot, ld.totalrandomweight
    if not (n and w and n > 0 and w > 0) then
        return
    end

    for _, t in pairs(ld.randomloot) do
        for i=1, n do --add extra drops for numrandomloot > 1
            ld:AddChanceLoot(t.prefab, t.weight / w)
        end
    end

    ld.randomloot = nil --this also clears ld.totalrandomweight when necessary
    --keep ld.numrandomloot for haunted loot
end

----------------------
-- Prefab functions --
----------------------

if GetModConfigData("batilisk_wing") > 0.0 then
    AddPrefabPostInit("bat", function(inst)
        ensure_loot(inst.components.lootdropper, 'batwing', GetModConfigData("batilisk_wing"))
    end)
end

local honey_rate = GetModConfigData("bee_honey")
local stinger_rate = GetModConfigData("bee_stinger")

if honey_rate > 0.0 or stinger_rate > 0.0 then
    AddPrefabPostInit("bee", function(inst)
        local ld = inst.components.lootdropper

        convert_rand_loot(ld)
        ensure_loot(ld, 'honey', honey_rate)

        reduce_loot(ld, 'stinger', stinger_rate)
    end)

    AddPrefabPostInit("killerbee", function(inst)
        local ld = inst.components.lootdropper

        convert_rand_loot(ld)
        ensure_loot(ld, 'honey', honey_rate)

        reduce_loot(ld, 'stinger', stinger_rate)
    end)
end

if GetModConfigData("bird_morsel") > 0.0 or GetModConfigData("bird_feather") > 0.0 then
    for k, v in pairs({crow = "feather_crow", puffin = "feather_crow", robin = "feather_robin", robin_winter = "feather_robin_winter"}) do
        AddPrefabPostInit(k, function(inst)
            local ld = inst.components.lootdropper

            convert_rand_loot(ld)
            ensure_loot(ld, 'smallmeat', GetModConfigData("bird_morsel"))
            ensure_loot(ld, v, GetModConfigData("bird_feather"))
        end)
    end
end

if GetModConfigData("canary_saffron") > 0.0 then
    AddPrefabPostInit("canary", function(inst)
        local ld = inst.components.lootdropper

        convert_rand_loot(ld)
        ensure_loot(ld, 'smallmeat', 1.0)
        ensure_loot(ld, 'feather_canary', GetModConfigData("canary_saffron"))
    end)
end

if GetModConfigData("bunnyman_carrot") > 0.0 or GetModConfigData("bunnyman_meat") > 0.0 or GetModConfigData("bunnyman_tail") > 0.0 then
    local function is_beardlord(ld) --NOTE: only returns true after death
        local guy = ld.inst.causeofdeath
        guy = guy and guy.components.follower and guy.components.follower.leader or guy

        local sanity = guy and guy.replica.sanity or nil
        return sanity and sanity:IsInsanityMode() and
            sanity:GetPercentNetworked() <= (guy:HasTag("dappereffects") and
            TUNING.DAPPER_BEARDLING_SANITY or
            TUNING.BEARDLING_SANITY)
    end

    AddPrefabPostInit("bunnyman", function(inst)
        local ld = inst.components.lootdropper

        local oldfn = ld.lootsetupfn
        ld:SetLootSetupFn(function(ld)
            if oldfn then
                oldfn(ld)
            end
            if is_beardlord(ld) then
                return --beardlords don't drop any of our items
            end

            convert_rand_loot(ld)
            ensure_loot(ld, 'carrot', GetModConfigData("bunnyman_carrot"))
            ensure_loot(ld, 'meat', GetModConfigData("bunnyman_meat"))
            ensure_loot(ld, 'manrabbit_tail', GetModConfigData("bunnyman_tail"))
        end)
    end)
end

if GetModConfigData("butterfly_butter") > 0.0 then
    AddPrefabPostInit("butterfly", function(inst)
        local ld = inst.components.lootdropper

        convert_rand_loot(ld)
        ensure_loot(ld, 'butterflywings', 1.0)
        ensure_loot(ld, 'butter', GetModConfigData("butterfly_butter"))
    end)
end

if GetModConfigData("catcoon_tail") > 0.0 then
    AddPrefabPostInit("catcoon", function(inst)
        ensure_loot(inst.components.lootdropper, 'coontail', GetModConfigData("catcoon_tail"))
    end)
end

if GetModConfigData("cookiecutter_shell") > 0.0 then
    AddPrefabPostInit("cookiecutter", function(inst)
        ensure_loot(inst.components.lootdropper, 'cookiecuttershell', GetModConfigData("cookiecutter_shell"))
    end)
end

if GetModConfigData("dragonfly_egg") > 0.0 then
    AddPrefabPostInit("dragonfly", function(inst)
        ensure_loot(inst.components.lootdropper, 'lavae_egg', GetModConfigData("dragonfly_egg"))
    end)
end

if GetModConfigData("hound_tooth") > 0.0 then
    AddPrefabPostInit("hound", function(inst)
        ensure_loot(inst.components.lootdropper, 'houndstooth', GetModConfigData("hound_tooth"))
    end)
end

if GetModConfigData("hound_redgem") > 0.0 then
    AddPrefabPostInit("firehound", function(inst)
        ensure_loot(inst.components.lootdropper, 'redgem', GetModConfigData("hound_redgem"))
    end)
end

if GetModConfigData("hound_bluegem") > 0.0 then
    AddPrefabPostInit("icehound", function(inst)
        ensure_loot(inst.components.lootdropper, 'bluegem', GetModConfigData("hound_bluegem"))
    end)
end

if GetModConfigData("krampus_pack") > 0.0 then
    AddPrefabPostInit("krampus", function(inst)
        ensure_loot(inst.components.lootdropper, 'krampus_sack', GetModConfigData("krampus_pack"))
    end)
end

if GetModConfigData("mactusk_hat") > 0.0 or GetModConfigData("mactusk_tusk") > 0.0 then
    AddPrefabPostInit("walrus", function(inst)
        local ld = inst.components.lootdropper
        ensure_loot(ld, 'walrushat', GetModConfigData("mactusk_hat"))
        ensure_loot(ld, 'walrus_tusk', GetModConfigData("mactusk_tusk"))
    end)
end

if GetModConfigData("pigman_meat") > 0.0 or GetModConfigData("pigman_skin") > 0.0 then
    local function adjust_pig_loot(ld)
        convert_rand_loot(ld)
        ensure_loot(ld, 'meat', GetModConfigData("pigman_meat"))
        ensure_loot(ld, 'pigskin', GetModConfigData("pigman_skin"))
    end

    AddPrefabPostInit("pigman", function(inst) --no need to bother with pigguard
        adjust_pig_loot(inst.components.lootdropper)

        if not inst.components.werebeast then
            return
        end

        local oldfn = inst.components.werebeast.onsetnormalfn
        inst.components.werebeast:SetOnNormalFn(function(inst)
            if oldfn then
                oldfn(inst)
            end

            adjust_pig_loot(inst.components.lootdropper)
        end)
        --onsetwerefn clears chanceloottable
    end)
end

local silk_rate = GetModConfigData("spider_silk")
local gland_rate = GetModConfigData("spider_gland")

if silk_rate > 0.0 or gland_rate > 0.0 then
    for _, v in pairs({"spider", "spider_warrior", "spider_hider", "spider_spitter", "spider_dropper", "spider_moon", "spider_healer", "spider_water"}) do
        AddPrefabPostInit(v, function(inst)
            local ld = inst.components.lootdropper

            convert_rand_loot(ld)

            if silk_rate >= 0.25 then
                ensure_loot(ld, 'silk', silk_rate)
            else
                reduce_loot(ld, 'silk', silk_rate)
            end

            if gland_rate >= 0.25 then
                ensure_loot(ld, 'spidergland', gland_rate)
            else
                reduce_loot(ld, 'spidergland', gland_rate)
            end
        end)
    end
end

if GetModConfigData("slurperpelt") > 0.0 then
    AddPrefabPostInit("slurper", function(inst)
        ensure_loot(inst.components.lootdropper, 'slurper_pelt', GetModConfigData("slurperpelt"))
    end)
end

if GetModConfigData("slurtle_helm") > 0.0 then
    AddPrefabPostInit("slurtle", function(inst)
        ensure_loot(inst.components.lootdropper, 'slurtlehat', GetModConfigData("slurtle_helm"))
    end)
end

if GetModConfigData("snurtle_armor") > 0.0 then
    AddPrefabPostInit("snurtle", function(inst)
        ensure_loot(inst.components.lootdropper, 'armorsnurtleshell', GetModConfigData("snurtle_armor"))
    end)
end

if GetModConfigData("tentacle_spot") > 0.0 then
    AddPrefabPostInit("tentacle", function(inst)
        ensure_loot(inst.components.lootdropper, 'tentaclespots', GetModConfigData("tentacle_spot"))
    end)

    AddPrefabPostInit("tentacle_pillar", function(inst)
        ensure_loot(inst.components.lootdropper, 'tentaclespots', GetModConfigData("tentacle_spot"))
    end)
end

if GetModConfigData("voltgoat_horn") > 0.0 then
    local do_horn = true

    local function adjust_goat_horn() --adjust volt goat shared loot tables, only done once
        if not do_horn then
            return
        end

        local horn_rate = GetModConfigData("voltgoat_horn")

        for _, t in ipairs(_G.LootTables['lightninggoat'] or {}) do
            if t[1] == 'lightninggoathorn' then --found it
                if t[2] < horn_rate then
                    t[2] = horn_rate
                end

                break --one guarantee is sufficient
            end
        end

        for _, t in ipairs(_G.LootTables['chargedlightninggoat'] or {}) do
            if t[1] == 'lightninggoathorn' then
                if t[2] < horn_rate then
                    t[2] = horn_rate
                end

                break
            end
        end

        do_horn = nil
    end

    AddPrefabPostInit("lightninggoat", function(inst)
        adjust_goat_horn()
    end)
end
