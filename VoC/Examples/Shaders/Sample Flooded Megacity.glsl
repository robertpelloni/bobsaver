#version 420

// original https://www.shadertoy.com/view/wllczN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FDIST 0.5

#define CELL_SIZE 3.
#define MINI_CELL_SIZE .15
#define WINDOW_SIZE vec3(0.5, 0.5, 0.45)
#define WINDOW_STRIDE 1.
#define WINDOW_THICKNESS 0.05
#define ROOM_DEPTH 10.
#define MAX_VOXELS 200
#define REFLECTION_VOXELS 20
#define REFRACTION_VOXELS 10
#define MAX_HEIGHT 40.
#define SHADOW_STEPS 10
#define EPS 0.005
#define SHADOW_EPS 0.01
#define WATER_HEIGHT -2.
#define IOR 1.33
#define GLASS_IOR 5.
#define ABSORPTION_RATE vec3(0.7, 0.8, 0.9)

#define WATER_MAT 6

#define MOON_COL vec3(0.4, 0.4, 0.4)
#define MOON_RADIUS 0.11
#define AMBIENT_COL vec3(0.1, 0.1, 0.15)

#define SILL_COLOR vec3(1., 0.9, 0.9)

#define PI 3.141593

struct Hit {
    float t;
    int mat;
    vec3 n;
    vec3 id;
};

float hash( in vec3 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Value3D.glsl

    // establish our grid cell and unit position
    vec3 Pi = floor(P);
    vec3 Pf = P - Pi;
    vec3 Pf_min1 = Pf - 1.0;

    // clamp the domain
    Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
    vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

    // calculate the hash
    vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    vec2 hash_mod = vec2( 1.0 / ( 635.298681 + vec2( Pi.z, Pi_inc1.z ) * 48.500388 ) );
    vec4 hash_lowz = fract( Pt * hash_mod.xxxx );
    vec4 hash_highz = fract( Pt * hash_mod.yyyy );

    //    blend the results and return
    vec3 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
    vec4 res0 = mix( hash_lowz, hash_highz, blend.z );
    vec4 blend2 = vec4( blend.xy, vec2( 1.0 - blend.xy ) );
    return dot( res0, blend2.zxzx * blend2.wwyy );
}

vec3 tex(in vec3 p) {
    float fac = 0.5*(hash(p)+hash(p*2.5));
    float fac2 = smoothstep(0.45, 0.65, fac);
    return mix(vec3(0.9, 0.8, 0.8), vec3(0.8, 0.7, 0.6), fac2);
}

vec3 ramp(in float t) {
    return abs(fract(t + vec3(3,2,1)/3.)*6. - 3.) - 1.;
}

float buildings(in vec3 ro) {
    return -ro.z/2. + 5.*sin(ro.x/2.) * sin(ro.y/2.);
}

float holes(in vec3 id) {
    id = mod(id+5., 10.)-5.;
    return step(10., dot(id, id));
}

float cylinders(in vec3 id) {
    id.xy = mod(id.xy+22.5, 45.)-22.5;
    float density = step(abs(length(id.xy)-5.), 1.);
    density = min(density, step(4., length(id.xz-vec2(0., 2.))));
    return density;
}

float voxMap(in vec3 id) {
    float build1 = min(max(buildings(id), buildings(id*0.25)) + 2.*(hash(id)-0.5), holes(id));
    float build2 = cylinders(id);
    return max(build1, build2);
}

float occupancy(in vec3 id) {
    //return step(0.5, -step(length(id.xz - vec2(0., 4.)), 2.5) + voxMap(id/10.) + 0.25*(voxMap(id)-0.5));
    return step(0.5, voxMap(id));
}

vec3 cellID(in vec3 ro) {
    return floor(ro/(2.*CELL_SIZE) + 0.5);
}

vec3 cellMod(in vec3 ro) {
    return mod(ro + CELL_SIZE, CELL_SIZE*2.) - CELL_SIZE;
}

float traceCell(in vec3 ro, in vec3 rd) {
    vec3 dr = 1.0/rd;
    vec3 n = ro * dr;
    vec3 k = CELL_SIZE * abs(dr);
    
    vec3 pout =  k - n;
    return min(pout.x, min(pout.y, pout.z));
}

float traceCell_normal(in vec3 ro, in vec3 rd, in vec3 r, out vec3 nn) {
    vec3 dr = 1.0/rd;
    vec3 n = ro * dr;
    vec3 k = r * abs(dr);
    
    vec3 pout =  k - n;
    nn = -sign(rd) * step(pout.xyz, pout.zxy) * step(pout.xyz, pout.yzx);
    return min(pout.x, min(pout.y, pout.z));
}

float skinnyBox(in vec3 modpos, in vec3 rd, in vec3 id, out vec3 pnear, out vec3 pfar) {
    vec2 offset = vec2(1., 0.);
    vec3 occp = vec3(
        occupancy(id + offset.xyy),
        occupancy(id + offset.yxy),
        occupancy(id + offset.yyx)
    );
    vec3 occm = vec3(
        occupancy(id - offset.xyy),
        occupancy(id - offset.yxy),
        occupancy(id - offset.yyx)
    );
    vec3 sig = step(-0.5, sign(rd));
    vec3 sizesp = mix(vec3(MINI_CELL_SIZE), vec3(CELL_SIZE), occp);
    vec3 sizesm = -mix(vec3(MINI_CELL_SIZE), vec3(CELL_SIZE), occm);
    pnear = (mix(sizesp, sizesm, sig) - modpos)/rd;
    pfar = (mix(sizesm, sizesp, sig) - modpos)/rd;
    /*vec3 ts[2];
    ivec3 index = ivec3(step(-0.5, sig));
    ts[index.x].x = (mix(MINI_CELL_SIZE, CELL_SIZE, occp.x) - modpos.x)/rd.x;
    ts[index.y].y = (mix(MINI_CELL_SIZE, CELL_SIZE, occp.y) - modpos.y)/rd.y;
    ts[index.z].z = (mix(MINI_CELL_SIZE, CELL_SIZE, occp.z) - modpos.z)/rd.z;
    ts[1-index.x].x = (-mix(MINI_CELL_SIZE, CELL_SIZE, occm.x) - modpos.x)/rd.x;
    ts[1-index.y].y = (-mix(MINI_CELL_SIZE, CELL_SIZE, occm.y) - modpos.y)/rd.y;
    ts[1-index.z].z = (-mix(MINI_CELL_SIZE, CELL_SIZE, occm.z) - modpos.z)/rd.z;
    pnear = ts[0];
    pfar = ts[1];*/
    return occp.x + occp.y + occp.z + occm.x + occm.y + occm.z;
}

Hit voxtrace(in vec3 ro, in vec3 rd, int iters, bool stopWater) {
    Hit h;
    h.t = 0.;
    // box marching
    for (int i=0; i<iters; i++) {
        vec3 pos = ro + rd*h.t;
        h.id = cellID(pos);
        if (stopWater && h.id.z < WATER_HEIGHT) {
            h.mat = WATER_MAT;
            return h;
        } else if (h.id.z > MAX_HEIGHT) {
            return h;
        }
        vec3 modpos = cellMod(pos);
        float maxdist = traceCell(modpos, rd);
        
        
        if (occupancy(h.id) > 0.5) {
            vec3 pnear, pfar;
            float neighbors = skinnyBox(modpos, rd, h.id, pnear, pfar);
            float tnear = max(pnear.x, max(pnear.y, pnear.z));
            float tfar = min(pfar.x, min(pfar.y, pfar.z));
            if (neighbors > 0.5 && tfar > tnear && tnear > -2.*EPS) {
                if (h.id.z >= WATER_HEIGHT) {
                    if (neighbors < 2.5) {
                        h.mat = 3;
                    } else if (neighbors < 4.5) {
                        h.mat = 1;
                    } else {
                        h.mat = 2;
                    }
                } else {
                    h.mat = 5;
                }
                h.t += tnear;
                h.n = -sign(rd) * step(pnear.zxy, pnear.xyz) * step(pnear.yzx, pnear.xyz);
                return h;
            }
        }
        
        h.t += maxdist + EPS;
        
    }
     
    h.mat = 0;
    return h;
}

/*float shadowtrace(in vec3 ro, in vec3 rd) {
    float t = 0.;
    for (int i=0; i<SHADOW_STEPS; i++) {
        vec3 pos = ro + rd*t;
        vec3 id = cellID(pos);
        vec3 modpos = cellMod(pos);
        float maxdist = traceCell(modpos, rd);
        
        if (occupancy(id) > 0.5) {
            vec3 pnear, pfar;
            skinnyBox(modpos, rd, id, pnear, pfar);
            float tnear = max(pnear.x, max(pnear.y, pnear.z));
            float tfar = min(pfar.x, min(pfar.y, pfar.z));
            if (tfar > tnear && tnear > -SHADOW_EPS) {
                return 0.;
            }
        }
        t += maxdist + EPS;
    }
    return 1.;
}*/

// Schlick approximation for the Fresnel factor
float schlick_fresnel(float R0, float cos_ang) {
    return R0 + (1.-R0) * pow(1.-cos_ang, 5.);
}

vec3 shade(in vec3 eye, in vec3 rd, in Hit h, in vec3 sundir) {
    vec3 ro = eye + h.t * rd;
    if (h.mat == 0) {
        // sky color
        vec3 sky = mix(vec3(0.), vec3(0.1, 0.05, 0.0), 1.-pow(max(0., rd.z), .5));
        float c = max(0., dot(rd, sundir));
        float s = sqrt(1.-c*c);
        vec2 n = normalize(vec2(s, sqrt(MOON_RADIUS*MOON_RADIUS-s*s)));
        float fac = max(0.,1.-0.5*(1.-n.y));
        sky = mix(fac * vec3(0.9, 0.95, 1.), sky, smoothstep(MOON_RADIUS-0.01, MOON_RADIUS, s));
        return sky;
    } else if (h.mat == 1 || h.mat == 3 || h.mat == 4 || h.mat == 5) {
        // buildings
        
        float fac = max(0., dot(h.n, sundir));
        //fac *= shadowtrace(ro + SHADOW_EPS*sundir, sundir);
        float fac2 = abs(dot(h.n, -sundir));
        vec3 albedo;
        if (h.mat == 1) albedo = tex(ro);
        else if (h.mat == 3) {
            vec3 absmod = abs(cellMod(ro));
            float coord = max(absmod.x, max(absmod.y, absmod.z))*1.253;
            float stripe = smoothstep(0.45, 0.55, 2.*abs(fract(coord)-0.5) + 0.5*(hash(ro*2.)-0.5));
            albedo = mix(1.-tex(ro), 0.5*tex(ro*2.), stripe);
        }
        else if (h.mat == 4) albedo = SILL_COLOR;
        else if (h.mat == 5) albedo = vec3(1.); //underwater
        return albedo * (MOON_COL * fac + AMBIENT_COL * fac2);
    } else return vec3(1., 0., 1.);
}

vec3 winmod(in vec3 ro) {
    return (fract(ro/(WINDOW_STRIDE*2.)+0.5)-0.5)*2.*WINDOW_STRIDE;
}

vec3 winID(in vec3 ro) {
    return floor(ro/(WINDOW_STRIDE*2.)+0.5);
}

float win_mask(in vec3 ro, in vec3 n, float margin) {
    vec3 win = step(1.-(WINDOW_SIZE + margin)/WINDOW_STRIDE, abs(fract(ro/(WINDOW_STRIDE*2.))-0.5)*2.);
    return win.x * win.y * win.z * step(abs(n.z), 0.2) * step(WATER_HEIGHT * CELL_SIZE*2., ro.z);
}

vec3 shade_interior(in vec3 eye, in vec3 rd, in vec3 id, in vec3 sundir) {
    vec3 n;
    float t = traceCell_normal(eye, rd, vec3(WINDOW_THICKNESS,WINDOW_SIZE.y, WINDOW_SIZE.z), n);
    vec3 albedo;
    vec3 ro = eye + rd * t;
    if (n.x > 0.5) {
        t = traceCell_normal(eye, rd, vec3(ROOM_DEPTH, WINDOW_STRIDE, WINDOW_STRIDE), n);
        ro = eye + rd * t;
        float hass = hash(id);
        vec3 tilecolor = 0.8 + 0.2 * (ramp(hass)-0.5);
        float ang = hass * PI * .5;
        float sr = sin(ang);
        float cr = cos(ang);
        mat2 rot = mat2(cr, -sr, sr, cr);
        vec2 tile = step(mod(rot*ro.xy, hass), vec2(0.5*(1.-hass)));
        float tilefac = abs(tile.x-tile.y);
        vec3 floorcol = mix(vec3(0.5+0.5*fract(hass*145.7)), tilecolor, tilefac);
        vec3 wallcol = 0.95+0.05*(ramp(1.-hass)-0.5);
        albedo = mix(wallcol, floorcol, step(0.1, n.z));
    } else {
        albedo = SILL_COLOR;
    }
    vec3 lightpos = vec3(-0.25*ROOM_DEPTH, 0., WINDOW_STRIDE*0.95);
    vec3 l = lightpos - ro;
    float ll = length(l);
    float fac = max(0.25, dot(n, l)/(ll*ll));
    
    return albedo * fac * 3. * hash(id);
}

vec3 shade_fake(in vec3 eye, in vec3 rd, in Hit h, in vec3 sundir) {
    vec3 ro = eye + rd * h.t;
    if (h.mat == 2) {
        // add in fake windows without reflections
        if (win_mask(ro, h.n, 0.) > 0.5) {
            vec3 id = winID(ro);
            vec3 row = winmod(ro);
            mat2 rot = mat2(h.n.x, -h.n.y, h.n.y, h.n.x);
            vec3 ro2 = vec3(rot * row.xy, row.z);
            vec3 rd2 = vec3(rot * rd.xy, rd.z);
            sundir = vec3(rot * sundir.xy, sundir.z);
            return shade_interior(ro2, rd2, id, sundir);
        } else if (win_mask(ro, h.n, 0.2) > 0.5) {
            h.mat = 4;
            return shade(eye, rd, h, sundir);
        } else {
            h.mat = 1;
            return shade(eye, rd, h, sundir);
        }
    } else if (h.mat == WATER_MAT) {
        // water refractions
        vec3 rdr = refract(rd, h.n, 1./1.33);
        Hit h3 = voxtrace(ro, rdr, REFRACTION_VOXELS, false);
        vec3 refrcol = shade(ro, rdr, h3, sundir);
        refrcol *= pow(ABSORPTION_RATE, vec3(h3.t));
        return refrcol;
    } else {
        return shade(eye, rd, h, sundir);
    }
}

// shade materials which require reflections
vec3 shade_refl(in vec3 eye, in vec3 rd, in Hit h, in vec3 sundir) {
    vec3 ro = eye + h.t * rd;
    if (h.mat == 2) {
        // windows
        vec3 basecolor = shade_fake(eye, rd, h, sundir);
        if (win_mask(ro, h.n, 0.) > 0.5) {
            vec3 rdr = reflect(rd, h.n);
            Hit h2 = voxtrace(ro, rdr, REFLECTION_VOXELS, true);
            vec3 reflcol = shade_fake(ro, rdr, h2, sundir);
            float R0 = (GLASS_IOR-1.)/(GLASS_IOR+1.);
            float fresnel = schlick_fresnel(R0, dot(h.n, rdr));
            return mix(basecolor, reflcol, fresnel);
        } else {
            return basecolor;
        }
    } else if (h.mat == WATER_MAT) {
        float R0 = (IOR-1.)/(IOR+1.);
        R0*=R0;
        float fresnel = schlick_fresnel(R0, -rd.z);
        
        vec2 disp = 0.01 * vec2(cos(ro.x*0.5 + 0.25*ro.y + 10.*time), sin(ro.x +2.*ro.y));
        vec3 wn = normalize(vec3(disp, 1.));
        h.n = wn;
        vec3 refrcol = shade_fake(eye, rd, h, sundir);
        
         // water reflections
         
        vec3 rdr = reflect(rd, wn);
        Hit h2 = voxtrace(ro, rdr, REFLECTION_VOXELS, false);
        vec3 reflcol = shade_fake(ro, rdr, h2, sundir);
        
        return mix(refrcol, reflcol, fresnel);
    } else {
        return shade_fake(eye, rd, h, sundir);
    }
}

void main(void)
{
    float mouseY = 0.;
    float mouseX = time*0.25;
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.x;
    vec3 eye = vec3(0., time * 30., 20.1);
    vec3 w = vec3(cos(mouseX) * cos(mouseY), sin(mouseX) * cos(mouseY), -sin(mouseY));
    vec3 u = normalize(cross(w, vec3(0., 0., 1.)));
    vec3 v = cross(u, w);
    vec3 rd = normalize(FDIST*w + uv.x*u + uv.y*v);
    
    Hit h = voxtrace(eye, rd, MAX_VOXELS, true);
    vec3 ro = eye + h.t * rd;
    vec3 sundir = normalize(vec3(1., -2., 1.2));

    vec3 col = shade_refl(eye, rd, h, sundir);
    glFragColor = vec4(pow(col, vec3(0.75)),1.0);
}
