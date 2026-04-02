#version 420

// original https://www.shadertoy.com/view/4lsSDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sphere(vec3 p, float s)
{
    float k = length(p)-s;
    return k < 0.0 ? 0.0 : k;
}

float duckBody(vec3 p) {
    float k = 6.0;
    float a = 0.;
    
    a += exp(-k * sphere(p + vec3(0.11, 0, 0.1), 0.06));
    a += exp(-k * sphere(p + vec3(-0.11, 0, 0.1), 0.06));
    a += exp(-k * sphere(p + vec3(0.2, 0, 0.3), 0.1));
    a += exp(-k * sphere(p + vec3(-0.2, 0, 0.3), 0.1));
    a += exp(-k * sphere(p + vec3(0.2, 0, 0.55), 0.07));
    a += exp(-k * sphere(p + vec3(-0.2, 0, 0.55), 0.07));
    a += exp(-k * sphere(p + vec3(-0.00, 0, 0.72), 0.1));
    
    a += exp(-k * sphere(p + vec3(0, -0.39, 0.8), 0.01));

    a += exp(-k * sphere(p + vec3(0, -0.7, 0.1), 0.15));
    a += exp(-k * sphere(p + vec3(0, -0.65, -0.05), 0.07));

    return -log(a) / k;
}

float beak(vec3 p, float s)
{
    float k = max(length(p)-s, -(length(p+vec3(-0.15,-0.2,-0.1))-0.25));
    k = max(k, -(length(p+vec3(0.12,-0.2,-0.1))-0.25));
    return k < 0.0 ? 0.0 : k;
}

float duckBeak(vec3 p) {
    float k = 12.0;
    float a = 0.;
    
    a += exp(-k * beak(p + vec3(0, -0.55, -0.1), 0.15));

    return -log(a) / k;
}

vec4 nearest(vec4 d1, vec4 d2)
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec3 rotate(vec3 p, float angle)
{
    float  c = cos(angle);
    float  s = sin(angle);
    return vec3(c*p.x-s*p.z, p.y, s*p.x+c*p.z);
}

vec4 map(vec3 pos)
{
    vec3 offset = vec3(0, 0.4, -0.3);
    vec4 res = vec4(duckBody(pos-vec3(-0.0, 0.25, 0.0)+offset), vec3(1, 1, 0));
    res = nearest(res, vec4(duckBeak(pos-vec3(-0.0, 0.25, 0.0)+offset), vec3(1, 0, 0)));
    res = nearest(res, vec4(sphere(pos-vec3(0.09, 0.87, 0.14)+offset, 0.06), vec3(0.0, 0, 0.3)));
    res = nearest(res, vec4(sphere(pos-vec3(-0.09, 0.87, 0.14)+offset, 0.06), vec3(0.0, 0, 0.3)));
 
    return res;
}

vec4 castRay(in vec3 ro, in vec3 rd)
{
    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.002;
    float t = tmin;
    vec3 color = vec3(1, 0, 1);
    for(int i=0; i<50; i++)
    {
        vec4 res = map(ro+rd*t);
        if(res.x<precis || t>tmax) break;
        t += res.x;
        color = res.yzw;
    }

    if(t>tmax) t=-1.0;
    return vec4(t, color);
}

vec3 calcNormal(in vec3 pos)
{
    vec3 eps = vec3(0.001, 0.0, 0.0);
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x);
    return normalize(nor);
}

vec4 render(in vec3 ro, in vec3 rd, float angle)
{ 
    vec4 res = castRay(ro,rd);

    float t = res.x;
    vec3 col = res.yzw;
    if(t>-0.5)
    {
        // Light calculations by iq
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);
        vec3 ref = reflect(rd, nor);
        
        vec3  lig = normalize(vec3(0.6*cos(angle), 0.3, -0.6*sin(angle)));
        float amb = clamp(0.5+0.5*nor.y, 0.0, 1.0);
        float dif = clamp(dot(nor, lig), 0.0, 1.0);
        float bac = clamp(dot(nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0)*clamp(1.0-pos.y,0.0,1.0);
        float dom = smoothstep(-0.1, 0.1, ref.y);
        float fre = pow(clamp(1.0+dot(nor,rd),0.0,1.0), 2.0);
        float spe = pow(clamp(dot(ref, lig), 0.0, 1.0),6.0);

        vec3 brdf = vec3(0.0);
        brdf += 0.50*dif*vec3(1.00,0.90,0.60);
        brdf += 0.30*spe*vec3(1.00,0.90,0.60)*dif;
        brdf += 0.70*amb*vec3(0.50,0.70,1.00);
        brdf += 0.40*fre*vec3(1.00,1.00,1.00);
        brdf += 0.02;
        col = col*brdf;

        return vec4(clamp(col, 0.0, 1.0), 1.0);
    }
   return vec4(0, 0, 0, 0);
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr)
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize(cross(cw,cp));
    vec3 cv = normalize(cross(cu,cw));
    return mat3(cu, cv, cw);
}

vec4 mixc(vec4 c1, vec4 c2) {
  float newa = mix(c2.a, c2.a, c1.a);
  return vec4(mix(c1.rgb, c2.rgb, newa), 1.0-(1.0-c1.a)*(1.0-c2.a));
}

vec4 background(vec2 p, float time)
{
  float rat = 1.0 + 0.4 * sin(time*0.744);
  vec3 C1 = vec3(0.7, 0.7, 0.5);
  vec3 C2 = vec3(0.7, 0.7, 0.4);
  vec3 C3 = vec3(sin(time)*0.4+0.5, 0.22, 0.712);
    
  float dist = length(p);
  float angle = atan(p.x, p.y);
  vec4 color = vec4(C3.x, C3.y, C3.z, clamp(1.0 - dist*0.4, 0.0, 1.0)*rat);  

  float ray1 = clamp((sin(angle*6.0 - dist*sin(time)*5.0 + time*2.0) + 0.0) * 2.0, 0.0, 0.7) - dist*0.3;
  color = mixc(color, vec4(C1.x, C1.y, C1.z, ray1*rat));

  float ray2 = clamp((sin(angle*17.0 -dist * 8.0 + time*3.43) + 0.0) * 2.0, 0.0, 0.4) - dist*0.1;
  color = mixc(color, vec4(C2.x, C2.y, C2.z, ray2*rat));

  float circ = clamp((2.25-dist*2.0)*0.47, 0.0, 1.0);
  color = mixc(color, vec4(1, 1, 1, circ*rat));
    
  color *= clamp(1.0-pow(p.x*p.x+p.y*p.y, 0.95)*0.2, 0.0, 1.0);

  return color;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    vec2 mo = mouse*resolution.xy.xy/resolution.xy;
         
    float time = time;
    float Dist = 3.0;

    // camera    
    float angle = 1.0*time + 6.0*mo.x;
    vec3 ro = vec3(Dist*cos(angle), 0.0 , Dist*sin(angle));
    vec3 ta = vec3(-0.0, 0.0, 0.0);
    mat3 ca = setCamera(ro, ta, 0.0);
    vec3 rd = ca * normalize(vec3(p.xy,2.5));

    vec4 duckColor = render(ro, rd, -0.8-angle);
    vec4 backgroundColor = background(p, time);
    glFragColor = mix(backgroundColor, duckColor, duckColor.a);
}
