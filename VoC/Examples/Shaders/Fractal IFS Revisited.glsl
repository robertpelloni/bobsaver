#version 420

// original https://www.shadertoy.com/view/ttyyWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define MaxSteps 60.
#define MinDistance 0.001
#define eps 0.001
#define Iterations 16.

mat3 rotateX(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotateY(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

mat3 rotateZ(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

vec2 DE(vec3 z)
{
    float trap = 10000.;
    float angl = cos(time/20.)*2.*3.14159;
    mat3 rz = rotateZ(angl);
    mat3 rot = rz;
 
    float Scale = 2. + cos(time/8.)*.5;
    float Offset = .65;
    float n = 0.;
    while (n < Iterations) {
       z *= rot;
       if(z.x - z.y < 0.) z.yx = z.xy;
       if(z.x + z.y < 0.) z.yx = -z.xy;
       if(z.x - z.z < 0.) z.xz = z.zx;
       z *= rot;
       z = abs(z);
       z = z*Scale - vec3(vec3(Offset*(Scale-1.0)).xy, 0);
       trap = min(length(z), trap);
       n++;
    }
    return vec2((length(z) ) * pow(Scale, -float(n)), trap);
}

vec2 scene(vec3 p) {
    float t = time/4.;
    p *= rotateY(t);
    float size = 1.3;
    return DE(size*p - vec3(0,.1,0))/size;
}

float shadowScene(vec3 p){
    return DE(p - vec3(0,.1,0)).x;
}

vec3 calcNormal(vec3 p) {
    vec2 h = vec2(0.0001,0);
    return normalize(vec3(scene(p+h.xyy).x - scene(p-h.xyy).x, 
                          scene(p+h.yxy).x - scene(p-h.yxy).x, 
                          scene(p+h.yyx).x - scene(p-h.yyx).x));
}

vec3 march(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        vec2 hit = scene(p);
        
        if(hit.x < MinDistance) {
            return vec3(t-MinDistance, 1.-i/MaxSteps, hit.y);  
        }
        t += hit.x;
        if(t > 20.) {
            break;
        }
        
    }
    return vec3(0.);
}

float marchShadow(vec3 ro, vec3 rd) {
    float t = 0., i = 0.;
    for(i=0.; i < MaxSteps; i++) {
        vec3 p = ro + t * rd;
        float dt = shadowScene(p);
        t += dt;
        if(dt < MinDistance) {
            return t-MinDistance;    
        }
    }
    return 0.;
}

float angle(vec3 a, vec3 b) {
    return acos(dot(a,b) / (length(a)*length(b)));
}

vec3 brdf_gauss(vec3 N, vec3 L, vec3 V, vec3 diff, vec3 spec) {
    vec3 H = normalize(L+V);
    //specular
    float m = 0.7;
    float NHm = angle(N,H) / m;
    float NHm2 = NHm*NHm;
    float k_gauss = exp(-NHm2);
    //diffuse
    float wrap = 0.5;
    float diffuse = max(0., dot(L, N));
    float wrap_diffuse = max(0., (dot(L, N) + wrap) / (1. + wrap));
    
    return diff * diffuse + spec * k_gauss;
}

vec3 magma(float t) { // from Mattz
    const vec3 c0 = vec3(-0.002136485053939582, -0.000749655052795221, -0.005386127855323933);
    const vec3 c1 = vec3(0.2516605407371642, 0.6775232436837668, 2.494026599312351);
    const vec3 c2 = vec3(8.353717279216625, -3.577719514958484, 0.3144679030132573);
    const vec3 c3 = vec3(-27.66873308576866, 14.26473078096533, -13.64921318813922);
    const vec3 c4 = vec3(52.17613981234068, -27.94360607168351, 12.94416944238394);
    const vec3 c5 = vec3(-50.76852536473588, 29.04658282127291, 4.23415299384598);
    const vec3 c6 = vec3(18.65570506591883, -11.48977351997711, -5.601961508734096);
    t *= 2.; if(t >= 1.) { t = 2. - t; }
    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));
}

vec3 light(vec3 P, vec3 N, vec3 rd, float trap) {
   
    vec3 ambient = vec3(.1);
    vec3 diff = magma(trap);
    vec3 spec = vec3(.9,.9,.7) * .5;
    return brdf_gauss(N, normalize(vec3(3,5,-3) - P), -rd, diff, spec)
         + brdf_gauss(N, normalize(vec3(-5,-5,3) - P), -rd, diff, spec)*.6;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;
    vec3 col = vec3(.0);
    vec3 ro = vec3(0,0.18,-1); 
    vec3 rd = normalize(vec3(uv.x, uv.y, 0) - ro);
    
    vec3 hit = march(ro, rd);
    float t = hit.x;
    
    if(t > eps) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        col = light(p, n, rd, hit.z);
        col *= hit.y;
    }
    else { 
        vec3 bg = vec3(0.85);//texture(iChannel0, rd).rgb;
        col = mix(bg*.8, bg*.5, smoothstep(.2, .6, gl_FragCoord.xy.y/R.y));
        
    }
    glFragColor = vec4(pow(col, vec3(2.2)),1.0);
}
