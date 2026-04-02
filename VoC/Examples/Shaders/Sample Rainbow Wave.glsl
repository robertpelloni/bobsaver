#version 420

// original https://www.shadertoy.com/view/XdSSWy

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float cube_width = 20.0;
float wave_width = 2.5;
float PI = 3.1415926;
vec4 rainbow_color(int i)
{
    vec4 c;
    
    if (i == 0) c=vec4(0,0,0,0); else
    if (i == 1) c= vec4(255,43,14,255)/255.0; else
    if (i == 2) c= vec4(255,168,6,255)/255.0; else
    if (i == 3) c= vec4(255,244,0,255)/255.0; else
    if (i == 4) c= vec4(51,234,5,255)/255.0; else
    if (i == 5) c= vec4(8,163,255,255)/255.0; else
    if (i == 6) c= vec4(122,85,255,255)/255.0; else
        c=vec4(0,0,0,0);
    return c;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = 1.0 - 2.0 * uv;
   
    //wave
    vec4 wave_color = vec4(0.);
    for(int i = 0;i<7;++i)
    {
        float y = 0.1 * sin(uv.x*PI + float(i)/3. + time*PI ) + uv.y+float(i)/10.0 - 0.5;
        float wave = abs(1.0 / (y * resolution.y /wave_width));
        wave_color += rainbow_color(i)*wave;
    }
    
    //back ground
    float c1 = mod(gl_FragCoord.x,2.0 * cube_width);
    c1 = smoothstep(cube_width*0.7,cube_width*1.3,c1);
    float c2 = mod(gl_FragCoord.y,2.0 * cube_width);
    c2 = smoothstep(cube_width*0.7,cube_width*1.3,c2);
    vec4 bcolor = mix(vec4(0.0,0.2,0.3,1.0),vec4(0.5,0.0,0.,1.0),c1*c2);
    glFragColor = bcolor + wave_color;
}
