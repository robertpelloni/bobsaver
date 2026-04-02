#version 420

// original https://www.shadertoy.com/view/wsyXzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 suncol = vec3(1., 1., 1.);

vec3 hadamard (vec3 a, vec3 b) {
    return vec3(a.x*b.x, a.y*b.y, a.z*b.z);
}

float SDFplane (vec3 p) {
    return p.y+2.;
}

float SDFsphere (vec3 p) {
    float PH = 6.;
    p = vec3(mod(p.x, 10.)-5., p.y, mod(p.z, PH*2.)-PH);
    float SDFp = length(p)-2.;
    return SDFp;
}

float SDF (vec3 p) {
    float SDFp = 1e20;
    SDFp = min(SDFp, SDFplane(p));
    SDFp = min(SDFp, SDFsphere(p));
    return SDFp;
}

vec3 dSDF (vec3 p) {
    float SDFp = SDF(p);
    return normalize(
        vec3(
            SDF(vec3(p.x+1e-4, p.y, p.z))-SDFp,
            SDF(vec3(p.x, p.y+1e-4, p.z))-SDFp,
            SDF(vec3(p.x, p.y, p.z+1e-4))-SDFp
        )
    );
}

float idSDF (vec3 p) {
    float SDFspherep = SDFsphere(p);
    float SDFplanep = SDFplane(p);
    if (SDFspherep < SDFplanep) {
        return 1.;
    }
    return 0.;
}

float rxindex (vec3 p) {
    float idSDFp = idSDF(p);
    if (idSDFp == 0.) {
        return .5+.5*sin((p.x+p.z)*3.141592/6.);
    }
    if (idSDFp == 1.) {
        return .3;
    }
}

vec3 sund () {
    return normalize(vec3(cos(time), 1., sin(time) ));
}

vec3 TEX (vec3 p, vec3 d) {
    vec3 col = vec3(1., 0., 0.);
    vec3 dSDFp = dSDF(p);
    float idSDFp = idSDF(p);
    float czk = mod(floor(p.x)+floor(p.y)+floor(p.z), 2.);
    if (idSDFp == 0.) {
        col = vec3(0., .7, .7)*czk;
    }
    if (idSDFp == 1.) {
        col = vec3(0., .7, .7)*czk;
    }
    vec3 lighting = vec3(1., 1., 1.);
    // diffuse lighting
    float ang = clamp(dot(sund(), dSDFp)/2.+1., 0., 1.);
    ang = (dot(sund(), dSDFp)+1.)/2.;
    // ang = clamp(dot(sund(), dSDFp), 0., 1.);
       lighting = lighting*ang;
    // ambient lighting
    lighting = .3+lighting*.7;
    // u cant have red light from a blue sun
    col = hadamard(col, hadamard(lighting, suncol));
    return col;
}

vec3 bg (vec3 d) {
    vec3 col = vec3(0., 0., 100./255.);
    col += suncol*pow( clamp(dot(sund(), d), 0., 1.),40. );
    col = clamp(col, 0., 1.);
    return col;
}

vec3 march (vec3 p, vec3 d) {
    float rxcount = 0.;
    float shiny = 1.;
    vec3 finalcol = vec3(0., 0., 0.);
    for (int i=0; i<100; ++i) {
        float SDFp = SDF(p);
        if (SDFp < 1e-3) {
            p = p+d*SDFp*.995;
            vec3 TEXpd = TEX(p, d);
            float rxindexp = rxindex(p);
            if (rxindexp == 0. || rxcount > 4.) {
                // hits solid object, final color determined
                finalcol = finalcol+TEXpd*shiny*(1.-rxindexp);
                return finalcol;
            }
            if (rxcount > 3.) {
                // waaaay to many reflections reflect background col
                break;
            }
            finalcol = finalcol+TEXpd*shiny*(1.-rxindexp);
            shiny = shiny*rxindexp;
            d = reflect(d, dSDF(p));
            p = p+d*.02;
            ++rxcount;
        }
        float DE = SDFp;
        if (0. < DE && DE < 50.) {
            DE *= .7;
        }
        p = p+d*DE;
    }
    // diverges waaaay out into the sky. reflect sky color
    if (rxcount > 0.) {
        return finalcol+bg(d)*shiny;
    }
    return bg(d);
}

void main(void) {
    vec2 maus;
    maus.x = resolution.x/2.;
    maus.y = resolution.y/2.;
    vec2 screen = (gl_FragCoord.xy*2.-resolution.xy)/resolution.x;
    vec3 dir1 = vec3(screen.x, screen.y, 1.);
    dir1 = normalize(dir1);
    float dir1zytheta = atan(dir1.z, dir1.y);
    float dir1zyr = sqrt(dir1.z*dir1.z+dir1.y*dir1.y);
    float dir2phi = dir1zytheta+clamp((maus.y-resolution.y/2.)/resolution.x*10.+0., -3.14/4., 3.14/2.);
    dir1.y = dir1zyr*cos(dir2phi);
    dir1.z = dir1zyr*sin(dir2phi);
    float dir1zxtheta = atan(dir1.z, dir1.x);
    float dir1zxr = sqrt(dir1.z*dir1.z+dir1.x*dir1.x);
    float dir2theta = dir1zxtheta+(maus.x-resolution.x/2.)/resolution.x*10./2.*2.;
    dir1.x = dir1zxr*cos(dir2theta);
    dir1.z = dir1zxr*sin(dir2theta);
    float PI = 3.141592;
    vec3 retina = march(vec3(cos(time/4.*3.141592*2./2.)*3.-5., 0., -7.+mod(time, 4.)/4.*2.*6.), dir1);
    glFragColor = vec4(retina, 1.);
}
