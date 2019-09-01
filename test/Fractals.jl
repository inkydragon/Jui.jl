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

@static if Sys.isapple()
    # OpenGL 3.2 + GLSL 150
    const glsl_version = 150
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
else
    # OpenGL 3.0 + GLSL 130
    const glsl_version = 130
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
end

# setup GLFW error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)

# create window
window = GLFW.CreateWindow(1280, 720, "Demo")
@assert window != C_NULL
GLFW.MakeContextCurrent(window)
GLFW.SwapInterval(1)  # enable vsync

# setup Dear ImGui context
ctx = CImGui.CreateContext()
# setup Dear ImGui style
CImGui.StyleColorsDark()

# setup Platform/Renderer bindings
ImGui_ImplGlfw_InitForOpenGL(window, true)
ImGui_ImplOpenGL3_Init(glsl_version)

rule_list = getAllRules()

while !GLFW.WindowShouldClose(window)
    GLFW.PollEvents()
    # start the Dear ImGui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()

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

        CImGui.SetCursorScreenPos(backupPos)
        CImGui.BeginChild(currentChild+=1)
        draw_list = CImGui.GetWindowDrawList()
        for ((sx, sy), (ex, ey)) in steps
            CImGui.AddLine(draw_list,
                ImVec2(sx, sy),
                ImVec2(ex, ey),
                col32,
                th
            );
            if unsafe_load(draw_list)._VtxCurrentIdx > (2^16-2^10)
                CImGui.EndChild()

                CImGui.SetCursorScreenPos(backupPos)
                CImGui.BeginChild(currentChild+=1)
                draw_list = CImGui.GetWindowDrawList()
            end
        end
        CImGui.EndChild()
    end

    CImGui.End() #= widgets end ---------------------------------------------=#

    # rendering
    CImGui.Render()
    GLFW.MakeContextCurrent(window)
    display_w, display_h = GLFW.GetFramebufferSize(window)
    glViewport(0, 0, display_w, display_h)
    glClear(GL_COLOR_BUFFER_BIT)
    ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

    GLFW.MakeContextCurrent(window)
    GLFW.SwapBuffers(window)
end

# cleanup
ImGui_ImplOpenGL3_Shutdown()
ImGui_ImplGlfw_Shutdown()
CImGui.DestroyContext(ctx)

GLFW.DestroyWindow(window)
