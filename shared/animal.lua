--==============================================================================
--  tm-bridge :: shared/animal.lua
--  Animal helpers (mostly for RDR3 where a lot of peds are wildlife).  Returns
--  classification booleans and sensible idle/walk anim references.
--==============================================================================

TM.Animal = {}

local CATS = {
    [`a_c_cat_01`]           = true,
}
local SMALL_DOGS = {
    [`a_c_chop`]             = true,
    [`a_c_husky`]            = true,
    [`a_c_pug_01`]           = true,
    [`a_c_poodle_01`]        = true,
    [`a_c_pomeranian_01`]    = true,
    [`a_c_corgi_01`]         = true,
    [`a_c_terrier_01`]       = true,
    [`a_c_westy_01`]         = true,
    [`a_c_dog_americanfoxhound_01`] = true,
    [`a_c_dog_aussiesheepdog_01`]   = true,
    [`a_c_dog_blackcollie_01`]      = true,
    [`a_c_dog_chesbayretriever_01`] = true,
    [`a_c_dog_hobocollie_01`]       = true,
}
local BIG_DOGS = {
    [`a_c_dog_rottweiler_01`]       = true,
    [`a_c_dog_husky_01`]            = true,
    [`a_c_dog_lab_01`]              = true,
    [`a_c_dog_stbernard_01`]        = true,
}
local COYOTES = {
    [`a_c_coyote_01`] = true,
}

local ALL = {}
for k in pairs(CATS) do ALL[k] = 'cat' end
for k in pairs(SMALL_DOGS) do ALL[k] = 'small_dog' end
for k in pairs(BIG_DOGS) do ALL[k] = 'big_dog' end
for k in pairs(COYOTES) do ALL[k] = 'coyote' end

local IDLE_ANIMS = {
    cat       = { dict = 'creatures_mammal@cat@normal@idle@idle_variations',  name = 'idle_a' },
    small_dog = { dict = 'creatures_mammal@dog@normal@idle@idle_variations',  name = 'idle_a' },
    big_dog   = { dict = 'creatures_mammal@dog@normal@idle@idle_variations',  name = 'idle_a' },
    coyote    = { dict = 'creatures_mammal@coyote@normal@idle@idle_variations', name = 'idle_a' },
}

--------------------------------------------------------------------------------
-- Classification
--------------------------------------------------------------------------------
function TM.Animal.Type(model)
    if type(model) ~= 'number' then model = joaat(model) end
    return ALL[model]
end

function TM.Animal.Is(model)        return TM.Animal.Type(model) ~= nil end
function TM.Animal.IsCat(model)     return TM.Animal.Type(model) == 'cat' end
function TM.Animal.IsDog(model)     local t = TM.Animal.Type(model) return t == 'small_dog' or t == 'big_dog' end
function TM.Animal.IsBigDog(model)  return TM.Animal.Type(model) == 'big_dog' end
function TM.Animal.IsSmallDog(model)return TM.Animal.Type(model) == 'small_dog' end
function TM.Animal.IsCoyote(model)  return TM.Animal.Type(model) == 'coyote' end

function TM.Animal.IdleAnim(model)
    local t = TM.Animal.Type(model)
    return t and IDLE_ANIMS[t] or nil
end

function TM.Animal.PedIs(ped)
    if not ped or not DoesEntityExist(ped) then return false end
    return TM.Animal.Is(GetEntityModel(ped))
end
