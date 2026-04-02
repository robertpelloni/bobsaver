#version 420

// original https://www.shadertoy.com/view/NtXGz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 p[8];
float s[8] = float[](.1f,.2f,.1f,.4f, .1f, .12f, .11f, .5f);
float aspect = 16.f / 9.f;
vec3 light = vec3(1.f,1.f,1.f);

vec3 d(vec2 u) {
    vec3 a = vec3(0,0,0);;
    for(int i=0;i<8;i++) {
        vec2 d = u - p[i];
        float abs = 1.f / (d.x*d.x+d.y*d.y);
        a.y += s[i] * abs;
        a.xz += d.xy * abs;
    }
    return a;
}

vec3 n(vec3 i) {
    i = normalize(i);
    vec3 j = cross(i, vec3(0,4,0));
    return cross(i,j);
}

void u() {
    p[7].x = sin(time*.245f)*.5f+.5f; p[7].y = cos(time*.8f)*.14f+.5f;
    p[6].x = sin(time*.5f)*.7f+.5f; p[6].y = cos(time*.45f)*.34f+.5f;
    p[5].x = sin(time*.1f)*.4f+.8f; p[5].y = cos(time*.23f)*.1f+.6f;
    p[4].x = sin(time*.2f)*.8f+.8f; p[4].y = cos(time*.55f)*.2f+.8f;
    p[3].x = sin(time)*.2f+.5f; p[3].y = cos(time*.333333f)*.2f+.5f;
    p[2].x = sin(time*.5f)*.2f+.5f; p[2].y = cos(time*.7f)*.2f+.5f;
    p[1].x = sin(time*1.f)*.3f+.9f; p[1].y = cos(time*.1f)*.2f+.5f;
    p[0].x = sin(time*.8f)*.2f+.5f; p[0].y = cos(time*.9f)*.2f+.5f; 
}

vec3 shade(vec3 n, vec2 uv) {
    vec3 r = reflect(vec3(0,-1,0), n);
    return vec3(1,1,1)*clamp(dot(normalize(light-vec3(uv.x,0,uv.y)), n), 0.05f,1.f);
}

void main(void) {
    u();
    vec2 uv = gl_FragCoord.xy/resolution.xy*vec2(aspect,1.f);
    vec3 d = d(uv);
    if(d.y > 32.f) { 
        glFragColor = vec4(0.149,0.141,0.912, 255.0);
        //glFragColor = vec4(shade(n(d), uv),1);

    }
    else { glFragColor = vec4(0,0,0,0); }
    //glFragColor.x = pow(glFragColor.x, .4545454545f);
    //glFragColor.y = pow(glFragColor.y, .4545454545f);
    //glFragColor.z = pow(glFragColor.z, .4545454545f);
}
