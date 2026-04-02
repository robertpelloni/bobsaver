#version 420

// original https://www.shadertoy.com/view/XlXXWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Voxel Deblockification
    2015 BeyondTheStatic

    - changed shader name to something more accurate (and somewhat Bush-like)
    - ditched the rotation matrix & used rotate() instead (works correctly in IE now)
*/
const float maxDist = 100.;

float s, c;
#define rotate(p, a) mat2(c=cos(a), s=-sin(a), -s, c) * p

float strand(in vec3 p) {
    p.y += 2. * cos(p.z*3.14159265/8.);
    return length(mod(p.xy, 16.) - 8.)-2.;
}

float map(in vec3 p) {
    float f;
    p.xz += 4.;
    f = min(2.,    strand(p));
    f = min(f,    strand(vec3(p.x+8., p.y, p.z+8.)));
    f = min(f,    strand(vec3(p.zy, p.x+8.)));
    f = min(f,    strand(vec3(p.z+8., p.yx)));
    return f;
}

void main(void) {
    vec2 res    = resolution.xy;
    vec2 uv        = (gl_FragCoord.xy-.5*res) / res.y;
    vec2 mPos    = 3.5 * (mouse.xy-.5*res) / res.y;
    
    vec3 camPos    = vec3(.5);
    vec3 rayDir    = normalize(vec3(uv, .5));
    
    rayDir.yz = rotate(rayDir.yz, mPos.y);
    rayDir.xz = rotate(rayDir.xz, mPos.x);
    
    camPos.z += 8. * time;
    
    vec3 adj, xV, yV, zV, V_;
    vec3 po    = sign(rayDir);
    vec3 V    = camPos, LV=vec3(0.0);
    float dist = -1.;
    bool didHit = false;
    
    for(int i=0; i<140; i++) {
        dist = length(V-camPos);
        
        LV = V;
        
        adj = mix(floor(V+po), ceil(V+po), .5-.5*po) - V;
        
        xV = adj.x * vec3(1., rayDir.yz/rayDir.x);
        yV = adj.y * vec3(rayDir.xz/rayDir.y, 1.);
        zV = adj.z * vec3(rayDir.xy/rayDir.z, 1.);

        V_ = vec3(length(xV)<length(yV) ? xV : yV.xzy);
        V_ = vec3(length(V_)<length(zV) ? V_ : zV);
        
        V += V_;
        
        if(map(LV+V_/2.)<0.){didHit=true; break;}
        if(dist>maxDist) break;
    }
    
    // some really basic ray marching to adjust intersection point
    vec3 pos = LV;
    for(int i=0; i<5; i++) {
        float d = map(pos);
        pos += rayDir * d;
        if(d>1.) break;
    }
    LV = pos;
    
    float f = map(LV+1.)/4. + .5;
    
    vec3 col = vec3(.2, 1., .3);
    col = mix(.2-.4*col, col, f);
    
    glFragColor = vec4(mix(col, vec3(1., 1.3, 1.5), float(didHit ? length(LV-camPos)/maxDist : 1.)), 1.0);
}
