#version 420

// original https://www.shadertoy.com/view/tstSD7

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 tmat(vec2 t)
{
  mat3 r;
  r[0] = vec3(1.0, 0.0, 0.0);
  r[1] = vec3(0.0, 1.0, 0.0);
  r[2] = vec3(t, 1.0);
  return r;
}

mat3 rmat(float a)
{
    mat3 r;
    float s = sin(a);
    float c = cos(a);
    r[0] = vec3(c, s, 0.0);
    r[1] = vec3(-s, c, 0.0);
    r[2] = vec3(0.0, 0.0, 1.0);
    return r;
}

void main(void)
{
    float R = 0.5 * min(resolution.x, resolution.y) - 10.0;
    float l1 = R * 0.1;
    float l2 = R * 0.2;
    float W = 2.0;
    
    float time = date.w;
    
    float hours = time / 3600.0;
    float sec = time - trunc(hours) * 3600.0;
    float minutes = sec / 60.0;
    sec = sec - trunc(minutes) * 60.0;
    
    mat3 t = tmat(-resolution.xy * 0.5);
    mat3 hm = rmat(radians(-90.0 + hours / 12.0 * 360.0)) * t;
    vec3 hp = hm * vec3(gl_FragCoord.xy, 1.0);
    mat3 mm = rmat(radians(-90.0 + minutes / 60.0 * 360.0)) * t;
    vec3 mp = mm * vec3(gl_FragCoord.xy, 1.0);
    mat3 sm = rmat(radians(-90.0 + sec / 60.0 * 360.0)) * t;
    vec3 sp = sm * vec3(gl_FragCoord.xy, 1.0);
    
    vec3 col = vec3(1.0);
    if(hp.x > 0.0 && hp.x < R && abs(hp.y) < 5.0) 
        col = mix(vec3(0.0), col, smoothstep(2.0, 4.0, abs(hp.y)));
    if(mp.x > 0.0 && mp.x < R && abs(mp.y) < 3.0) 
        col = mix(vec3(0.0), col, smoothstep(1.0, 2.0, abs(mp.y)));
    if(sp.x > 0.0 && sp.x < R && abs(sp.y) < 2.0) 
        col = mix(vec3(0.0), col, smoothstep(0.0, 1.0, abs(sp.y)));
    
    float d = abs(distance(gl_FragCoord.xy, resolution.xy * 0.5) - R - 5.0);
    if (d < 2.0) col = mix(vec3(0.0), col, smoothstep(0.0, 1.0, d)); 
    
    for(float i = 0.0; i < 60.0; i++)
    {
        sm = rmat(radians(-90.0 + i / 60.0 * 360.0)) * t;
        sp = sm * vec3(gl_FragCoord.xy, 1.0);
        if(sp.x > 0.9 * R && sp.x < R && abs(sp.y) < 2.0) 
            col = mix(vec3(0.0), col, smoothstep(0.0, 1.0, abs(sp.y)));
    }
    
    for(float i = 0.0; i < 12.0; i++)
    {
        sm = rmat(radians(-90.0 + i / 12.0 * 360.0)) * t;
        sp = sm * vec3(gl_FragCoord.xy, 1.0);
        if(sp.x > 0.8 * R && sp.x < R && abs(sp.y) < 3.0) 
            col = mix(vec3(0.0), col, smoothstep(0.0, 2.0, abs(sp.y)));
    }
    
    glFragColor = vec4(col,1.0);
}
