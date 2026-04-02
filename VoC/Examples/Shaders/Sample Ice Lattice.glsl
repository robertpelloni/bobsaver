#version 420

// original https://www.shadertoy.com/view/WtGBDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float max_iter = 200.0;

float sdfSphere(vec3 p, vec4 sphere)
{
    return distance(p, sphere.xyz) - sphere.w;
}

vec3 rotate_z(vec3 p, float a)
{
    return mat3(
        vec3(sin(a), cos(a),0),
        vec3(-cos(a), sin(a),0),
        vec3(0,0,1)
    ) * p;
}

vec3 rotate_y(vec3 p, float a)
{
    return mat3(
        vec3(sin(a), 0, cos(a)),
        vec3(0,1,0),
        vec3(-cos(a),0, sin(a))
    ) * p;
}

float subsurf_ndotl(vec3 n, vec3 l, float wrap)
{
    return max(0.0, (dot(n,l)+wrap) / (1. + wrap));
}

vec3 fresnelSchlickR(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
}   

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(max(1.0 - cosTheta, 0.0), 5.0);
}

// bump mapping from https://www.shadertoy.com/view/4ts3z2
float tri(in float x){return abs(fract(x)-.5);}
vec3 tri3(in vec3 p){return vec3( tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));}
                                 
mat2 m2 = mat2(0.970,  0.242, -0.242,  0.970);

float triNoise3d(in vec3 p, in float spd)
{
    float z=1.4;
    float rz = 0.;
    vec3 bp = p;
    for (float i=0.; i<=3.; i++ )
    {
        vec3 dg = tri3(bp*2.);
        p += (dg+time*spd);

        bp *= 1.8;
        z *= 1.5;
        p *= 1.2;
        //p.xz*= m2;
        
        rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        bp += 0.14;
    }
    return rz;
}

float bnoise(in vec3 p)
{
    float n = sin(triNoise3d(p*.3,0.0)*11.)*0.6+0.4;
    n += sin(triNoise3d(p*1.,0.05)*40.)*0.1+0.9;
    return (n*n)*0.003;
}

vec3 bump(in vec3 p, in vec3 n, in float ds)
{
    vec2 e = vec2(.005,0);
    float n0 = bnoise(p);
    vec3 d = vec3(bnoise(p+e.xyy)-n0, bnoise(p+e.yxy)-n0, bnoise(p+e.yyx)-n0)/e.x;
    n = normalize(n-d*2.5/sqrt(ds));
    return n;
}

vec3 map(vec3 p)
{
    vec4 sphere_1 = vec4(.50,.50,.50,.40);
    
    
    p = mod(p, vec3(2.0));
    
    
    float d1 = sdfSphere(p, sphere_1);

    float d2 = distance(p.xz, vec2(0.5,0.5)) - 0.1;
    float d3 = distance(p.xy, vec2(0.5,0.5)) - 0.1;
    float d4 = distance(p.zy, vec2(0.5,0.5)) - 0.1;

    float td = min(d1,d2);
    td = min(td, d3);
    td = min(td, d4);
    
    return vec3(td,0,0);
}

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.1, 0., 0. );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

vec4 ray_march(vec3 ro, vec3 rd, float min_d, float max_d, float pres, bool rotate)
{
    float dist = 0.0;
    float total_dist = 0.0;
    vec3 point = ro;
    for (float i = 0.0; i < max_iter; i+=1.0)
    {
        float dist = map(point).x * pres;
        if(dist < min_d || total_dist > max_d) break;
        point += dist*rd;
        total_dist += dist;
        if (rotate)
           rd.xy = cos(0.15*dist)*rd.xy + sin(0.15*dist)*vec2(-rd.y, rd.x);
    }
    return vec4(point, total_dist);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2. -1.;
    uv.x*=resolution.x/resolution.y;
    
    vec3 ro = vec3(0,1,5.0 + time);
    vec3 rd = vec3(uv.x, uv.y, -1);
    rd = normalize(rd);
    
    rd = rotate_y(rd,time);
    rd = rotate_z(rd,time*0.5);

    const float min_dist = 0.002;
    const float max_dist = 100.0;
    
    
    vec4 res = ray_march(ro, rd, min_dist, max_dist, .2570, true);
    float total_dist = res.w;
    
    vec3 world_point = res.xyz;
    
    float depth = ray_march(world_point + rd * 0.2 , rd, 0.000001, max_dist, -.01280, true).w;
    
    //depth = depth/(1.0+depth);
    
    vec3 n = calcNormal(world_point);
    
    n = bump(mod(world_point,2.0), n, .510);
    
    float ndotv = max(0.0,dot(n, -rd));
    vec3 fres = fresnelSchlick(ndotv*0.5, vec3(0.04));
    vec3 mask_1 = 1.0 - fresnelSchlick(ndotv, vec3(0.04)) * 20.0;
    mask_1 = smoothstep(0.0, .30, mask_1) * 1.6666;
    
    
    vec3 col = vec3(total_dist/5.0);
    vec3 l = normalize(vec3(1,2,3));
    float ndotl = subsurf_ndotl(n,l,.50);
    
    float lo = ndotl;
    
    vec3 c1 = vec3(0.513,0.522,0.98); 
    vec3 c2 = vec3(0.653,0.642,0.98);
    
    c1 = pow(c1, vec3(2.2));
    
    float fog = total_dist/(1.0+total_dist);
    
    col = vec3(c1 + fres);

    col += c2 * max(0.0,exp(-depth));

    col *= vec3(1.0-fog);

    col = pow(col, vec3(2.2));  
    col = col/(1.0+col);
    col = pow(col, vec3(1.0/2.2));  
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
