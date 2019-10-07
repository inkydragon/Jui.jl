using CImGui
using CImGui.LibCImGui
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using CImGui.CSyntax
using Printf
using CImGui.CSyntax.CStatic
using CImGui: ImVec2, ImVec4, IM_COL32, ImU32,
    GetVersion, Get_BackendPlatformName, Get_BackendRendererName

@static if Sys.isapple()
    const glsl_version = 150
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
else
    const glsl_version = 130
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
end
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)

window1 = GLFW.CreateWindow(1280, 720, "Julia Demo")
@assert window1 != C_NULL
GLFW.MakeContextCurrent(window1)
ctx1 = CImGui.CreateContext()
CImGui.StyleColorsDark()
ImGui_ImplGlfw_InitForOpenGL(window1, true)
ImGui_ImplOpenGL3_Init(glsl_version)


clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
window1_open = true
while window1_open
    global clear_color;
    global window1_open;
    GLFW.PollEvents()
    
    GLFW.WindowShouldClose(window1) && (window1_open = false;)
    if window1_open
        GLFW.MakeContextCurrent(window1)
        CImGui.SetCurrentContext(ctx1)
        GLFW.PollEvents()
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame(window1)
        CImGui.NewFrame()
        
        CImGui.Begin("Example: Custom rendering")
        draw_list = CImGui.GetWindowDrawList()
        io = CImGui.GetIO()
        CImGui.Text(@sprintf("Dear ImGui %s Backend Checker", unsafe_string(GetVersion())))
        CImGui.Text(@sprintf("io.BackendPlatformName: %s", unsafe_string(io.BackendPlatformName)))
        CImGui.Text(@sprintf("io.BackendRendererName: %s", unsafe_string(io.BackendRendererName)))
        CImGui.Separator()
        
        if CImGui.TreeNode("0001: Renderer: Large Mesh Support")
            begin 
                vtx_count = @cstatic vtx_count=Cint(6_000) begin
                    @c CImGui.CImGui.SliderInt("VtxCount##1", &vtx_count, 0, 100_000, "%d")
                end
                p = CImGui.GetCursorScreenPos()
                for n in 0:ceil(Int, vtx_count/4)
                    off_x = (n % 100) * 3.0
                    off_y = (n % 100) * 1.0
                    col = IM_COL32(((n * 17) & 255), ((n * 59) & 255), ((n * 83) & 255), 255);
                    CImGui.AddRectFilled(draw_list, ImVec2(p.x + off_x, p.y + off_y), ImVec2(p.x + off_x + 50, p.y + off_y + 50), col)
                end
                CImGui.Dummy(ImVec2(300 + 50, 100 + 20))
                CImGui.Text(@sprintf("VtxBuffer.Size = %d", unsafe_load(draw_list).VtxBuffer.Size))
            end
            begin
                vtx_count = @cstatic vtx_count=Cint(6_000) begin
                    @c CImGui.CImGui.SliderInt("VtxCount##2", &vtx_count, 0, 100_000, "%d")
                end
                p = CImGui.GetCursorScreenPos()
                for n in 0:ceil(Int, vtx_count/(10*4))
                    off_x = (n % 100) * 3.0
                    off_y = (n % 100) * 1.0
                    col = IM_COL32(((n * 17) & 255), ((n * 59) & 255), ((n * 83) & 255), 255);
                    CImGui.AddText(draw_list, ImVec2(p.x + off_x, p.y + off_y), col, "ABCDEFGHIJ")
                end
                CImGui.Dummy(ImVec2(300 + 50, 100 + 20))
                CImGui.Text(@sprintf("VtxBuffer.Size = %d", unsafe_load(draw_list).VtxBuffer.Size))
            end
            CImGui.TreePop()
        end

        CImGui.End()
        
        CImGui.Render()
        GLFW.MakeContextCurrent(window1)
        display_w, display_h = GLFW.GetFramebufferSize(window1)
        glViewport(0, 0, display_w, display_h)
        glClearColor(clear_color...)
        glClear(GL_COLOR_BUFFER_BIT)
        ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData())
        GLFW.SwapBuffers(window1)
    else
        GLFW.HideWindow(window1)
    end

end

ImGui_ImplOpenGL3_Shutdown()
ImGui_ImplGlfw_Shutdown()
CImGui.DestroyContext(ctx1)
GLFW.DestroyWindow(window1)
