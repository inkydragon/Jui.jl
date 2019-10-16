using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using Printf
using CImGui: ImVec2, ImVec4, IM_COL32, ImU32
using CImGui.CSyntax.CFor

include("LSystem.jl")
using .LSystem: RULES, genStep, getAllRules


##== init GLFW ==##
@static if Sys.isapple()
    # OpenGL 3.2 + GLSL 150
    const _glsl_version = 150
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
else
    # OpenGL 3.0 + GLSL 130
    const _glsl_version = 130
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
end
# setup GLFW error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)
##== init GLFW end ==##

_width, _hight, _wd_name = (1280, 720, "Demo")
# StyleColorsDark
##== init window & context ==##
# create window
_window_1 = GLFW.CreateWindow(_width, _hight, _wd_name)
@assert _window_1 != C_NULL
GLFW.MakeContextCurrent(_window_1)
GLFW.SwapInterval(1)  # enable vsync
_ctx_1 = CImGui.CreateContext() # setup Dear ImGui context
CImGui.StyleColorsDark() # setup Dear ImGui style
# setup Platform/Renderer bindings
ImGui_ImplGlfw_InitForOpenGL(_window_1, true)
ImGui_ImplOpenGL3_Init(_glsl_version)
##== init window & context end ==##


_clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
rule_list = getAllRules() # user's code
while !GLFW.WindowShouldClose(_window_1) ## Main Cycle
    GLFW.MakeContextCurrent(_window_1)
    CImGui.SetCurrentContext(_ctx_1)
    GLFW.PollEvents()
    # start the Dear ImGui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()
    ## new frame begin


    #= Add widgets ---------------------------------------------------------- =#
    CImGui.SetNextWindowSize((350, 560), CImGui.ImGuiCond_FirstUseEver)
    CImGui.Begin("Example: Custom rendering")
    draw_list = CImGui.GetWindowDrawList()

    CImGui.Text("L-Systems")
    listbox_item_current, listbox_items = @cstatic listbox_item_current=Cint(0) listbox_items=rule_list begin
        # list box
        @c CImGui.ListBox("L-Systems\n(click to select one)", &listbox_item_current, listbox_items, length(listbox_items), 5)
    end
    CImGui.Text("L-System parameters")
    iter, angle, slen = @cstatic iter=Cint(4) angle=Cfloat(0.0) slen=Cfloat(10) begin
        @c CImGui.CImGui.SliderInt("Iteration times", &iter, 1, 8, "%d")
        @c CImGui.DragFloat("Initial angle", &angle, 1, -180.0, 180.0, "%.0f")
        @c CImGui.DragFloat("Step length",  &slen, 0.5, 0.5, 30, "%.0f")
    end
    CImGui.Separator()

    CImGui.Text("Lines")
    thickness, col = @cstatic thickness=Cfloat(2.0)  col=Cfloat[1.0,1.0,0.4,1.0] begin
        @c CImGui.DragFloat("Width", &thickness, 0.05, 1.0, 8.0, "%.02f")
        CImGui.ColorEdit4("Color", col)
    end
    CImGui.Text("Adjust Original Point")
    dx, dy = @cstatic dx=Cfloat(256.0) dy=Cfloat(128.0) begin
        @c CImGui.DragFloat("dx ->", &dx, 4, 0.0, 4096.0, "%.0f")
        @c CImGui.DragFloat("dy V",  &dy, 4, 0.0, 2048.0, "%.0f")
    end
    CImGui.Separator()

    @cstatic currentChild = 0
    wpos = CImGui.GetWindowPos()
    backupPos = CImGui.GetCursorScreenPos()

    # draw lines
    p = CImGui.GetCursorScreenPos()
    col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))

    begin
        x::Cfloat = p.x + 4.0 + dx
        y::Cfloat = p.y + 4.0 + dy
        th::Cfloat = thickness
        param = Dict(
            "iter" => iter,
            "direct" => angle,
            "start point" => (x,y),
            "step length" => slen,
        )

        # L System
        steps = genStep(RULES[listbox_item_current+1], param)
        
        for ((sx, sy), (ex, ey)) in steps
            CImGui.AddLine(draw_list,
                ImVec2(sx, sy),
                ImVec2(ex, ey),
                col32,
                th
            );
        end
    end

    CImGui.End() #= widgets end ---------------------------------------------=#


    ## rendering
    CImGui.Render()
    GLFW.MakeContextCurrent(_window_1)
    _display_w, _display_h = GLFW.GetFramebufferSize(_window_1)
    glViewport(0, 0, _display_w, _display_h)
    glClearColor(_clear_color...)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
    GLFW.MakeContextCurrent(_window_1)
    GLFW.SwapBuffers(_window_1)
end

## cleanup
ImGui_ImplOpenGL3_Shutdown()
ImGui_ImplGlfw_Shutdown()
CImGui.DestroyContext(_ctx_1)
GLFW.DestroyWindow(_window_1) # # GLFW_init tail
