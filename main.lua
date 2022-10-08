#include "constants.lua"

G_DEV = true

STATES = {
    enabled = false,
    playing = false,

    set_keyframe_duration = 1,
    set_keyframe_interp = 2,

    current_keyframe = 0
}

KEYFRAMES = {}

CURRENT_TIME = 0
CURRENT_INTERP = 0
CURRENT_SECOND = 0

CURRENT_POS = nil
CURRENT_ROT = nil

CURRENT_POS_X = nil
CURRENT_POS_Y = nil
CURRENT_POS_Z = nil

CURRENT_ROT_X = nil
CURRENT_ROT_Y = nil
CURRENT_ROT_Z = nil
CURRENT_ROT_W = nil

-- #region Main

function init()
    RegisterTool("cineline", "Cineline [FD]", "MOD/vox/lasergun.vox")
    SetBool("game.tool.cineline.enabled", true)
end

function tick(delta)
    if not(GetString("game.player.tool") == "cineline") then
        STATES.enabled = false
        return
    end

    STATES.enabled = true

    if InputDown('t') and #KEYFRAMES > 0 then
        SetBool("game.input.locktool", true)

        if InputValue("mousewheel") ~= 0 then
            local modify_by = 0.5
            if InputDown("shift") then
                modify_by = 1
            elseif InputDown("ctrl") then
                modify_by = 0.1
            end

            local offset = modify_by * InputValue("mousewheel")
            local new_target_time = STATES.set_keyframe_duration + offset

            if new_target_time > 0 then
                STATES.set_keyframe_duration = new_target_time
            end
        end
    end

    if InputPressed('y') then
        STATES.set_keyframe_interp = (STATES.set_keyframe_interp % #ENUM_INTERP_TYPE) + 1
    end

    if InputPressed('g') then
        local player_pos = GetPlayerCameraTransform()

        if #KEYFRAMES ~= 0 then
            table.insert(KEYFRAMES,
            {
                time = KEYFRAMES[#KEYFRAMES].time + STATES.set_keyframe_duration,
                interp_type = STATES.set_keyframe_interp,
                duration = STATES.set_keyframe_duration,

                pos = player_pos.pos,
                rot = player_pos.rot,

                init = false
            }
        )
        else
            table.insert(KEYFRAMES,
            {
                time = 0,
                interp_type = STATES.set_keyframe_interp,

                pos = player_pos.pos,
                rot = player_pos.rot,

                init = false
            }
        )
        end

        -- STATES.target_keyframe_time = KEYFRAMES[#KEYFRAMES].time + 1
    end

    if InputPressed('c') then
        KEYFRAMES = {}

        STATES.playing = false
        STATES.current_keyframe = 0
        STATES.set_keyframe_duration = 1
    end

    if InputPressed('p') then
        STATES.playing = not STATES.playing

        if STATES.playing then
            CURRENT_TIME = 0

            for _, frame in ipairs(KEYFRAMES) do
                frame.init = false
            end
        end
    end

    if not STATES.playing then return end

    ---------------------------------------------------
    -- Beyond this point
    -- Cineline playing camera animation
    ---------------------------------------------------

    if #KEYFRAMES < 2 then
        STATES.playing = false
        return
    end

    CURRENT_TIME = CURRENT_TIME + delta

    local keyframe_iter = #KEYFRAMES
    while keyframe_iter > 0 and KEYFRAMES[keyframe_iter].time >= CURRENT_TIME do
        keyframe_iter = keyframe_iter - 1
    end

    local keyframe_current = KEYFRAMES[keyframe_iter]

    local keyframe_next = keyframe_iter + 1
    if keyframe_next > #KEYFRAMES then
        STATES.playing = false
        return
    end

    keyframe_next = KEYFRAMES[keyframe_next]

    CURRENT_INTERP = mapToRange(CURRENT_TIME, keyframe_current.time, keyframe_current.time + keyframe_next.duration, 0, 1)

    dWatch("CURRENT TIME", CURRENT_TIME)
    dWatch("CURRENT INTERP", CURRENT_INTERP)
    dWatch("CURRENT SECOND", CURRENT_SECOND)

    if not keyframe_current.init then
        if keyframe_iter == 1 then
            CURRENT_POS_X = keyframe_current.pos[1]
            CURRENT_POS_Y = keyframe_current.pos[2]
            CURRENT_POS_Z = keyframe_current.pos[3]

            CURRENT_ROT_X = keyframe_current.rot[1]
            CURRENT_ROT_Y = keyframe_current.rot[2]
            CURRENT_ROT_Z = keyframe_current.rot[3]
            CURRENT_ROT_W = keyframe_current.rot[4]
        end

        local interp_type = ENUM_INTERP_TYPE[keyframe_current.interp_type] or "linear"
        local duration = keyframe_next.duration or 1

        SetValue('CURRENT_POS_X', keyframe_next.pos[1], interp_type, duration)
        SetValue('CURRENT_POS_Y', keyframe_next.pos[2], interp_type, duration)
        SetValue('CURRENT_POS_Z', keyframe_next.pos[3], interp_type, duration)

        SetValue('CURRENT_ROT_X', keyframe_next.rot[1], interp_type, duration)
        SetValue('CURRENT_ROT_Y', keyframe_next.rot[2], interp_type, duration)
        SetValue('CURRENT_ROT_Z', keyframe_next.rot[3], interp_type, duration)
        SetValue('CURRENT_ROT_W', keyframe_next.rot[4], interp_type, duration)

        keyframe_current.init = true
    end

    CURRENT_POS = {
        CURRENT_POS_X,
        CURRENT_POS_Y,
        CURRENT_POS_Z
    }

    CURRENT_ROT = {
        CURRENT_ROT_X,
        CURRENT_ROT_Y,
        CURRENT_ROT_Z,
        CURRENT_ROT_W
    }

    dWatch("CURRENT POS", CURRENT_POS)
    dWatch("CURRENT ROT", CURRENT_ROT)

    local transform_new = Transform(CURRENT_POS, CURRENT_ROT)
    SetCameraTransform(transform_new, 75)
end

function update(delta)

end

function draw()
    UiPush()
        UiTranslate(200, 100)
        UiColor(1, 1, 1, 1)
        UiFont('regular.ttf', 24)
        UiText(STATES.set_keyframe_duration, true)
        UiText(ENUM_INTERP_TYPE[STATES.set_keyframe_interp], true)
    UiPop()
end

-- #endregion Main