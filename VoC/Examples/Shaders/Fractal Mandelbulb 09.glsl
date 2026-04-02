#version 420

// original https://www.shadertoy.com/view/ltVSRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    The BRDF used in this shader is based on those used by Disney and Epic Games.
    
    The input parameters and individual components are modelled after the ones
    described in

        https://de45xmedrsdbp.cloudfront.net/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf

    The various components are then combined based on Disney's PBR shader, found here

        https://github.com/wdas/brdf/blob/master/src/brdfs/disney.brdf
    
    I'd recommend reading this for a description of what the parameters in this BRDF do

        http://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf

    
*/

#define ITERS 20
#define POWER 11.0
#define BAILOUT 1.5

//Ray march detail - lower numbers increase detail
#define DETAIL 0.5

#define OCC_STRENGTH 4.0
#define OCC_ITERS 25

float closeObj = 0.0;
const float PI = 3.14159;

mat3 rotX(float d){
    float s = sin(d);
    float c = cos(d);
    return mat3(1.0, 0.0, 0.0,
                0.0,   c,  -s,
                0.0,   s,   c );
}

mat3 rotY(float d){
    float s = sin(d);
    float c = cos(d);
    return mat3(  c, 0.0,  -s,
                0.0, 1.0, 0.0,
                  s, 0.0,   c );
}

mat3 rotZ(float d){
    float s = sin(d);
    float c = cos(d);
    return mat3(  c,  -s, 0.0,
                  s,   c, 0.0,
                0.0, 0.0, 1.0);
}

//From http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
float mandelbulb(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < ITERS ; i++) {
        r = length(z);
        if (r>BAILOUT) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, POWER-1.0)*POWER*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,POWER);
        theta = theta*POWER;
        phi = phi*POWER;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return 0.5*log(r)*r/dr;
}
    
vec2 vecMin(vec2 a, vec2 b){
    if(a.x <= b.x){
        return a;
    }
    return b;
}

float lastx = radians(180.0);
float lasty = 0.0;

vec2 mapMat(vec3 p){
    
    //Map
    mat3 mouserot = rotZ(radians(lastx) / 1.5) * rotX(radians(lasty) / 1.5);
     
    vec2 bulb = vec2(mandelbulb(mouserot * p), 3.0);
    
    return bulb;
}

//Returns the min distance
float map(vec3 p){
    return mapMat(p).x;
}

float trace(vec3 ro, vec3 rd){
    float t = 0.0;
    float d = 0.0;
    float w = 1.3;
    float ld = 0.0;
    float ls = 0.0;
    float s = 0.0;
    float cerr = 10000.0;
    float ct = 0.0;
    float pixradius = DETAIL / resolution.y;
    vec2 c;
    int inter = 0;
    for(int i = 0; i < 512; i++){
        ld = d;
        c = mapMat(ro + rd * t);
        d = c.x;
        
        //Detect intersections missed by over-relaxation
        if(w > 1.0 && abs(ld) + abs(d) < s){
            s -= w * s;
            w = 1.0;
            t += s;
            continue;
        }
        s = w * d;
        
        float err = d / t;
        
        if(abs(err) < abs(cerr)){
            ct = t;
            cerr = err;
        }
        
        //Intersect when d / t < one pixel
        if(abs(err) < pixradius){
            inter = 1;
            break;
        }
        
        t += s;
        if(t > 20.0){
            break;
        }
    }
    closeObj = c.y;
    if(cerr < 0.2 && inter != 1){
        ct = -2.0;
        closeObj = cerr;
    }else if(inter == 0){
        ct = -1.0;
    }
    return ct;
}

//Approximate normal
vec3 normal(vec3 p){
    return normalize(vec3(map(vec3(p.x + 0.0001, p.yz)) - map(vec3(p.x - 0.0001, p.yz)),
                          map(vec3(p.x, p.y + 0.0001, p.z)) - map(vec3(p.x, p.y - 0.0001, p.z)),
                          map(vec3(p.xy, p.z + 0.0001)) - map(vec3(p.xy, p.z - 0.0001))));
}

vec3 camPos = vec3(0.0);
vec3 lightPos = vec3(0.0);

float occlusion(vec3 ro, vec3 rd){
    float k = 1.0;
    float d = 0.0;
    float occ = 0.0;
    for(int i = 0; i < OCC_ITERS; i++){
        d = map(ro + 0.1 * k * rd);
        occ += 1.0 / pow(2.0, k) * (k * 0.1 - d);
        k += 1.0;
    }
    return 1.0 - clamp(occ * OCC_STRENGTH, 0.0, 1.0);
}

vec3 colour(vec3 p, float id){
    
    if(id == 1.0){
       return vec3(0.0);
    }
    
    vec3 n = normal(p);
    
    float o = occlusion(p, n);
    return vec3(o);
  
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    camPos = vec3(0.0 , 0.0, -2.5);
    
    lastx += mouse.x*resolution.x - 0.5;
    lasty += mouse.y*resolution.y - 0.5;
    
    vec3 ro = camPos;
    vec3 rd = normalize(vec3(uv, 1.5));
    float d = trace(ro, rd);
    vec3 c = ro + rd * d;
    vec3 col = vec3(1.0);
    //If intersected
    if(d > 0.0){
        //Colour the point
        col = colour(c, closeObj);
        col *= 1.0 / exp(d * 0.25);
    }else if(d == -2.0){
        col = vec3(0.25) * (1.0 / exp(closeObj * 600.0));
    }else{
        col = vec3(0.0);
    }
    
    col = pow( col, vec3(0.4545) );
    glFragColor = vec4(col,1.0);
}
