#version 420

// original https://www.shadertoy.com/view/WsVfDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*Ethan Alexander Shulman 2020 - xaloez.com
4k 60fps video https://www.youtube.com/watch?v=iKuZ95FoQc4
4k wallpaper xaloez.com/art/2020/Devious2.jpg*/

#define EPS 3e-3
#define PI 3.14159265

mat2 r2(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

vec4 r4(float n) {
    #define R4P 1.1673039782614187
    return fract(.5+vec4(1./R4P,1./R4P/R4P,1./R4P/R4P/R4P,1./R4P/R4P/R4P/R4P)*n);
}
vec4 hash(vec4 a) {
    a = mod(abs(a),8273.97234);
    #define R4S(sw) floor(fract(.352347+dot(a,vec4(.001,.1,10.,100.).sw*2.23454))*20000.)
    return r4(R4S(xyzw)+R4S(yzwx)+R4S(wxyz)+R4S(zwxy));
}

float geo(vec3 p) {
    float d = 1.;
    vec3 fp = floor(p);
    for (float x = -1.; x < 2.; x++) {
        for (float y = -1.; y < 2.; y++) {
            for (float z = -1.; z < 2.; z++) {
                vec3 ap = abs(fp+vec3(x,y,z));
                float h = fract(.5+dot(ap,vec3(1.,128.,2048.))/1.6180339887498948482), yp = clamp(1.1-ap.y*.1,0.,1.), bprob = 20./ap.z*yp;
                yp *= .5;
                if (h > bprob) d = min(d,length(max(abs(p-(fp+vec3(x,y,z)+.5))-yp,0.))-(.5-yp));
            }
        }
    }
    return max(p.y,d);
}

void main(void)
{
#define time time
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    vec3 aas = vec3(0);
    //for (float ax = -1.; ax < 2.; ax++) {
    //    for (float ay = -1.; ay < 2.; ay++) {
            vec3 rp = vec3(1,-9.+pow(time*.06,4.)*12.,time),
                rd = normalize(vec3(uv.xy,1.));
            vec3 c = vec3(1);
            //+vec2(ax,ay)*.5/screenY
    
            rp += vec3(geo(rp+vec3(EPS,0,0)),geo(rp+vec3(0,EPS,0)),geo(rp+vec3(0,0,EPS)))-geo(rp);

            for (int i = 0; i < 300; i++) {
                float dst = geo(rp);
                if (dst <= 0.) {
                    rp -= rd*EPS*1.5;
                    dst = geo(rp);
                    vec3 nrm = vec3(geo(rp+vec3(EPS,0,0)),geo(rp+vec3(0,EPS,0)),geo(rp+vec3(0,0,EPS)))-dst;
                    rd = reflect(rd,normalize(nrm));
                    c *= .8;
                }
                rp += rd*(dst+EPS);
                if (rp.y > 0. && rd.y > 0.) break;
            }
    
            vec3 l = (vec3(.04,.07,.18)+max(0.,1.-length(rd-normalize(vec3(1,1,1)))*(.5+rd.y*.5))*vec3(1.,.8,.6)*2.)*clamp(rp.y*.1+1.,0.,1.);
            aas += c*l;
    //    }
    //}
    glFragColor = vec4(aas,1);
}
