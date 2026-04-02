#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/MdcBWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float xor(vec2 p, vec2 lims, float A)
{
    return smoothstep(lims.x, lims.y, float(int(A*p.x) ^ int(A*p.y))/A);
}

float pattern(vec2 gl_FragCoord)
{
    const float TS = 4.0*120.0/131.0;
    vec2 uv = -1.0+2.0*gl_FragCoord.xy/resolution.xy;
    uv.y *= resolution.y/resolution.x;
    uv /= 1.0+0.5*sin(time*2.065*0.25);
    uv *= 0.75;
    
    const float PI = 3.141593;
    const float RC = 4.0;
    const float a = PI/RC;
    const float tq = 60.0;
    const vec2 lims = vec2(0.495,0.505);
    const mat2 R = mat2(cos(a),sin(a),-sin(a),cos(a));
    float rf = time*2.065*0.25*0.25;
    mat2 R2 = mat2(cos(rf),sin(rf),-sin(rf),cos(rf));
    
    uv *= R2;
    
    // TODO: the 2.065 constant is not exact, idk what it should actually be
    float A = exp(15.0+mod(-time*0.25, 2.065));
    float p = xor(uv, lims, A);
    
    for(int i = 0; i < int(RC)-1; i++)
    {
        if(p > 0.0) break;
        uv *= 1.5+0.5*sin(time*2.065*0.25);
        uv *= R;
        p = xor(uv, lims, A);
    }
    
    return p;
}

void main(void)
{
    float p = 0.0;
    const float S = 1.0/3.0;
    p += pattern(gl_FragCoord.xy+vec2(0));
    p += pattern(gl_FragCoord.xy+vec2(S,0));
    p += pattern(gl_FragCoord.xy+vec2(-S,0));
    p += pattern(gl_FragCoord.xy+vec2(0,S));
    p += pattern(gl_FragCoord.xy+vec2(0,-S));
    p += pattern(gl_FragCoord.xy+vec2(-S,S));
    p += pattern(gl_FragCoord.xy+vec2(S,-S));
    p += pattern(gl_FragCoord.xy+vec2(S));
    p += pattern(gl_FragCoord.xy+vec2(-S));
    p /= 9.0;
    glFragColor = vec4(sqrt(p));
}
