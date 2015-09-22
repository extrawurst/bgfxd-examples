module common;

import derelict.bgfx.bgfx;

bgfx_memory_t* loadMem(string _filePath)
{
    bgfx_memory_t res;
    
    import std.file;
    import core.stdc.stdio;
    import std.string;
    
    assert(exists(_filePath));
    
    auto file = fopen(toStringz(_filePath), "rb");
    scope(exit) fclose(file);
    fseek(file, 0, SEEK_END);
    auto size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    assert(size > 1);
    
    auto data = bgfx_alloc(cast(uint32_t)size+1);
    
    fread(data.data, size, 1, file);
    
    data.data[size]=0;
    
    return data;
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
    
    return bgfx_create_shader(loadMem(filePath));
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
    
    return bgfx_create_program(vsh, fsh, true /* destroy shaders when program is destroyed */);
}