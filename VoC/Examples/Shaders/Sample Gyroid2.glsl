#version 420

// original https://www.shadertoy.com/view/wd2BRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 gyroid(vec3 p) 
{
    vec3 s = vec3(sin(p.xyz));
    vec3 c = vec3(cos(p.zxy));
    vec3 result = vec3(dot(s,c));
    return result;    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= 1.4;

    float sc = 16.0;
    float tt = trunc(time);
    float tf = fract(time);
    tf = smoothstep(0.0,1.0,tf);
    float t= tf+tt;
    vec3 p = vec3(uv*sc,t*1.0);
    vec3 col=vec3(0.,0.,0.);
    col.x = float(gyroid(p+vec3(0,0,0.0)));
    col.y = float(gyroid(p+vec3(0,0,0.2)));
    col.z = float(gyroid(p+vec3(0,0,0.4)));
                   
    col = abs(col);
    col.x = pow(col.x,0.6);
    col.y = pow(col.y,0.9);
    col.z = pow(col.z,0.8);

    col *= 0.8;

    // Output to screen
    glFragColor = vec4(col,1.0);
}

