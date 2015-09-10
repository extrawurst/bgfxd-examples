import std.stdio;

import std.stdio;
import std.algorithm:max;

import derelict.bgfx.bgfx;
import derelict.glfw3.glfw3;

struct PosColorVertex
{
    float m_x;
    float m_y;
    float m_z;
    uint32_t m_abgr;

    static bgfx_vertex_decl_t ms_decl;

    static void init()
    {
        bgfx_vertex_decl_begin(&ms_decl);
        bgfx_vertex_decl_add(&ms_decl, BGFX_ATTRIB_POSITION, 3, BGFX_ATTRIB_TYPE_FLOAT);
        bgfx_vertex_decl_add(&ms_decl, BGFX_ATTRIB_COLOR0, 4, BGFX_ATTRIB_TYPE_UINT8);
        bgfx_vertex_decl_end(&ms_decl);
    }
}

static PosColorVertex[8] s_cubeVertices =
[
    PosColorVertex(-1.0f,  1.0f,  1.0f, 0xff000000 ),
    PosColorVertex( 1.0f,  1.0f,  1.0f, 0xff0000ff ),
    PosColorVertex(-1.0f, -1.0f,  1.0f, 0xff00ff00 ),
    PosColorVertex( 1.0f, -1.0f,  1.0f, 0xff00ffff ),
    PosColorVertex(-1.0f,  1.0f, -1.0f, 0xffff0000 ),
    PosColorVertex( 1.0f,  1.0f, -1.0f, 0xffff00ff ),
    PosColorVertex(-1.0f, -1.0f, -1.0f, 0xffffff00 ),
    PosColorVertex( 1.0f, -1.0f, -1.0f, 0xffffffff ),
];

static uint16_t[36] s_cubeIndices =
[
    0, 1, 2, // 0
        1, 3, 2,
        4, 6, 5, // 2
        5, 6, 7,
        0, 2, 4, // 4
        4, 2, 6,
        1, 5, 3, // 6
        5, 7, 3,
        0, 4, 1, // 8
        4, 5, 1,
        2, 3, 6, // 10
        6, 3, 7,
];

uint16_t width = 1024;
uint16_t height = 768;
uint32_t dbg = BGFX_DEBUG_TEXT;
uint32_t reset = BGFX_RESET_VSYNC;

bgfx_memory_t loadMem(string _filePath)
{
    bgfx_memory_t res;

    import std.file;
    writefln("loadmem: %s",_filePath);

    auto filecontent = cast(ubyte[])read(_filePath) ~ '\0';

    assert(filecontent.length > 1);

    res.data = filecontent.ptr;
    res.size = cast(uint)filecontent.length;

    return res;
}

bgfx_shader_handle_t loadShader(string _name)
{
    string shaderPath = "shaders/dx9/";
    
    switch (bgfx_get_renderer_type())
    {
        case BGFX_RENDERER_TYPE_DIRECT3D11:
        case BGFX_RENDERER_TYPE_DIRECT3D12:
            shaderPath = "shaders/dx11/";
            break;
            
        case BGFX_RENDERER_TYPE_OPENGL:
            shaderPath = "shaders/glsl/";
            break;
            
        case BGFX_RENDERER_TYPE_METAL:
            shaderPath = "shaders/metal/";
            break;
            
        case BGFX_RENDERER_TYPE_OPENGLES:
            shaderPath = "shaders/gles/";
            break;
            
        default:
            break;
    }

    string filePath = shaderPath ~ _name ~ ".bin";

    auto mem = loadMem(filePath);
    writefln("bgfx_create_shader: %s",filePath);
    writefln("%s",mem);
    return bgfx_create_shader(&mem);
}

bgfx_program_handle_t loadProgram(string _vsName, string _fsName)
{
    bgfx_shader_handle_t vsh = loadShader(_vsName);
    bgfx_shader_handle_t fsh = bgfx_shader_handle_t(BGFX_INVALID_HANDLE);
    if (_fsName.length>0)
    {
        fsh = loadShader(_fsName);
        assert(fsh.idx);
    }

    assert(vsh.idx);
   
    writefln("bgfx_create_program"); 
    return bgfx_create_program(vsh, fsh, true /* destroy shaders when program is destroyed */);
}

void main()
{
    DerelictBgfx.load();
    DerelictGLFW3.load();

    GLFWwindow* window;
    
    /* Initialize the library */
    if (!glfwInit())
        return;
    
    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(width/2, height/2, "Hello World", null, null);
    if (!window)
    {
        glfwTerminate();
        return;
    }
    
    /* Make the window's context current */
    glfwMakeContextCurrent(window);

    bgfx_platform_data_t pd;
    pd.nwh          = glfwGetCocoaWindow(window);
    pd.context      = glfwGetNSGLContext(window);
    bgfx_set_platform_data(&pd);

    auto resInit = bgfx_init();

    assert(resInit);

    bgfx_reset(width, height, reset);

    // Enable debug text.
    bgfx_set_debug(dbg);
    
    // Set view 0 clear state.
    bgfx_set_view_clear(0
        , BGFX_CLEAR_COLOR | BGFX_CLEAR_DEPTH
        , 0x303030ff
        , 1.0f
        , 0
        );

    // Create vertex stream declaration.
    PosColorVertex.init();

    // Create static vertex buffer.
    auto m_vbh = bgfx_create_vertex_buffer(
        // Static data can be passed with bgfx::makeRef
        bgfx_make_ref(s_cubeVertices.ptr, s_cubeVertices.sizeof)
        , &PosColorVertex.ms_decl, 0
        );

    assert(m_vbh.idx);
    
    // Create static index buffer.
    auto m_ibh = bgfx_create_index_buffer(
        // Static data can be passed with bgfx::makeRef
        bgfx_make_ref(s_cubeIndices.ptr, s_cubeIndices.sizeof )
        , 0
        );

    assert(m_ibh.idx);
    
    // Create program from shaders.
    auto m_program = loadProgram("vs_cubes", "fs_cubes");

    assert(m_program.idx);

    while (!glfwWindowShouldClose(window))
    {
        // Set view 0 default viewport.
        bgfx_set_view_rect(0, 0, 0, width, height);
            
        // This dummy draw call is here to make sure that view 0 is cleared
        // if no other draw calls are submitted to view 0.
        bgfx_touch(0);

        // Use debug font to print information about this example.
        bgfx_dbg_text_clear();
        bgfx_dbg_text_printf(0, 1, 0x4f, "bgfx/examples/01-cube");
        bgfx_dbg_text_printf(0, 2, 0x6f, "Description: Rendering simple static mesh.");
        //bgfx_dbg_text_printf(0, 3, 0x0f, "Frame: % 7.3f[ms]", cast(double)(frameTime)*toMs);
            
        // Advance to next frame. Rendering thread will be kicked to
        // process submitted rendering primitives.
        bgfx_frame();

        /* Poll for and process events */
        glfwPollEvents();
    }

    // Shutdown bgfx.
    bgfx_shutdown();
    glfwTerminate();
}
