-- ============================================================
-- LUMEN FLUX
-- Directional / cinematic / stable
-- ============================================================

hl.curve("fluxIn", {
    type = "bezier",
    points = { {0.16, 0.90}, {0.22, 1.00} },
})

hl.curve("fluxOut", {
    type = "bezier",
    points = { {0.70, 0.00}, {0.84, 0.10} },
})

hl.curve("fluxMove", {
    type = "bezier",
    points = { {0.22, 1.00}, {0.36, 1.00} },
})

hl.curve("fluxFade", {
    type = "bezier",
    points = { {0.25, 0.00}, {0.15, 1.00} },
})


-- ============================================================
-- GLOBAL
-- ============================================================

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 5,
    bezier = "fluxMove",
})


-- ============================================================
-- WINDOWS
-- ============================================================

-- Actual style change:
-- no popin / no gnomed

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "fluxMove",
    style = "slide",
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 5,
    bezier = "fluxIn",
    style = "slide right",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4,
    bezier = "fluxOut",
    style = "slide left",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4,
    bezier = "fluxMove",
})


-- ============================================================
-- FADE
-- ============================================================

-- Keep fade restrained so movement is the star.

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 2,
    bezier = "fluxFade",
})

hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 3,
    bezier = "fluxIn",
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 2,
    bezier = "fluxOut",
})

hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 2,
    bezier = "fluxFade",
})

hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 3,
    bezier = "fluxFade",
})


-- ============================================================
-- LAYERS
-- ============================================================

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 4,
    bezier = "fluxMove",
    style = "slide",
})

hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 4,
    bezier = "fluxIn",
    style = "slide top",
})

hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 3,
    bezier = "fluxOut",
    style = "slide bottom",
})


-- ============================================================
-- WORKSPACES
-- ============================================================

-- Real spatial travel instead of fade-only.

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "fluxMove",
    style = "slidefade 30%",
})

hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 5,
    bezier = "fluxIn",
    style = "slidefade 30%",
})

hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 4,
    bezier = "fluxOut",
    style = "slidefade 30%",
})


-- ============================================================
-- SPECIAL WORKSPACE / SCRATCHPAD
-- ============================================================

-- Different motion language from normal workspaces.

hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 5,
    bezier = "fluxMove",
    style = "slidefadevert 25%",
})

hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 5,
    bezier = "fluxIn",
    style = "slidefadevert 25%",
})

hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 4,
    bezier = "fluxOut",
    style = "slidefadevert 25%",
})


-- ============================================================
-- BORDER
-- ============================================================

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 3,
    bezier = "fluxFade",
})

-- One-shot gradient rotation, not a continuous loop.
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 6,
    bezier = "fluxMove",
    style = "once",
})


-- ============================================================
-- ZOOM
-- ============================================================

hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 5,
    bezier = "fluxMove",
})