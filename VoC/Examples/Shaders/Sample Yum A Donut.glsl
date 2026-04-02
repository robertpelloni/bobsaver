#version 420

// original https://www.shadertoy.com/view/cdBXRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//██████╗░░█████╗░███╗░░██╗██╗░░░██╗████████╗  ██╗
//██╔══██╗██╔══██╗████╗░██║██║░░░██║╚══██╔══╝  ██║
//██║░░██║██║░░██║██╔██╗██║██║░░░██║░░░██║░░░  ██║
//██║░░██║██║░░██║██║╚████║██║░░░██║░░░██║░░░  ╚═╝
//██████╔╝╚█████╔╝██║░╚███║╚██████╔╝░░░██║░░░  ██╗
//╚═════╝░░╚════╝░╚═╝░░╚══╝░╚═════╝░░░░╚═╝░░░  ╚═╝

// wich one do you prefer?
// inspired by Blender Guru: https://www.youtube.com/@blenderguruofficial
// move the mouse to rotate the donut

//////////////
//          //
// SETTINGS //
//          //
//////////////

// donut with ice
//#define FROZEN_DONUT
// just the materials
//#define MATERIAL_PREVIEW

// antialiasing, icrease it if you have a fast computer
#define AA 2
// comment this if you want a concrete donut
#define SUB_SURFACE_SCATTERING
// sharpness of the shadows
#define SHADOW_SHARPNESS 7.
// pi
#define PI 3.141592

//////////////////////
//                  //
// USEFUL FUNCTIONS //
//                  //
//////////////////////

// ray sphere intersection
// tnanks to iq: https://iquilezles.org/articles/intersectors/
vec2 sphIntersect(vec3 ro, vec3 rd, float ra) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - ra*ra;
    float h = b*b - c;
    if(h<0.) return vec2(-1); // no intersection
    h = sqrt(h);
    return vec2(-b-h, -b+h);
}

// rotation function
mat2 rot(float a) {
    float s = sin(a), c = cos(a); // sine and cosine
    return mat2(c, -s, s, c);
}

// generate a random value
float hash(float n) {return fract(sin(n)*43758.5453123);}

// noise function by iq
float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.-2.*f); // S curve

    float n = p.x + p.y*157. + 113.*p.z;

    return mix(mix(mix(hash(n+  0.), hash(n+  1.),f.x),
                   mix(hash(n+157.), hash(n+158.),f.x),f.y),
               mix(mix(hash(n+113.), hash(n+114.),f.x),
                   mix(hash(n+270.), hash(n+271.),f.x),f.y),f.z);
}

// fractal noise
float fbm(vec3 p) {
    float f = 0.;
    f += .5*noise(p);
    f += .25*noise(2.*p);
    f += .125*noise(4.*p);
    return f;
}

// sphere sdf
float sdSphere(vec3 p, float r) {
    return length(p)-r;
}

// torus sdf
float sdTorus(vec3 p, float r1, float r2) {
    vec2 q = vec2(length(p.xz)-r1, p.y);
    return length(q)-r2;
}

// union of two objects
vec2 opU(vec2 a, vec2 b) {
    return a.x<b.x ? a : b;
}

// smooth minimum
// thanks to iq: https://iquilezles.org/articles/smin/
float smin(float a, float b, float k) {
    float h = clamp(.5+.5*(b-a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1.-h);
}

///////////////
//           //
// MODELLING //
//           //
///////////////

// materials idx
#define MAT_DONUT 0.
#define MAT_ICING 1.
#define MAT_SPRINKLES 2.

// polar coorninates
vec3 polarCoords(vec3 p, float an, out float sector) {
    an = 2.*PI/an;
    sector = round(atan(p.z, p.x)/an);
    p.zx *= rot(sector*an);
    return p;
}

// scene
vec2 map(vec3 p) {
    vec2 d = vec2(1e10); // big number
            
    // rotate the point
    p.xz *= rot(.75*PI);
    p.yz *= rot(.3*PI);
    
    // displacement
    float f = sin(20.*p.x)*sin(20.*p.y)*sin(20.*p.z);
    // radius of the torus
    float r = .24-.01*sin(16.*p.y+8.); // this sinus makes the donut less round
    // donut
    d = opU(d, vec2(sdTorus(p, .5, r)-.005*f, MAT_DONUT));
    
    // icing
    float i = sdTorus(p, .5, r+.05)-.0035*f;
    
    // woobles
    float an = atan(p.x,p.z); // horizontal axis of the polar coordinates
    float h = sin(10.*an)*.028;
    h += .009*sin(24.*an+3.);
    h *= dot(p.xz, p.xz); // attenuate the wobbles in the hole of the donut
    i = smin(i, h-p.y, -.06); // cut of the icing
        
    // dripping
    vec3 q = p;
    i = smin(i, sdSphere(q-vec3(.73,-.02,0), .06), .08);
    q.xz *= rot(.9);
    i = smin(i, sdSphere(q-vec3(.72,-.04,0), .06), .08);
    q.xz *= rot(2.5);
    i = smin(i, sdSphere(q-vec3(.73,-.04,0), .06), .08);
        
    d = opU(d, vec2(i,MAT_ICING));
    d.x *= .8; // make the step size smaller
    
    // sprinkles
    float sector;
    q = polarCoords(p, 7., sector);
    float n = 1.+sector*13.; // randoms seed
    float s = sdSphere(q-vec3(.5-.14*hash(n),.3-.02*hash(n+14.),0), .05);
    
    q = polarCoords(p, 5., sector);
    n += sector*25.*5.;
    s = min(s, sdSphere(q-vec3(.5+.13*hash(n),.3-.03*hash(n-8.),0), .05));

    d = opU(d, vec2(s, MAT_SPRINKLES));

    return d;
}

///////////////
//           //
// RENDERING //
//           //
///////////////

// raymarching loop
// return the distance and material idx
vec2 intersect(vec3 ro, vec3 rd, float tmin, float tmax) {
    float t = tmin;
    for (int i=0; i<256 && t<tmax; i++) {
        vec3 p = ro + rd*t; // point
        
        vec2 h = map(p); // distance to the scene and material idx
        if (h.x<.001) return vec2(t,h.y); // we hit the surface!
        t += h.x; // march
    }
    return vec2(-1); // no intersection
}

// normal estimation
vec3 calcNormal(vec3 p) {
    float h = map(p).x;
    const vec2 e = vec2(.0001,0);
    
    return normalize(h - vec3(map(p-e.xyy).x,
                              map(p-e.yxy).x,
                              map(p-e.yyx).x));
}

// soft shadow function
// thanks to iq: https://iquilezles.org/articles/rmshadows/
// k is the softness of the shadow
float shadow(vec3 ro, vec3 rd, float tmax, float k) {
    float res = 1.;
    for (float t=.005; t<tmax;) {
        vec3 p = ro + rd*t;
        
        float h = map(p).x+.004; // offset to see better the sss
        if (h<.001) return 0.;
        res = min(res, k*h/t);
        t += h;
    }
    return res*res*(3.-2.*res); // S curve
}

// ambient occlusion function
// k is the radius of AO
float calcAO(vec3 p, vec3 n, float k) {
    float res = clamp(.5+.5*map(p + n*k).x/k,0.,1.);
    return res*res*(3.-2.*res); // S curve
}

// subsurface scattering function
// thanks to iq: https://www.shadertoy.com/view/llXBWn
// I used his function but I added small modifications
// ra is the radius of the subsurface
// sca is the scattered color under the surface
vec3 calcSSS(vec3 p, vec3 n, vec3 lig, float ra, vec3 sca) {
    float dif = dot(n, lig); // diffuse light
    
    float pdif = clamp(dif,0.,1.); // positive diffuse
    float ndif = clamp(-dif,0.,1.); // negative diffuse
    vec3 sha = vec3(1)*shadow(p, lig, 1., SHADOW_SHARPNESS); // shadow
    sha = pow(sha, 1./sqrt(sca)); // ading sss also on the shadow

    vec3 col = vec3(0);
    col += pdif*sha; // diffuse light
    // aproximation of the scattered light under the surface
    col += sha*.2*sca*ra*(1.-ndif)*(1.-ndif)*pow(1.-ndif,3./ra);
        
    return col;
}

// rendering function
vec3 render(vec3 ro, vec3 rd, vec2 uv) {
    // transition
    float tr = step(.5,fract((uv.x+uv.y+.05*sin(26.*uv.x))*.1+.1*time));
    
    // background
    float stripes = step(0., sin(10.*uv.y+sin(10.*uv.x)+time));
    vec3 pink = mix(vec3(1,.23,.52), vec3(1,.36,.7), stripes);
    vec3 brown = vec3(.022,.014,.011)*(.5+.5*stripes);
    vec3 col = mix(pink, brown, tr);
        
    // light direction
    vec3 lig = normalize(vec3(-2,2,-2));
    
    // bounding volume
    vec2 bound = sphIntersect(ro, rd, .81);
    vec2 tm = vec2(-1);
    if (bound.x>0.) { // we hit the sphere
        tm = intersect(ro, rd, bound.x, bound.y); // distance and material idx
    }
    float t = tm.x;
        
    if (t>0.) { // we hit the surface!
    
        // lighting and coloring
        
        vec3 p = ro + rd*t; // hit point
        vec3 n = calcNormal(p); // surface normal
        vec3 r = reflect(rd, n); // reflected vector
        
        // ambient occlusion
        float occ = 1.;
        for (int i=0; i<4; i++) {
            occ *= calcAO(p, n, float(i+1)*.03);
        }
        occ *= calcAO(p, n, .5);
        
        float dif = clamp(dot(n, lig), 0., 1.); // diffuse light
        float sha = shadow(p, lig, 1., 8.); // soft shadow
        float spe = clamp(dot(r, lig), 0., 1.); // specular light
        float fre = 1.+dot(rd, n); // fresnel
             
        vec3 mat, sca, sss; // material sss scatter and sss (diffuse+shadow+sss)
        col = vec3(0);
        // some very ugly code, i'm to lazy to make it better
        if (tm.y == MAT_DONUT) { // donut
            mat = vec3(1,.55,.3);
            sca = mat;
            sss = calcSSS(p, n, lig, .5, sca);
            fre = .1*pow(fre,1.5);
            spe = 0.;
        } else if (tm.y == MAT_ICING) { // icing
            mat = mix(vec3(1,.3,.8), vec3(1,.72,.55), tr);
            sca = mat*mix(vec3(1,.8,.3), vec3(1,.55,.55), tr);
            sss = calcSSS(p, n, lig, .4, sca);
            
            fre = .4*pow(fre,2.);
            spe = 1.5*pow(spe, 48.*fbm(32.*p));
            
            vec3 bou = mat;
            #ifdef SUB_SURFACE_SCATTERING
            bou *= sca;
            #endif
            col += .35*occ*bou*(1.-calcAO(p, n, .8)); // fake global illumination
        } else if (tm.y == MAT_SPRINKLES) { // sprinkles
            if (p.z>.48)      mat = vec3(.3,.7,1);
            else if (p.z>.2)  mat = vec3(.6,.2,1);
            else if (p.x<-.4) mat = vec3(1,.5,.7);
            else              mat = vec3(1,.7,.4);
            mat = mix(mat, .65*vec3(.9,.35,.15), tr);
            
            sca = mat*mat;
            sss = calcSSS(p, n, lig, .3, sca);
            fre = .3*pow(fre,3.);
            spe = 2.*pow(spe, 32.);
        }
        
        #ifdef SUB_SURFACE_SCATTERING
        col += sss; // base layer
        col += sca*occ*fre; // sss on raising angles
        #else
        col += dif*sha; // base layer
        #endif
        col += .08*occ; // ambient light
        col += sss*spe; // specular
        
        col *= mat; // coloring
        
        // blue rimlight only on the white donut
        vec3 bac = lig*vec3(-1,-1,1);
        dif = clamp(dot(n,bac),0.,1.);
        fre = 1.+dot(rd, n);
        col += 2.*tr*vec3(.1,.4,1)*occ*pow(fre,4.)*dif*clamp(.2+.8*dot(rd, bac), 0., 1.);
        
        // cheap ice effect
        #ifdef FROZEN_DONUT
        col += occ*.7*vec3(.3,.7,1)*pow(fre, 3.*pow(fbm(8.*p),.5));
        #endif
        #ifdef MATERIAL_PREVIEW
        col = mat*occ*(.5+.5*n.y);
        #endif
    }
        
    return col;
}

// camera function
mat3 setCamera(vec3 ro, vec3 ta) {
    vec3 w = normalize(ta - ro);
    vec3 u = normalize(cross(w, vec3(0,1,0)));
    vec3 v = cross(u, w);
    return mat3(u, v, w);
}

void main(void)
{
    // music frequency
    float freq = 0; //texture(iChannel0, vec2(0,.1)).r;
    
    vec3 tot = vec3(0); // accumulated color
    for (int m=0; m<AA; m++)
    for (int n=0; n<AA; n++) {
        vec2 off = vec2(m,n)/float(AA)-.5; // antialiasing offset
        // pixel coordinates centered at the origin
        vec2 p = (gl_FragCoord.xy+off - .5*resolution.xy)/resolution.y;
        p *= 1.1-.2*freq; // music bounce
        
        // normalized mouse coordinates
        vec2 mo = mouse*resolution.xy.xy/resolution.xy;
        // normalized pixel coordinates
        vec2 q = (gl_FragCoord.xy+off)/resolution.xy;

        // time value
        float time = .5*time + mo.x*PI*2.;
                                
        vec3 ro = vec3(0,0,3); // ray origin
        ro.xz *= rot(time); // rotate the camera
        vec3 ta = vec3(0); // target
        mat3 ca = setCamera(ro, ta); // camera matrix
    
        vec3 rd = ca * normalize(vec3(p,1.5)); // ray direction
    
        vec3 col = render(ro, rd, q);
        tot += col;
    }
    tot /= float(AA*AA);
    
    tot = 2.*tot/(1.+tot); // tonemapping
    tot = pow(tot, vec3(.4545)); // gamma correction
                    
    // vignette
    vec2 q = gl_FragCoord.xy/resolution.xy;
    tot *= .5+.5*pow(24. * q.x*q.y*(1.-q.x)*(1.-q.y), .1);
    // dithering
    tot += hash(gl_FragCoord.xy.x+13.*gl_FragCoord.xy.y)/255.;
                
    glFragColor = vec4(tot,1.0);
}
