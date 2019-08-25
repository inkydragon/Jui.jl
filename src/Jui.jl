module Jui

using MLStyle

using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using Printf

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

# @data JWidget begin
#     JButton(String)
#     JText(String)
# end


macro jwindow(name, expr)
    # gen_window(name, expr) |> esc
    @when :(begin $(es...) end) = expr begin
        map(es) do e
            @match e begin
                ln::LineNumberNode => ln
                :(button($bname)) => :(CImGui.Button($bname))
                :(text($s)) => :(CImGui.Text($s))
                :(image($w, $h)) => :(CImGui.Image(Ptr{Cvoid}(image_id), ($w, $h)))
                node => node
            end
        end |> exprs ->
            Expr(:block,
                :(CImGui.Begin($name)),
                exprs...,
                :(CImGui.End())
            )
    end
end

# function gen_window(name :: String, expr)
#     @when :(begin $(es...) end) = expr begin
#         map(es) do e
#             @match e begin
#                 ln::LineNumberNode => ln
#                 JButton(bname::String) => :(CImGui.Button($bname))
#                 JText(s::String) => :(CImGui.Text($s))
#                 node => node
#             end
#         end |> exprs ->
#             Expr(:block,
#                 :(CImGui.Begin($name)),
#                 exprs...,
#                 :(CImGui.End())
#             )
#     end
# end


# function addWindow(name::String)
#     CImGui.Begin(name)  # create a window called "Hello, world!" and append into it.
#     CImGui.Text("This is some useful text.")  # display some text
# 
#     CImGui.Button("Button")
# 
#     CImGui.SameLine()
#     CImGui.Text("counter")
# 
#     CImGui.End()
# end

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
# CImGui.StyleColorsClassic()
# CImGui.StyleColorsLight()

# setup Platform/Renderer bindings
ImGui_ImplGlfw_InitForOpenGL(window, true)
ImGui_ImplOpenGL3_Init(glsl_version)

img_width, img_height = 256, 256
image_id = ImGui_ImplOpenGL3_CreateImageTexture(img_width, img_height)
clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
while !GLFW.WindowShouldClose(window)
    # oh my global scope
    # TODO: remove all global variables
    global clear_color
    global image_id, img_width, img_height

    GLFW.PollEvents()
    # start the Dear ImGui frame
    ImGui_ImplOpenGL3_NewFrame()
    ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()

    # show a simple window that we create ourselves.
    # we use a Begin/End pair to created a named window.
    
    image = rand(GLubyte, 4, img_width, img_height)
    ImGui_ImplOpenGL3_UpdateImageTexture(image_id, image, img_width, img_height)
    @jwindow "my window" begin
        button("Button111")
        text("some text")
        image(256, 256)
    end
    
    @cstatic f=Cfloat(0.0) counter=Cint(0) begin
        CImGui.Begin("Hello, world!")  # create a window called "Hello, world!" and append into it.
        CImGui.Text("This is some useful text.")  # display some text
        
        @c CImGui.SliderFloat("float", &f, 0, 1)  # edit 1 float using a slider from 0 to 1
        CImGui.ColorEdit3("clear color", clear_color)  # edit 3 floats representing a color
        CImGui.Button("Button") && (counter += 1)
        
        # CImGui.Button("Button-addWindow") && addWindow("new windows")

        CImGui.SameLine()
        CImGui.Text("counter = $counter")
        CImGui.Text(@sprintf("Application average %.3f ms/frame (%.1f FPS)", 1000 / CImGui.GetIO().Framerate, CImGui.GetIO().Framerate))

        CImGui.End()
    end
   

    # rendering
    CImGui.Render()
    GLFW.MakeContextCurrent(window)
    display_w, display_h = GLFW.GetFramebufferSize(window)
    glViewport(0, 0, display_w, display_h)
    glClearColor(clear_color...)
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

end # module Jui
