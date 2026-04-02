#version 420

// original https://www.shadertoy.com/view/Wd33DB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 200
#define MIN_DIST .01
#define MAX_DIST 200.

float sdTorus( vec3 p, vec2 t ){
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float GetDist(vec3 p){
    float plane = p.y + .1;
    //float sphere = length(vec3(-2., 2., 5) - p) - 1.;
    //float sphere2 = length(vec3(0., 2.5, 4.5) - p) - .8;
    //float wut = min(sphere, sphere2);
    
    float size = 5.;
    vec3 id = floor(vec3(p.x, min(p.y, 5.), p.z) / size);
    
    vec3 pos = vec3(id*size+size*.5);
    float wut = distance(pos, p) - 1.;
    //float wut = sdTorus((p-pos)*vec3(1,1.5,1), vec2(.8));
    
    
     return min(plane, wut);   
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return n/e.x;
}

vec2 RayMarch(vec3 ro, vec3 rd){
    float d0 = 0.;
    float minD = MAX_DIST*99.;
    
    for(int x = 0; x < MAX_STEPS; x++){
        vec3 p = ro + rd * d0;
        float dS = GetDist(p);
        d0 += dS;
        if(dS < minD)minD = dS;
        if(dS < MIN_DIST || d0 > MAX_DIST)break;
    }
    
    return vec2(d0, minD);
}

vec3 GetColor(vec3 p){
    return p.y > .99 ? 
        (mod(dot(floor(p/5.),vec3(1)), 2.) == 0. ? vec3(1,.2,.2) : vec3(.5,.5,1)) : 
        (mod(dot(floor(p.xz*1.),vec2(1)), 2.) == 0. ? vec3(1) : vec3(.8));
}

vec3 GetMaterial(vec3 p, vec3 n){
    vec3 col = vec3(0);
    
    //diffuse
    vec3[] lights = vec3[](
        vec3(-5. + time*2., 100., 200.),
        vec3(0. + time*2., 10., -1.)
            );
    
    vec3[] light_colors = vec3[](
        vec3(1., .9, .9) * .5,
        vec3(.9, .8, .8)
            );
    
    for(int i=0; i<lights.length(); i++){
        vec3 light = lights[i];
        
        vec3 lmp = light - p;
        float ld = length(lmp);
        vec3 l = lmp / ld;
    
        //shadow
        float pneumbra = .1 + ld * .005;
        vec2 sd = RayMarch(p + n * (.02+pneumbra), l);
        float shadow = sd.x < MAX_DIST ? .0 : (sd.y < pneumbra ? sd.y/pneumbra : 1.);
        
        float lum = max(0., dot(n, l));
        col += lum * light_colors[i] * shadow;
    }
    
    return col * GetColor(p);
}

vec3 R3(vec3 p){
    return fract(cross(sin(p*vec3(872234.85, 312348.77137, 44456.82)), vec3(.2179, 1.5215, 2.155411)));  
}
float R1(vec3 p){
    return fract(dot(sin(p*vec3(31189.3, 74.5542, 9511.332)), vec3(1.5486, .5915, 3.14851)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    float angle = time * .1;
    float sa = sin(angle);
    float ca = cos(angle);
    mat2 yrotm = mat2(ca, -sa, sa, ca);
    
    float fov = 1.;
    vec3 ro = vec3(sin(-angle*1.)*-10. + time *2., sin(time*.5)*5. + 5.2, cos(-angle*1.)*-20. + 4.);
    //vec3 ro = vec3(time * 2. + 5., 5., 2.);
    vec3 rd = normalize( vec3(uv.xy * fov, 1) );
    rd.xz *= yrotm;
    
    vec2 rm = RayMarch(ro, rd);
    if(rm.x > MAX_DIST){
        //col = vec3(.5,.5,1.);
    }else{
        //ambient
        //col += vec3(.5,.5,1.) * .1;
        
        //base
        vec3 p = ro + rd * rm.x;
        //randomized "rough" normal
        vec3 n = normalize(GetNormal(p) + R3(p) * .01 
                           + vec3(sin(p.x*7.15),1.,sin(p.z*1.37))*.01  );
        
        col += GetMaterial(p, n);
    
        //reflection
        vec3 r = reflect(rd, n);
        vec2 rrm = RayMarch(p + n*.02, r);
        vec3 p2 = rrm.x * r + p;
        vec3 n2 = GetNormal(p2);
    
        col += GetMaterial(p2, n2) * GetColor(p) * mix(.6, .0, dot(-rd, n));
    }
    
    // Output to screen
    glFragColor = vec4(col * .8,1.0);
}
