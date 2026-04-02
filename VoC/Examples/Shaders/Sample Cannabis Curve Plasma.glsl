#version 420

// original https://www.shadertoy.com/view/4lyyDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// cannabis curve plasma shader

vec3 hsv2rgb(float h,float s,float v) {
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

void main(void)
{
        vec2 pos = -1.0 + 2.0 * ( gl_FragCoord.xy / resolution.xy );
        pos.x *= resolution.x/resolution.y;
        pos.y += 0.6;
        
        float r = length(pos);
        float th = atan(pos.y, pos.x);
        
        
        float color = 1.0/((r*2.0) - pow(1.5*(1.0+sin(th))*(1.0+0.9*cos(8.0*th))*(1.0+0.1*cos(24.0*th))*(0.5+0.05*cos(140.0*th)), sin(time)*0.3+0.8));
        glFragColor = vec4(hsv2rgb(((color+time/1.5) - th * 1.114), 1.0, clamp(5.0 - abs(color), 0.0, 1.0)) * (color < 0.01 ? vec3(0.0, 1.0, 0.0) : vec3(1.0))
                        + (color < 0.01 ? vec3(0.0, smoothstep(-5.0, 0.0, color), 0.0) : vec3(0.0)), 1.0 );    
}
