#version 420

// original https://www.shadertoy.com/view/XdcSzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Trying to learn some basic stuff about cg and raytracing. Wanted to replicate this: https://www.youtube.com/watch?v=V5Y06xkRWio
   Not sure how he has handled recursion for transmissive and reflective rays but I tried to look everywhere but couldn't find how
   to go it in a shader without it running horrendously slow.
*/

const int iterations = 5;
const float maxDist = 1000.0;
const vec3 amb = vec3(1.0);
const float eps = 1e-3;

struct Camera
{
    vec3 up, right, forward;
    vec3 position;
};

Camera cam;
vec4 spheres[10];
vec4 colors[10];
vec2 materials[10];

void init()
{
    // X Y Z Radius
    spheres[0] = vec4(      0,       0,    -1.5,    0.1);
    spheres[1] = vec4(     -0,    0.25,    -1.5,    0.1);
    spheres[2] = vec4(      0,    -0.7,    -1.5,    0.3);
    spheres[3] = vec4(      0,    -0.1,    -1.5,    0.2);
    spheres[4] = vec4(      0,    -0.1,    -1.5,    0.12);
    spheres[5] = vec4( 1001.0,       0,       0, 1000.0); 
    spheres[6] = vec4(-1001.0,       0,       0, 1000.0);
    spheres[7] = vec4(      0,  1001.0,       0, 1000.0); 
    spheres[8] = vec4(      0, -1001.0,       0, 1000.0);
    spheres[9] = vec4(      0,       0, -1002.0, 1000.0);

    //R G B Diffuse
    colors[0] = vec4(1.0, 0.8, 0.0,-1.0);
    colors[1] = vec4(0.0, 0.0, 1.0,-1.0);
    colors[2] = vec4(1.0, 1.0, 1.0, 1.0);
    colors[3] = vec4(1.0, 1.0, 1.0, 1.0);
    colors[4] = vec4(0.0, 1.0, 0.0, 1.0);
    colors[5] = vec4(0.0, 1.0, 0.0, 0.7);
    colors[6] = vec4(1.0, 0.0, 0.0, 0.7);
    colors[7] = vec4(1.0, 1.0, 1.0, 0.7);
    colors[8] = vec4(1.0, 1.0, 1.0, 0.7);
    colors[9] = vec4(1.0, 1.0, 1.0, 0.7);

    //Reflection Coeff, Refraction index
    materials[0] = vec2 (0.0, 0.0);
    materials[1] = vec2 (0.0, 0.0);                
    materials[2] = vec2 (1.0, 0.0);    
    materials[3] = vec2 (0.1, 0.8);    
    materials[4] = vec2 (0.1, 0.8);    
    materials[5] = vec2 (0.0, 0.0);                
    materials[6] = vec2 (0.0, 0.0);                
    materials[7] = vec2 (0.1, 0.0);                
    materials[8] = vec2 (0.1, 0.0);                
    materials[9] = vec2 (0.1, 0.0);    

    cam.up = vec3(0,1,0);
    cam.right = vec3(1,0,0);
    cam.forward = vec3(0,0,-1);
    cam.position = vec3(0,0,-0.2);
}

vec3 getRayDir(vec2 gl_FragCoord)
{
  vec2 uv = (gl_FragCoord.xy / resolution.xy )*2.0 - 1.0;
  uv.x *= resolution.x/resolution.y;                   
  return normalize(uv.x * cam.right + uv.y * cam.up + cam.forward);
}

// The Intersection funtions and shading funcs are taken from inigo's article:
// http://www.iquilezles.org/www/articles/simplegpurt/simplegpurt.htm

bool intersectSphere(vec3 ro, vec3 rd, vec4 sp, float tm, out float t)
{
    bool r = false;
    vec3 v = ro - sp.xyz;
    float b = dot(v,rd);
    float c = dot(v,v) - sp.w*sp.w;
    t = b*b-c;
    if( t > 0.0 )
    {
        t = -b-sqrt(t);
        r = (t > 0.0) && (t < tm);
    }
    return r;
}

float calcInter(vec3 ro, vec3 rd, out vec4 ob, out vec4 col,out vec2 mat)
{
    float tm = 10000.0;
    float t;

    if(intersectSphere(ro,rd,spheres[0],tm,t)) { ob = spheres[0]; col = colors[0]; tm = t; mat = materials[0]; }
    if(intersectSphere(ro,rd,spheres[1],tm,t)) { ob = spheres[1]; col = colors[1]; tm = t; mat = materials[1]; }
    if(intersectSphere(ro,rd,spheres[2],tm,t)) { ob = spheres[2]; col = colors[2]; tm = t; mat = materials[2]; }
    if(intersectSphere(ro,rd,spheres[3],tm,t)) { ob = spheres[3]; col = colors[3]; tm = t; mat = materials[3]; }
    if(intersectSphere(ro,rd,spheres[4],tm,t)) { ob = spheres[4]; col = colors[4]; tm = t; mat = materials[4]; }
    if(intersectSphere(ro,rd,spheres[5],tm,t)) { ob = spheres[5]; col = colors[5]; tm = t; mat = materials[5]; }
    if(intersectSphere(ro,rd,spheres[6],tm,t)) { ob = spheres[6]; col = colors[6]; tm = t; mat = materials[6]; }
    if(intersectSphere(ro,rd,spheres[7],tm,t)) { ob = spheres[7]; col = colors[7]; tm = t; mat = materials[7]; }
    if(intersectSphere(ro,rd,spheres[8],tm,t)) { ob = spheres[8]; col = colors[8]; tm = t; mat = materials[8]; }
    if(intersectSphere(ro,rd,spheres[9],tm,t)) { ob = spheres[9]; col = colors[9]; tm = t; mat = materials[9]; }

    return tm;
}

bool inShadow(vec3 ro,vec3 rd,float d)
{
    float t;

         if(intersectSphere(ro,rd,spheres[2],d,t)){ return true; }
    else if(intersectSphere(ro,rd,spheres[3],d,t)){ return true; }
    else if(intersectSphere(ro,rd,spheres[4],d,t)){ return true; }
    else if(intersectSphere(ro,rd,spheres[5],d,t)){ return true; }
    else if(intersectSphere(ro,rd,spheres[6],d,t)){ return true; }
    else if(intersectSphere(ro,rd,spheres[7],d,t)){ return true; }
    else if(intersectSphere(ro,rd,spheres[8],d,t)){ return true; }
    else if(intersectSphere(ro,rd,spheres[9],d,t)){ return true; }
    
    return false;

}

vec3 calcShade(vec3 pt, vec4 ob, vec4 col,vec2 mat,vec3 n)
{

    float dist,diff;
    vec3 lcol,l;

    vec3 color = vec3(0.0);
    vec3 ambcol = amb * (1.0-col.w) * col.rgb;
    vec3 scol = col.w * col.rgb;

    if(col.w > 0.0) //If its not a light
    {
        l = spheres[0].xyz - pt;
        dist = length(l);
        l = normalize(l);
        lcol = colors[0].rgb;
        diff = clamp(dot(n,l),0.0,1.0);
        color += (ambcol * lcol + lcol * diff * scol) / (1.0+dist*dist);
        if(inShadow(pt,l,dist))
            color *= 0.7;

        l = spheres[1].xyz - pt;
        dist = length(l);
        l = normalize(l);
        vec3 lcol = colors[1].rgb;
        diff = clamp(dot(n,l),0.0,1.0);
        color += (ambcol * lcol + lcol * diff * scol) / (1.0+dist*dist);

        if(inShadow(pt,l,dist))
            color *= 0.7;
    }
    else
        color = col.rgb;

    return color;
}

float getFresnel(vec3 n,vec3 rd,float r0)
{
    float ndotv = clamp(dot(n, -rd), 0.0, 1.0);
    return r0 + (1.0 - r0) * pow(1.0 - ndotv, 5.0);
}

vec3 getReflection(vec3 ro,vec3 rd)
{
    vec3 color = vec3(0);
    vec4 ob,col;
    vec2 mat;
    float tm = calcInter(ro,rd,ob,col,mat);
    if(tm < maxDist)
    {
        vec3 pt = ro + rd*tm;
        vec3 n = normalize(pt - ob.xyz);
        color = calcShade(pt,ob,col,mat,n);
    }
    return color;
}

void rotObjects()
{
    spheres[0].x = spheres[0].x + sin(time) * 0.4;
    spheres[0].z = spheres[0].z + cos(time) * 0.4;
    
    spheres[1].x = spheres[1].x + sin(time) * -0.3;
    spheres[1].z = spheres[1].z + cos(time) * -0.3;
}

void main(void)
{
    init();
    float fresnel,tm;
    vec4 ob,col;
    vec2 mat;
    vec3 pt,refCol,n,refl;

    vec3 mask = vec3(1.0);
    vec3 color = vec3(0);
    vec3 ro = cam.position;
    vec3 rd = getRayDir(gl_FragCoord.xy);
    
    rotObjects();
    
    for(int i = 0; i < iterations; i++)
    {
        tm = calcInter(ro,rd,ob,col,mat);
        if(tm < maxDist)
        {
            pt = ro + rd*tm;
            n = normalize(pt - ob.xyz);
            fresnel = getFresnel(n,rd,mat.x);
            mask *= fresnel;
            
            if(mat.y > 0.0) // Refractive
            {
                ro = pt - n*eps;
                refl = reflect(rd,n);
                refCol = getReflection(ro, refl);
                color += refCol * mask;
                mask = col.rgb * (1.0 - fresnel) * (mask / fresnel);
                rd = refract(rd, n, mat.y);
            }
            else if(mat.x > 0.0) // Reflective
            {
                color += calcShade(pt,ob,col,mat,n) * (1.0 - fresnel) * mask / fresnel;
                ro = pt + n*eps;
                rd = reflect(rd, n);
            }
            else // Diffuse
            {
                color += calcShade(pt,ob,col,mat,n) * mask/fresnel;
                break;
            }
        }
    }
    glFragColor = vec4(color,1.0);
}
