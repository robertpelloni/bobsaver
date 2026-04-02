#version 420

// original https://www.shadertoy.com/view/fdsyWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Directional Lights" by Claus O. Wilke
// Jan. 20, 2022
// Published under MIT License

// Includes various code snippets from Inigo Quilez, licensed under MIT, https://iquilezles.org/www/index.htm
// Also includes code by Martijn Steinrucken, licensed under MIT, https://www.shadertoy.com/view/WtGXDD

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

mat2 rotMatrix(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// smooth minimum
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
    return mix(a, b, h) - k*h*(1.0-h);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdFloor(vec3 p) {
    return p.y + 0.4;
}

float getDist(vec3 p) {
    float d = sdFloor(p);
    
    float dspheres = smin(
        sdSphere(p - vec3(0, 1.5, .4), 1.0 + .3*sin(time)),
        smin(
            sdSphere(p - vec3(-.8, 1, 0), .8 + .2*sin(3.*time+2.)),
            sdSphere(p - vec3(.3, .5*cos(time/.8)+.7, .7*cos(time/.8)), 1.1),
            0.1
        ),
        0.1
    );
    
    return min(d, dspheres);
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow(in vec3 ro, in vec3 rd, in float mint, in float tmax)
{
    float t = mint;
    float k = 20.;  // "softness" of shadow. smaller numbers = softer

    // unroll first loop iteration
    float h = getDist(ro + rd*t);
    float res = min(1., k*h/t);
    t += h;
    float ph = h; // previous h
    
    for( int i=1; i<60; i++ )
    {
        if( res<0.01 || t>tmax ) break;        

        h = getDist(ro + rd*t);
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min(res, k*d/max(0.0, t-y));
        ph = h;
        t += h;
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);  // smoothstep, smoothly transition from 0 to 1
}

// from https://www.shadertoy.com/view/wlXSD7
float calcOcclusion(in vec3 pos, in vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hrconst = 0.03; // larger values create more occlusion
        float hr = hrconst + 0.15*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = getDist( aopos );
        occ += (hr-dd)*sca;
        sca *= 0.95;
    }
    return clamp(1.0 - occ*1.5, 0.0, 1.0);
}

float rayMarch(vec3 ro, vec3 rd) {
    float dO = 0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = getDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 getNormal(vec3 p) {
    float d = getDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        getDist(p-e.xyy),
        getDist(p-e.yxy),
        getDist(p-e.yyx));
    
    return normalize(n);
}

// Camera system explained here:
// https://www.youtube.com/watch?v=PBxuVlp7nuM
vec3 getRayDir(vec2 uv, vec3 ro, vec3 lookat, float zoom) {
    vec3 forward = normalize(lookat-ro),
        right = normalize(cross(forward, vec3(0, 1., 0))),
        up = cross(right, forward),
        center = forward*zoom,
        intersection = center + uv.x*right + uv.y*up,
        d = normalize(intersection);
    return d;
}

// cut1 and cut2 define the center cone and the max width of the light
// they are cosines of the corresponding angles, so a center cone of
// 15 degrees and a max width of 30 degrees would correspond to
// cut1 = 0.9659258 and cut2 = 0.8660254
// lr is the normalized light ray
float calcDirLight(in vec3 p, in vec3 lookfrom, in vec3 lookat,
                           in float cut1, in float cut2, out vec3 lr) {
    lr = normalize(lookfrom - p);
    float intensity = dot(lr, normalize(lookfrom - lookat));
    return smoothstep(cut2, cut1, intensity);
}

vec3 renderLight1(in vec3 p, in vec3 n, in vec3 rdref, in float ao, in vec3 material) {
    // Phong shading
    // https://en.wikipedia.org/wiki/Phong_reflection_model
    float ks = 0.6, // specular reflection constant
        kd = 0.4,   // diffuse
        ka = 0.2;   // ambient
    
    vec3 col_light = vec3(.8, .001, .8),
        is = 6.*col_light,  // specular light intensity
        id = 2.*col_light,  // diffuse
        ia = 1.*col_light;  // ambient
        
    vec3 pl = vec3(5.*cos(-time), 4, 5.*sin(-time)); // light position
    vec3 plat = vec3(0.5, 0, 0); // light direction

    float alpha_p = 20.; // Phong alpha exponent

    vec3 lr = vec3(0); // light ray to point p, will be assigned
                       // by calcDirLight()
    float light = calcDirLight(p, pl, plat, 0.96, 0.86, lr);
    vec3 lrref = reflect(lr, n); // reflected light ray

    float shadow = 1.;
    if (light > 0.001) { // no need to calculate shadow if we're in the dark
        shadow = calcSoftshadow(p, lr, 0.01, 20.0);
    }
    vec3 dif = light*kd*id*max(dot(lr, n), 0.)*shadow;
    vec3 spec = light*ks*is*pow(max(dot(lr, rdref), 0.), alpha_p)*shadow;
    vec3 amb = light*ka*ia*ao;

    return material*(amb + dif + spec);
}

vec3 renderLight2(in vec3 p, in vec3 n, in vec3 rdref, in float ao, in vec3 material) {
    // Phong shading
    // https://en.wikipedia.org/wiki/Phong_reflection_model
    float ks = 0.6, // specular reflection constant
        kd = 0.4,   // diffuse
        ka = 0.2;   // ambient
    
    vec3 col_light = vec3(.8, .8, .001),
        is = 6.*col_light,  // specular light intensity
        id = 2.*col_light,  // diffuse
        ia = 1.*col_light;  // ambient
        
    vec3 pl = vec3(5.*cos(time + 2.09), 4, 5.*sin(time + 2.09)); // light position
    vec3 plat = vec3(0, 0, 0.5); // light direction

    float alpha_p = 20.; // Phong alpha exponent

    vec3 lr = vec3(0); // light ray to point p, will be assigned
                       // by calcDirLight()
    float light = calcDirLight(p, pl, plat, 0.96, 0.86, lr);
    vec3 lrref = reflect(lr, n); // reflected light ray

    float shadow = 1.;
    if (light > 0.001) { // no need to calculate shadow if we're in the dark
        shadow = calcSoftshadow(p, lr, 0.01, 20.0);
    }
    vec3 dif = light*kd*id*max(dot(lr, n), 0.)*shadow;
    vec3 spec = light*ks*is*pow(max(dot(lr, rdref), 0.), alpha_p)*shadow;
    vec3 amb = light*ka*ia*ao;

    return material*(amb + dif + spec);
}

vec3 renderLight3(in vec3 p, in vec3 n, in vec3 rdref, in float ao, in vec3 material) {
    // Phong shading
    // https://en.wikipedia.org/wiki/Phong_reflection_model
    float ks = 0.6, // specular reflection constant
        kd = 0.4,   // diffuse
        ka = 0.2;   // ambient
    
    vec3 col_light = vec3(.001, .8, .8),
        is = 6.*col_light,  // specular light intensity
        id = 2.*col_light,  // diffuse
        ia = 1.*col_light;  // ambient
        
    vec3 pl = vec3(5.*cos(2.*time + 4.19), 4, 5.*sin(2.*time + 4.19)); // light position
    vec3 plat = vec3(0.5, 0, 0.5); // light direction

    float alpha_p = 20.; // Phong alpha exponent

    vec3 lr = vec3(0); // light ray to point p, will be assigned
                       // by calcDirLight()
    float light = calcDirLight(p, pl, plat, 0.96, 0.86, lr);
    vec3 lrref = reflect(lr, n); // reflected light ray

    float shadow = 1.;
    if (light > 0.001) { // no need to calculate shadow if we're in the dark
        shadow = calcSoftshadow(p, lr, 0.01, 20.0);
    }
    vec3 dif = light*kd*id*max(dot(lr, n), 0.)*shadow;
    vec3 spec = light*ks*is*pow(max(dot(lr, rdref), 0.), alpha_p)*shadow;
    vec3 amb = light*ka*ia*ao;

    return material*(amb + dif + spec);
}

vec3 render(vec3 ro, vec3 rd) {
    vec3 col = vec3(0);
   
    float d = rayMarch(ro, rd);
    
    if (d<MAX_DIST) {
        vec3 p = ro + rd * d,   // point on 3D surface
            n = getNormal(p),   // surface normal
            rdref = reflect(rd, n); // reflected ray
            
        float ao = calcOcclusion(p, n);

        vec3 material = vec3(1., 1., 1.); // material color
        col += renderLight1(p, n, rdref, ao, material);
        col += renderLight2(p, n, rdref, ao, material);
        col += renderLight3(p, n, rdref, ao, material);
        col += vec3(0.01)*ao; // just a touch of ambient light throughout
    }
    return clamp(col, 0., 1.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    vec3 ro = vec3(0, 4, 8);
    ro.yz *= rotMatrix((m.y-.5)*3.14);
    ro.xz *= rotMatrix((m.x-.5)*2.*3.14);
    
    vec3 rd = getRayDir(uv, ro, vec3(0., 1., 0.), .9);
    
    vec3 col = render(ro, rd);
    
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
