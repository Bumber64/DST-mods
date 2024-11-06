
local _G = GLOBAL
if not _G.TheNet:GetIsServer() then
    return
end

-------------------------------------------
---------------- Settings -----------------
-------------------------------------------

local cfg_name =
{
    "batilisk_nitre",
    "batilisk_wing",
    "bee_honey",
    "bee_stinger",
    "bird_morsel",
    "bird_feather",
    "canary_saffron",
    "bunnyman_carrot",
    "bunnyman_meat",
    "bunnyman_tail",
    "butterfly_butter",
    "catcoon_tail",
    "cookiecutter_shell",
    "dragonfly_egg",
    "hound_tooth",
    "hound_redgem",
    "hound_bluegem",
    "krampus_pack",
    "mactusk_hat",
    "mactusk_tusk",
    "marotter_bottle",
    "pigman_meat",
    "pigman_skin",
    "spider_silk",
    "spider_gland",
    "slurperpelt",
    "slurtle_helm",
    "snurtle_armor",
    "tentacle_spot",
    "voltgoat_horn",
}

local cfg = {}
for _,s in ipairs(cfg_name) do
    local n = GetModConfigData(s)
    cfg[string.upper(s)] = type(n) == "number" and n or 0.0
end

cfg_name = nil --don't need table anymore

-------------------------------------------
--------------- Utility fns ---------------
-------------------------------------------

local function ensure_loot(ld, item, chance)
    --make sure lootdropper has item as chance loot with given minimum chance
    if not ld or chance <= 0.0 then
        return
    end

    local shared_table --if found in chanceloottable
    local found_entry
    local found_value = 0.0

    local lt = ld.chanceloottable and _G.LootTables[ld.chanceloottable] or nil
    if lt then
        for _,t in ipairs(lt) do
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
        for _,t in pairs(ld.chanceloot) do
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
        for _,t in pairs(ld.chanceloot) do
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

    for _,t in pairs(ld.randomloot) do
        for i=1, n do --add extra drops for numrandomloot > 1
            ld:AddChanceLoot(t.prefab, t.weight / w)
        end
    end

    ld.randomloot = nil --this also clears ld.totalrandomweight when necessary
    --keep ld.numrandomloot for haunted loot
end

-------------------------------------------
----------------- Finally -----------------
-------------------------------------------

if cfg.BATILISK_NITRE > 0.0 or cfg.BATILISK_WING > 0.0 or cfg.VOLTGOAT_HORN > 0.0 then

    local function adjust_loot_table(tbl, item, chance) --adjust LootTable entry
        if chance <= 0.0 then
            return --default
        end
        for _,t in ipairs(_G.LootTables[tbl] or {}) do
            if t[1] == item then --found it
                if t[2] < chance then
                    t[2] = chance
                end
                break --one guarantee is sufficient
            end
        end
    end

    AddSimPostInit(function() --done once on world load
        adjust_loot_table("bat_acidinfused", "nitre", cfg.BATILISK_NITRE)

        adjust_loot_table("bat_acidinfused", "batwing", cfg.BATILISK_WING)
        adjust_loot_table("bat", "batwing", cfg.BATILISK_WING)

        adjust_loot_table("lightninggoat", "lightninggoathorn", cfg.VOLTGOAT_HORN)
        adjust_loot_table("chargedlightninggoat", "lightninggoathorn", cfg.VOLTGOAT_HORN)
    end)
end

if cfg.BEE_HONEY > 0.0 or cfg.BEE_STINGER > 0.0 then
    for _,v in ipairs({"bee", "killerbee"}) do
        AddPrefabPostInit(v, function(inst)
            local ld = inst.components.lootdropper
            convert_rand_loot(ld)

            ensure_loot(ld, "honey", cfg.BEE_HONEY)
            reduce_loot(ld, "stinger", cfg.BEE_STINGER) --stingers are trash
        end)
    end
end

if cfg.BIRD_MORSEL > 0.0 or cfg.BIRD_FEATHER > 0.0 then
    for k,v in pairs({crow = "feather_crow", puffin = "feather_crow", robin = "feather_robin", robin_winter = "feather_robin_winter"}) do
        AddPrefabPostInit(k, function(inst)
            local ld = inst.components.lootdropper
            convert_rand_loot(ld)

            ensure_loot(ld, "smallmeat", cfg.BIRD_MORSEL)
            ensure_loot(ld, v, cfg.BIRD_FEATHER)
        end)
    end
end

if cfg.CANARY_SAFFRON > 0.0 then
    AddPrefabPostInit("canary", function(inst)
        local ld = inst.components.lootdropper
        convert_rand_loot(ld)

        ensure_loot(ld, "smallmeat", 1.0)
        ensure_loot(ld, "feather_canary", cfg.CANARY_SAFFRON)
    end)
end

if cfg.BUNNYMAN_CARROT > 0.0 or cfg.BUNNYMAN_MEAT > 0.0 or cfg.BUNNYMAN_TAIL > 0.0 then
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
            ensure_loot(ld, "carrot", cfg.BUNNYMAN_CARROT)
            ensure_loot(ld, "meat", cfg.BUNNYMAN_MEAT)
            ensure_loot(ld, "manrabbit_tail", cfg.BUNNYMAN_TAIL)
        end)
    end)
end

if cfg.BUTTERFLY_BUTTER > 0.0 then
    AddPrefabPostInit("butterfly", function(inst)
        local ld = inst.components.lootdropper
        convert_rand_loot(ld)

        ensure_loot(ld, "butterflywings", 1.0)
        ensure_loot(ld, "butter", cfg.BUTTERFLY_BUTTER)
    end)
end

if cfg.CATCOON_TAIL > 0.0 then
    AddPrefabPostInit("catcoon", function(inst)
        ensure_loot(inst.components.lootdropper, "coontail", cfg.CATCOON_TAIL)
    end)
end

if cfg.COOKIECUTTER_SHELL > 0.0 then
    AddPrefabPostInit("cookiecutter", function(inst)
        ensure_loot(inst.components.lootdropper, "cookiecuttershell", cfg.COOKIECUTTER_SHELL)
    end)
end

if cfg.DRAGONFLY_EGG > 0.0 then
    AddPrefabPostInit("dragonfly", function(inst)
        ensure_loot(inst.components.lootdropper, "lavae_egg", cfg.DRAGONFLY_EGG)
    end)
end

if cfg.HOUND_TOOTH > 0.0 then
    AddPrefabPostInit("hound", function(inst)
        ensure_loot(inst.components.lootdropper, "houndstooth", cfg.HOUND_TOOTH)
    end)
end

if cfg.HOUND_REDGEM > 0.0 then
    AddPrefabPostInit("firehound", function(inst)
        ensure_loot(inst.components.lootdropper, "redgem", cfg.HOUND_REDGEM)
    end)
end

if cfg.HOUND_BLUEGEM > 0.0 then
    AddPrefabPostInit("icehound", function(inst)
        ensure_loot(inst.components.lootdropper, "bluegem", cfg.HOUND_BLUEGEM)
    end)
end

if cfg.KRAMPUS_PACK > 0.0 then
    AddPrefabPostInit("krampus", function(inst)
        ensure_loot(inst.components.lootdropper, "krampus_sack", cfg.KRAMPUS_PACK)
    end)
end

if cfg.MACTUSK_HAT > 0.0 or cfg.MACTUSK_TUSK > 0.0 then
    AddPrefabPostInit("walrus", function(inst)
        local ld = inst.components.lootdropper
        ensure_loot(ld, "walrushat", cfg.MACTUSK_HAT)
        ensure_loot(ld, "walrus_tusk", cfg.MACTUSK_TUSK)
    end)
end

if cfg.MAROTTER_BOTTLE > 0.0 then
    AddPrefabPostInit("otter", function(inst)
        ensure_loot(inst.components.lootdropper, "messagebottle", cfg.MAROTTER_BOTTLE)
    end)
end

if cfg.PIGMAN_MEAT > 0.0 or cfg.PIGMAN_SKIN > 0.0 then
    local function adjust_pig_loot(ld)
        convert_rand_loot(ld)
        ensure_loot(ld, "meat", cfg.PIGMAN_MEAT)
        ensure_loot(ld, "pigskin", cfg.PIGMAN_SKIN)
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

if cfg.SPIDER_SILK > 0.0 or cfg.SPIDER_GLAND > 0.0 then
    for _,v in ipairs({"spider", "spider_warrior", "spider_hider", "spider_spitter", "spider_dropper", "spider_moon", "spider_healer", "spider_water"}) do
        AddPrefabPostInit(v, function(inst)
            local ld = inst.components.lootdropper
            convert_rand_loot(ld)

            if cfg.SPIDER_SILK >= 0.25 then
                ensure_loot(ld, "silk", cfg.SPIDER_SILK)
            else --less trash
                reduce_loot(ld, "silk", cfg.SPIDER_SILK)
            end

            if cfg.SPIDER_GLAND >= 0.25 then
                ensure_loot(ld, "spidergland", cfg.SPIDER_GLAND)
            else --less trash
                reduce_loot(ld, "spidergland", cfg.SPIDER_GLAND)
            end
        end)
    end
end

if cfg.SLURPERPELT > 0.0 then
    AddPrefabPostInit("slurper", function(inst)
        ensure_loot(inst.components.lootdropper, "slurper_pelt", cfg.SLURPERPELT)
    end)
end

if cfg.SLURTLE_HELM > 0.0 then
    AddPrefabPostInit("slurtle", function(inst)
        ensure_loot(inst.components.lootdropper, "slurtlehat", cfg.SLURTLE_HELM)
    end)
end

if cfg.SNURTLE_ARMOR > 0.0 then
    AddPrefabPostInit("snurtle", function(inst)
        ensure_loot(inst.components.lootdropper, "armorsnurtleshell", cfg.SNURTLE_ARMOR)
    end)
end

if cfg.TENTACLE_SPOT > 0.0 then
    for _,v in ipairs({"tentacle", "tentacle_pillar"}) do
        AddPrefabPostInit(v, function(inst)
            ensure_loot(inst.components.lootdropper, "tentaclespots", cfg.TENTACLE_SPOT)
        end)
    end
end
