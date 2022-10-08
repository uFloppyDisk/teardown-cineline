STATES_TIMELINE = {
    enabled = false,

    mouse_pos = {},
    hitscan = {
        hit = false,
        pos = Vec(),
        dist = nil
    },
    camera_settings = {
        camera_transform = nil,
        target_camera_fov = nil,
        current_camera_fov = nil
    },
    camera_defaults = {},

    sample_depth_offset = 0
}

CAMERA_ELEVATION_OFFSET_MAX = 200
CAMERA_ELEVATION_OFFSET_MIN = 20

CAMERA_CURRENT_FOV = nil
CAMERA_DEFAULT_FOV = nil

function timeline_init()
    if STATES_TIMELINE.camera_settings.camera_transform == nil then
        STATES_TIMELINE.camera_settings.camera_transform = Transform(Vec(0, -100, 0), QuatEuler(-90, 0, 0))
        CAMERA_DEFAULT_FOV = 30
        CAMERA_CURRENT_FOV = CAMERA_DEFAULT_FOV
        STATES_TIMELINE.camera_settings.target_camera_fov = CAMERA_CURRENT_FOV
        STATES_TIMELINE.camera_settings.current_camera_fov = CAMERA_CURRENT_FOV

        STATES_TIMELINE.camera_defaults = {unpack(STATES_TIMELINE.camera_settings)}
    end
end

function timeline_tick(delta)
    SetEnvironmentProperty("fogParams", 0, 0, 0, 0)
    SetEnvironmentProperty("fogColor", 0, 0, 0)
    SetEnvironmentProperty("snowamount", 0, 0)
    SetEnvironmentProperty("snowdir", 0, 0, 0, 0)
    SetEnvironmentProperty("rain", 0)

    -- Set new camera transform based on player input
    -- local camera_transform_new = getCameraTransform(STATES_TIMELINE.camera_settings.camera_transform, set_offset)
    -- STATES_TIMELINE.camera_settings.camera_transform = camera_transform_new

    if InputValue("mousewheel") ~= 0 then

        local offset = 1 * InputValue("mousewheel")
        STATES_TIMELINE.sample_depth_offset = clamp(STATES_TIMELINE.sample_depth_offset + offset, -90, 200)
    end

    STATES_TIMELINE.camera_settings.current_camera_fov = CAMERA_CURRENT_FOV
    SetCameraTransform(STATES_TIMELINE.camera_settings.camera_transform, STATES_TIMELINE.camera_settings.current_camera_fov)
end

function timeline_draw()
    function drawGrid(metres, width, world_depth, opacity)
        if opacity < 0.05 then
            return
        end

        local step = metres or 50
        local grid_width, grid_world_depth = width or 1, world_depth or 0
        local alpha = opacity or 1

        local ui_width, ui_height = UiWidth(), UiHeight()
        local point_below = Vec(STATES_TIMELINE.camera_settings.camera_transform.pos[1], 0, STATES_TIMELINE.camera_settings.camera_transform.pos[3])

        local current_point, current_point_inverted = {}, {}
        local wx, wz = math.ceil(point_below[1] / step) * step, math.ceil(point_below[3] / step) * step

        local iter = 1
        repeat
            local step_invert = ((iter * 2) - 1) * step
            local wxi, wzi = wx - step_invert, wz - step_invert

            current_point = {UiWorldToPixel(Vec(wx, grid_world_depth, wz))}
            current_point[4], current_point[5] = wx, wz

            current_point_inverted = {UiWorldToPixel(Vec(wxi, grid_world_depth, wzi))}
            current_point_inverted[4], current_point_inverted[5] = wxi, wzi

            UiPush()
                UiColor(1, 1, 1, alpha)
                UiPush()
                    UiTranslate(current_point[1], 0)
                    UiRect(grid_width, ui_height)
                UiPop()
                UiPush()
                    UiTranslate(0, current_point[2])
                    UiRect(ui_width, grid_width)
                UiPop()
                UiPush()
                    UiTranslate(current_point_inverted[1], 0)
                    UiRect(grid_width, ui_height)
                UiPop()
                UiPush()
                    UiTranslate(0, current_point_inverted[2])
                    UiRect(ui_width, grid_width)
                UiPop()
            UiPop()

            wx, wz = wx + step, wz + step
            iter = iter + 1
        until (current_point[1] > ui_width and current_point[2] > ui_height)
    end
    function drawHUDMarker(pos, initial_rect_size, colour)
        local x, y, dist = UiWorldToPixel(pos)
        local rect_colour = colour or getRGBA(COLOUR["white"], 1)
        local rect_size = initial_rect_size or 10
        rect_size = clamp(rect_size * (1 * (100 / (dist * (CAMERA_CURRENT_FOV / 75)))), 10, 30)

        local rect_w, rect_h = rect_size, rect_size

        UiPush()
            UiTranslate(x - (rect_w / 2), y - (rect_h / 2))
            UiColor(unpack(rect_colour))
            UiRect(rect_w, rect_h)
        UiPop()
    end

    local function getStepDistance()
        local camera_pos = STATES_TIMELINE.camera_settings.camera_transform.pos

        local sample_depth = 100 + STATES_TIMELINE.sample_depth_offset
        local zero = UiWorldToPixel(Vec(0, camera_pos[2] - sample_depth, 0))
        local one = UiWorldToPixel(Vec(1, camera_pos[2] - sample_depth, 0))

        return one - zero
    end

    UiPush()
        UiMakeInteractive()
        local margins = {}
        margins.x0, margins.y0, margins.x1, margins.y1 = UiSafeMargins()

        UiPush()
            UiColor(0, 0, 0, 1)
            UiRect(UiWidth(), UiHeight())
            STATES_TIMELINE.mouse_pos = {UiGetMousePos()}
            local m_pos = STATES_TIMELINE.mouse_pos
            dWatch("Mouse Position", "{"..m_pos[1]..", "..m_pos[2].."}")

            -- drawGrid(1, 3, -200, 1)
        UiPop()

        local distance = getStepDistance()
        local height = UiHeight()
        UiPush()
            for i = 0, math.floor(UiWidth() / distance), 1 do
                UiTranslate(distance)
                UiRect(1, height * 0.25)
            end
        UiPop()
    UiPop()
end