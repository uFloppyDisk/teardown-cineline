#include "utils.lua"

G_DEV = true

STATES = {
    playing = false
}

POS = {}

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
    if InputPressed('f') then
        local player_pos = GetPlayerCameraTransform()
        table.insert(POS,
            {
                pos = player_pos.pos,
                rot = player_pos.rot
            }
        )
    end

    if InputPressed('c') then
        POS = {}
    end

    if InputPressed('p') then
        CURRENT_TIME = 0
        STATES.playing = not STATES.playing
    end

    if STATES.playing then
        CURRENT_TIME = CURRENT_TIME + delta
        CURRENT_INTERP = CURRENT_TIME % 1

        local current_second_calc = math.floor(CURRENT_TIME) + 1

        local isNewKeyFrame = false
        if (current_second_calc) ~= CURRENT_SECOND then isNewKeyFrame = true end
        CURRENT_SECOND = current_second_calc

        dWatch("CURRENT TIME", CURRENT_TIME)
        dWatch("CURRENT INTERP", CURRENT_INTERP)
        dWatch("CURRENT SECOND", CURRENT_SECOND)

        local next = CURRENT_SECOND + 1
        if next > #POS then
            STATES.playing = false
            return
        end

        local keyframe_next = {pos = {}, rot = {}}

        if isNewKeyFrame then
            local pos_next = POS[next]

            dPrint(next)
            keyframe_next.pos = pos_next.pos
            keyframe_next.rot = pos_next.rot

            CURRENT_POS_X = POS[CURRENT_SECOND].pos[1]
            CURRENT_POS_Y = POS[CURRENT_SECOND].pos[2]
            CURRENT_POS_Z = POS[CURRENT_SECOND].pos[3]

            CURRENT_ROT_X = POS[CURRENT_SECOND].rot[1]
            CURRENT_ROT_Y = POS[CURRENT_SECOND].rot[2]
            CURRENT_ROT_Z = POS[CURRENT_SECOND].rot[3]
            CURRENT_ROT_W = POS[CURRENT_SECOND].rot[4]

            SetValue('CURRENT_POS_X', keyframe_next.pos[1], "cosine", 1)
            SetValue('CURRENT_POS_Y', keyframe_next.pos[2], "cosine", 1)
            SetValue('CURRENT_POS_Z', keyframe_next.pos[3], "cosine", 1)

            SetValue('CURRENT_ROT_X', keyframe_next.rot[1], "cosine", 1)
            SetValue('CURRENT_ROT_Y', keyframe_next.rot[2], "cosine", 1)
            SetValue('CURRENT_ROT_Z', keyframe_next.rot[3], "cosine", 1)
            SetValue('CURRENT_ROT_W', keyframe_next.rot[4], "cosine", 1)
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
end

function update(delta)

end

function draw()
    
end

-- #endregion Main