#version 420

// original https://www.shadertoy.com/view/tdS3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Minus256
const float err = 0.001;
const float sta = 0.0;
const float end = 7000.0;
const int mxmrch = 255;
float spheresdf(vec3 p,float r)
{
    return length(p) - r;
}
float rep(vec3 p,vec3 c)
{
    vec3 q = mod(p,c)-0.5*c;
    return spheresdf(q,max(50.0*sin(time*5.0),30.0));
}
float scenesdf(vec3 p)
{
    vec3 damn = vec3(200.0,200.0,200.0);
    return rep(p,damn);
}
vec3 raydir(float fov,vec2 res,vec2 pos)
{
    vec2 dir = pos - res/2.0;
    float depth = (res.y/2.0)/tan(radians(fov/2.0));
    return normalize(vec3(dir,-depth));
}
mat4 viewmat(vec3 pos, vec3 centerdir, vec3 roll) {
    vec3 f = normalize(centerdir - pos);
    vec3 s = normalize(cross(f, roll));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}
vec3 normal(vec3 p)
{
    return normalize(vec3(
        scenesdf(vec3(p.x + 1.5+sin(time)*0.1,p.y,p.z)) - scenesdf(vec3(p.x - 4.1,p.y,p.z)),
        scenesdf(vec3(p.x,p.y + 4.1,p.z)) - scenesdf(vec3(p.x,p.y - 1.7+sin(time)*0.1,p.z)),
        scenesdf(vec3(p.x,p.y,p.z + 9.7+sin(time)*0.1)) - scenesdf(vec3(p.x,p.y,p.z - 8.1))
        ));
}
float dirlength(vec3 p,vec3 raydir)
{
    float depth = 2.0;
    for(int i = 0; i < mxmrch; i++)
    {
        float dist = scenesdf(p + raydir * depth);
            if(dist < err)
            {
                return depth;
            }
        depth += dist;
        if(depth >= end)
        {
            return end;
        }
    }
    return end;
}
float Minresetnor(vec3 lightpos,vec3 normalo,vec3 eye,vec3 rgb,float ext,float strongness)
{
    vec3 dir = normalo;
    vec3 point = eye;
    vec3 altp = dir*dirlength(eye,normalo);
    float altl = dirlength(eye,normalo);
    float altl2 = altl;
    for(int i = 0;i<2;i++)
    {
        altp = dir*altl;
        dir = reflect(dir,normal(altp));
        altl = dirlength(altp,dir);
        altl2 = altl2+altl;
    }
    return altl2;
}
vec3 Minresetnorr(vec3 lightpos,vec3 normalo,vec3 eye,vec3 rgb,float ext,float strongness)
{
    vec3 dir = normalo;
    vec3 point = eye;
    vec3 altp = dir*dirlength(eye,normalo);
    float altl = dirlength(eye,normalo);
    float altl2 = altl;
    for(int i = 0;i<2;i++)
    {
        altp = dir*altl;
        dir = reflect(dir,normal(altp));
        altl = dirlength(altp,dir);
        altl2 = altl2+altl;
    }
    return altp;
}
vec3 PCFL(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
    vec3 lightPos, vec3 lightITs,vec3 ffff) {
    vec3 N = ffff;
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));   
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    if (dotLN < 0.0) {
        return vec3(0.0, 0.0, 0.0);
    } 
    if (dotRV < 0.0) {
        return lightITs * (k_d * dotLN);
    }
    return lightITs * (k_d * dotLN + k_s * pow(dotRV, alpha));
}
vec3 POI(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,vec3 ffff) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    vec3 light1Pos = vec3(4.0 * sin(time),
                          2.0,
                          4.0 * cos(time));
    vec3 light1ITs = vec3(0.4, 0.4, 0.4);
    color += PCFL(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1ITs,ffff);
    vec3 light2Pos = vec3(2.0 * sin(0.37 *time),
                          2.0 * cos(0.37 * time),
                          2.0);
    vec3 light2ITs = vec3(0.4, 0.4, 0.4);
    color += PCFL(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2ITs,ffff);    
    return color;
}
void main(void)
{
    vec4 background = vec4(0.5,0.5,0.5,1.0);
    vec3 viewDir = raydir(90.0, resolution.xy, gl_FragCoord.xy);
    vec3 pointt = vec3(700.0*sin(time),400.0*cos(time),mod(time*400.0,sin(time*400.0)));
    mat4 viewToWorld = viewmat(pointt, vec3(0.0), normalize(vec3(sin(mod(time*5.0,5.0)),cos(time*0.5),cos(time))));   
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    float dist = dirlength(pointt, worldDir);
    vec3 eye = (pointt + dist * worldDir);
    vec3 ambient = vec3(1.0,1.0,1.0);
    vec3 hellr = Minresetnorr(vec3(0.0),worldDir,pointt,vec3(0.0,0.0,1.0),10.0,0.5);
    vec3 K_a = vec3(0.2, 0.2, 0.2);
    vec3 K_d = vec3(0.7, 0.2, 0.2);
    vec3 K_s = vec3(1.0, 1.0, 1.0);
    float shininess = 10.0;
    vec3 p = pointt + dist * worldDir;
    vec3 normcolor = normal(hellr);
    vec3 color = POI(K_a, K_d, K_s, shininess, p, pointt,normcolor);
    float hell = Minresetnor(vec3(0.0),worldDir,eye,vec3(0.0,0.0,1.0),10.0,0.5);
    float minphase = clamp(abs(1.1*sin(time*10.0)*sin(gl_FragCoord.y)),0.0,0.3);
    glFragColor = vec4(1.0) - vec4((hell)/(end))+vec4(vec3(color),0.0) - vec4(dist/(end-40.0*abs(sin(time)))) 
        - vec4(minphase) + vec4(vec3(0.2,0.2,0.5),0.0);
}   
