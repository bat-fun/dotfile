-- ANIMATIONS --

-- Curves
hl.curve("smooth", {
    type = "bezier",
    points = { {0.22, 1.00}, {0.36, 1.00} },
})

hl.curve("quick", {
    type = "bezier",
    points = { {0.15, 0.00}, {0.10, 1.00} },
})

-- Global
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 4,
    bezier = "smooth",
})

-- Windows
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "popin 94%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 2,
    bezier = "quick",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "slide",
})

-- Fade
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 2,
    bezier = "smooth",
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1,
    bezier = "quick",
})

-- Layers / Panels
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3,
    bezier = "smooth",
    style = "fade",
})

-- Workspaces
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "slidefade 18%",
})


-- Scratchpad / Special workspace
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "slidefadevert 18%",
})


-- Border
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 3,
    bezier = "smooth",
})

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 5,
    bezier = "smooth",
    style = "once",
})

-- Zoom
hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 4,
    bezier = "smooth",
})
