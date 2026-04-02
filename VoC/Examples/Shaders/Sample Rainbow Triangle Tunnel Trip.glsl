#version 420

// original https://www.shadertoy.com/view/dsK3Ry

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float gyroid(vec3 p, float scale, float bias, float thickness) {
    p *= scale;
    float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
    return d/scale;
}

    
float map(vec3 p) {
    return gyroid(p, 1., 1.3, .05)+.06;
    //return gyroid(p, 1., 1.+.6*pow(sin(time), 2.), .05);
    //return min(gyroid(p, 1., 1.47, .05), gyroid(p+ 3.14159*vec3(0., 1., 1.), 1., 1.47, .05));
}

mat2 rot(in float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c,-s,s,c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    
    
    vec3 ro = vec3(.5, 0., 3.*3.14159*time); // mod(time, 3.) // ugly fix
    vec3 rd = normalize(vec3(uv, 3.));
    
    mat2 rot = rot(-4./27.*3.14159); // (still goes off track)
    rd.xz *= rot;
    ro.xz *= rot;
    ro += vec3( 4., 0., 0.);

    
    float t=0.;
    for (int i=1; i<256; i++) {
        if (t > 256.) break;
        vec3 p = ro + rd*t;
        float dt = .7*map(p);
        if (dt < .01)  break;
        t += dt;
    }
    
    vec3 col = .585+.415*sin(t + 3.14159*vec3(0, .5, 1.)); //vec3(.25,1.,2.)
    col = vec3(1.-exp(-t/32.* col));
    col *=  vec3(1.-exp(-t/4.* col));

    glFragColor = vec4(pow(col, vec3(.4545)), 1);
}
