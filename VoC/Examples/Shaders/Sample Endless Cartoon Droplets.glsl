#version 420

// original https://www.shadertoy.com/view/WsyGWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define SURFACE_DIST .01
#define FOG_START 4.
#define FOG_END 10.
#define MAX_DIST FOG_END + 1.
#define PI 3.14159265359

// Noise 3 to 1
float N31(vec3 id) {
 id = fract(id * vec3(244.224, 441.211, 521.198));
 id += dot(id, vec3(63.6, 9.1, 55.3));
 return fract(id.x * id.y * id.z);
}

// Noise 3 to 3
vec3 N33(vec3 id) {
 id = fract(id * vec3(266.234, 881.211, 572.598));
 id += dot(id, vec3(67.6, 981.1, 5.3));
 return vec3(fract(id.x * id.y), fract(id.y * id.z), fract(id.z * id.x));
}

// Gets distance from point p to capsule a to b with radius r.
float d_capsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0., 1.);
    
    vec3 c = a + ab*t;
    
    // Make capsule thinner at center
    float mx = cos(t*2.*PI)*.5+.5;
    
    return length(p-c)-mix(r*.2, r, mx);
}

// Gets a random corner for the cube.
vec3 RandomCorner(vec3 id) {
    float s = .65;
    float r = N31(id);
    if (r < .25) {
        return vec3(-s, -s, -s);
    } else if (r < .5) {
        return vec3(-s, s, -s);
    } else if (r < .75) {
        return vec3(-s, s, s);
    } else {
        return vec3(s, s, -s);
    }
}

// Get distance to scene
float GetDist(vec3 p, vec3 rd) {
    // Get direction so that we don't search in wrong direction
    float ox = (rd.x > 0.) ? 1. : 0.;
    float oy = (rd.y > 0.) ? 1. : 0.;
    float oz = (rd.z > 0.) ? 1. : 0.;
       
    // square id
    vec3 id = floor(p / 2.);
    
    // Domain repetition
    p = vec3(mod(p.x, 2.)-1.,mod(p.y, 2.)-1., mod(p.z, 2.)-1.);//, );

    float sphere_d = MAX_DIST;
    // Search in xyz offset by direction.
    for(float x = -1.+ox;x<=ox;x++) {
        for(float y = -1.+oy;y<=oy;y++) {
            for(float z = -1.+oz;z<=oz;z++) {
                // Get random corner for this square
                vec3 v = RandomCorner(id + vec3(x, y, z));
                
                // Get capsule distance
                float d = d_capsule(p, v + vec3(x, y, z) * 2., -v + vec3(x, y, z) * 2., .3);//mh_length(p-sphere.xyz)-sphere.w;
                
                // Calc min
                sphere_d = min(sphere_d, d);
            }
        }
    }
    return sphere_d;
}

// March ray, returns distance and iterations
float RayMarch(vec3 ro, vec3 rd, out int its) {
    float d_o = 0.;  
    its = 0;
    for(int i=0;i<MAX_STEPS;i++) {
         vec3 c_p = ro + (rd * d_o);   
        float d_s = GetDist(c_p, rd);
        d_o+= d_s;
        its++;
        if ((d_s < SURFACE_DIST) || (d_o > MAX_DIST)) break;
    }
            
    return d_o;
}

// Guess normal at position p
vec3 GetNormal(vec3 p) {
    vec2 e = vec2(SURFACE_DIST, 0.);
    float d = GetDist(p, vec3(0.));
    vec3 n = d - vec3(
        GetDist(p-e.xyy, vec3(-1., 0., 0.)),
        GetDist(p-e.yxy, vec3(0., -1., 0.)),
        GetDist(p-e.yyx, vec3(0., 0., -1.))
    );
    return normalize(n);
}

// Get light level at position p
float GetLight(vec3 p) {
    // light position
       vec3 light = vec3(0., 5., -3. + time);
    vec3 lv = normalize(light-p);//lightvector
    vec3 nv = GetNormal(p);//normalvector
    int its = 0;
    float lightlevel = smoothstep(.3,.7,clamp(dot(lv, nv), 0., 1.));
    float shadow = (RayMarch(p+(nv*SURFACE_DIST*2.), lv, its) < length(light-p)) ? 0. : 1.;
    return 0.3 + ((lightlevel * shadow) * .7);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    // Ray origin, Ray direction
    vec3 ro = vec3(cos(time*0.8)*.4, 5.+sin(time*0.8)*.4, -6. + time);
    vec3 rd = normalize(vec3(uv.x-cos(time*0.8)*.1, uv.y-sin(time*0.8)*.1, 1.));
    
    // get iterations and distance to scene
    int its = 0;
    float d = RayMarch(ro, rd, its);
       
    // Dont bother if beyond fog reach
    if(d<FOG_END) {
        
        // Make more iterations darker
        float outline = smoothstep(.75, .65, float(its)/40.);
        
        // Get hit position
        vec3 pos = ro + (rd * d);
        
        // Get random color at position
           vec3 posid = floor(pos / 2.);
        vec3 col_at_pos = (.2+N33(posid)*.8);
        
        // Calculate final pixel color
        col = col_at_pos * GetLight(pos) * smoothstep(FOG_END, FOG_START, d) * outline;
    }

    glFragColor = vec4(col,1.0);
}
