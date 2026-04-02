#version 420

// original https://www.shadertoy.com/view/3dtczn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define textureCube texture

#define MAX_STEPS 99
#define MAX_DIST 20.
#define EPSILON 0.001
#define PI 3.1415

#define EMPTY 0.
#define MIRROR 1.
#define BLUE 2.
#define BLACK 3.
#define RED 4.
#define WHITE_MIRROR 5.
#define PUREWHITE 6.
#define n getNormal(p)

#define tBeam vec2(.2,.5)

#define PHI (sqrt(5.)*0.5 + 0.5)
#define tChank 4.28125

mat2 Rot(float a) { float s = sin(a), c = cos(a); return mat2(c, -s, s, c); }
float sdBox( vec3 p, vec3 b ) { vec3 q = abs(p) - b; return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0); }
float sdOctahedron( vec3 p, float s) { p = abs(p); float m = p.x+p.y+p.z-s; vec3 q; if( 3.0*p.x < m ) q = p.xyz; else if( 3.0*p.y < m ) q = p.yzx; else if( 3.0*p.z < m ) q = p.zxy; else return m*0.57735027; float k = clamp(0.5*(q.z-q.y+s),0.0,s); return length(vec3(q.x,q.y-s+k,q.z-k)); }
float Rnd (float x) {return 2.*fract(10000. * sin(10000. * x))-1.;}
float opSmoothUnion( float d1, float d2, float k ) { float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 ); return mix( d2, d1, h ) - k*h*(1.0-h); }
float sdTorus( vec3 p, vec2 t ){ vec2 q = vec2(length(p.xz)-t.x,p.y); return length(q)-t.y;}

float sdWater(vec3 p) {
    float t = time * 10.1;
    p.y += .001*sin(p.z*17.+t);
    p.y += .001*sin(p.z*13.+t);
    p.y += .001*sin(p.x*11.+t*.5);
    return p.y;
}

float sdMirrors(vec3 p) {
    float c = 1.1;
    p.xy *= Rot(PI/4.);
    p.xz *= Rot(.1*time);
    vec3 l = vec3(2,0,2), id = round(p/c);
    p = p-c*clamp(id,-l,l);
    p.xz *= Rot(p.y*(Rnd(id.x)+1.) + 30.*time * (Rnd(id.x + 10. * id.z)+1.5));
    // p.xz *= atan(p.x, p.z);
    return sdBox(p, vec3(.1,10.,.001));
}

float sdRocket (vec3 p){
    // p.y /= 2.;
    // p.xz *= Rot(time);
    p.xy *= Rot(PI/4.);
    float sph=length(p) - 1.;
    for(float i=2.;i<5.;i+=0.5){
        // float shift = 4.*sin(time*i);
        // float shift = 20.*(fract(.1*time*(1.2+.4*Rnd(i))+Rnd(i))*2.-1.)*i;
        float shift = tan(time*(1.2+.4*Rnd(i))+Rnd(i))*10.;
        float spread = 4.;
        sph=opSmoothUnion(sph, (length(p*i+vec3(spread*Rnd(i),shift,spread*Rnd(i+1.))) - 1.)/i, .4);
    }
    return sph;    
}

float sdBeam(vec3 p){
    p.xy *= Rot(PI/4.);
    float size = 3.*Rnd(time)*.5+.5;
    vec3 shift = 2.4*(vec3(Rnd(time+9.), 0, Rnd(time+99.))*.5);
    return sdBox(p+shift, vec3(.2*size,100.,.2*size));
}

float timeCurve(float t) {
    t = t * 4. / tChank;
    // t = t / 1000.;
    float whole = floor(t);
    float decimal = fract(t);
    t =  (whole + 1. - pow(1. - decimal, 32.));
    return t;
}

// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
vec2 getDist(vec3 p) {
    // float t = timeCurve(time);
    // for(float j;++j<6.;){
    //     p=abs(p)-1.1;
    //     p=abs(p)-1.1;
    //     p.xz*=Rot(t / 5.91 + j);
    //     p.xy*=Rot(t / 3.21 + j);
    // }
    // p.y+=1.;
    // float wave = 0.;//pow(sin(length(p + fract((time+.2) * 4. / tChank)))*.5+.5, 64.)*.2;
    // p.y *= .99;
    // p.x = cos(p.z);
    // p.y = sin(p.z);

    // p.z = cos(p.z * 1. + time * 10.);
    // p.zy*=Rot(PI / 2.);
    // vec2 obj = vec2(sdTorus(p, vec2(3.3, 0.)), WHITE_MIRROR);
    // p.x -= 1.;
    p.z += time * 10.1;
    float w = p.z * 1.5 + time * 1.;
    p.x += .6*cos(w);
    p.y += .6*sin(w);
    // p.y*=Rot(PI / 2.);
    p.xy*=Rot(p.z * 1.1 + time);
    p.x += 1.4;
    vec2 obj = vec2(length(p.xy) * .3, WHITE_MIRROR);

    return obj;
}
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

vec3 rayMarch(vec3 ro, vec3 rd) {
    float d = 0.;
    float info = EMPTY;
    float minAngleToObstacle = 1e10;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 distToClosest = getDist(ro + rd * d);
        minAngleToObstacle = min(minAngleToObstacle, atan(distToClosest.x, d));
        d += abs(distToClosest.x);
        info = distToClosest.y;
        if(abs(distToClosest.x) < EPSILON || d > MAX_DIST) {
            break;
        }
    }
    return vec3(d, info, minAngleToObstacle);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.);
    vec3 n_ = getDist(p).x - vec3(getDist(p - e.xyy).x,
                               getDist(p - e.yxy).x,
                               getDist(p - e.yyx).x);
    return normalize(n_);
}

vec3 getRayDirection (vec3 ro, vec2 uv, vec3 lookAt) {
    vec3 rd;
    rd = normalize(vec3(uv - vec2(0, 0.), 1.));
    vec3 lookTo = lookAt - ro;
    float horizAngle = acos(dot(lookTo.xz, rd.xz) / length(lookTo.xz) * length(rd.xz));
    rd.xz *= Rot(horizAngle);
    return rd;
}

vec3 getRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

// used recursively for reflections
// vec3 getColor(vec3 ro, vec3 rd, vec3 color, int depth) {
// }

void main(void)
{
    float d, info, dTotal=0.;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 ro, rd, color, p, rm;
    float camDist = -10.;// + 5.*sin(timeCurve(time));//-17.+12.*smoothstep(2., 2.3, fract(time/5.)*5.);
    ro = vec3(0,0,camDist);
    // ro.xz *= Rot(timeCurve(time));
    // ro.xy *= Rot(PI/4.);
    // ro += 1.1*sin(time*4.)*vec3(Rnd(time),Rnd(time+100.),0); // shake
    rd = getRayDir(uv, ro, vec3(0), 1.);
    color = vec3(0);
    float colorAmount = 0.;

    // for(int reflectionDepth = 0; reflectionDepth < 2; reflectionDepth++) {
    //     rm = rayMarch(ro, rd);
    //     dTotal += d = rm[0];
    //     info = rm[1];
    //     p = ro + rd * d;
    //     if (d < MAX_DIST) {
    //         // color = vec3(1);//textureCube(iChannel0, rd).rgb;
    //         if (info == MIRROR) {
    //             rd = reflect(rd, n);
    //             ro = p + 0.01 * rd;
    //             continue;
    //             // do nothing, propogate color getting to the reflection
    //         }
    //         else if (info == WHITE_MIRROR) {
    //             vec3 nn = n;
    //             nn.xy*=Rot(1.);
    //             // color = vec3(1) * (dot(nn, vec3(1,1,-1))*.3+.7);
    //             color = nn*.5+.5;
    //         }
    //         else if (info == PUREWHITE) {
    //             color += vec3(1) * (1. - colorAmount);
    //             colorAmount = 1.;
    //         }
    //     }
    //     else {
    //         // color += textureCube(iChannel0, vec3(rd.y, rd.xz*Rot(time)).yxz).rgb * (1. - colorAmount);
    //         // colorAmount = 1.;
    //     }
    //     break;
    // }
    // // color = mix(color, vec3(0,uv.yx+.5)*.2, smoothstep(20., 100., dTotal));
    // color = mix(color, rd*.2, smoothstep(20., 100., dTotal));
    // glFragColor = vec4(color, 1);
 
    rm = rayMarch(ro, rd);
    glFragColor = vec4(vec3(.003/rm.z), 1);

}
