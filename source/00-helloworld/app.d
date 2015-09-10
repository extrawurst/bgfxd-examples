import std.stdio;

import std.algorithm:max;
import derelict.bgfx.bgfx;
import derelict.glfw3.glfw3;

import logo;

uint16_t width = 1024;
uint16_t height = 768;
uint32_t dbg = BGFX_DEBUG_TEXT;
uint32_t reset = BGFX_RESET_VSYNC;

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
	version(darwin)
	{
		pd.nwh          = glfwGetCocoaWindow(window);
		pd.context      = glfwGetNSGLContext(window);
	}
	else version(Windows)
	{
		pd.nwh          = glfwGetWin32Window(window);
		pd.context      = null;
	}
	else
	{
		static assert(false, "platform not yet supported");
	}
	
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

    while (!glfwWindowShouldClose(window))
    {
        // Set view 0 default viewport.
        bgfx_set_view_rect(0, 0, 0, width, height);
            
        // This dummy draw call is here to make sure that view 0 is cleared
        // if no other draw calls are submitted to view 0.
        bgfx_touch(0);

        // Use debug font to print information about this example.
        bgfx_dbg_text_clear();
        bgfx_dbg_text_image(4
                , 4
                , 40
                , 12
                , s_logo.ptr
                , 160
                );

        bgfx_dbg_text_printf(0, 1, 0x4f, "bgfx/examples/00-helloworld");
        bgfx_dbg_text_printf(0, 2, 0x6f, "Description: Initialization and debug text.");
            
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
