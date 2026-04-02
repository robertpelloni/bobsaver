#version 420

// original https://www.shadertoy.com/view/MlycDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//MinusRefraction
const float err = 0.00001;
const float eserr = 0.001;
const float sta = 0.0;
const float end = 1000.0;
const float refval = 1.33;
const int mxmrch = 2000;

//Calculate Ray Dir
vec3 raydir(float fov,vec2 res,vec2 pos)
{
    vec2 norpos = (pos.xy-res.xy/2.0)/(res.xx/2.0);
    float depth = 1.0/(tan(radians(fov/2.0)));
    return normalize(vec3(vec2(norpos.xy),depth));
}

//Transformation Set
mat3 viewmat(vec3 eye, vec3 center, vec3 up)
{
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

mat3 rX(float th)
{
    float c = cos(th);
    float s = sin(th);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rY(float th)
{
    float c = cos(th);
    float s = sin(th);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rZ(float th)
{
    float c = cos(th);
    float s = sin(th);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float opDisplace( vec3 p )
{
    float d1 = sdTorus(p,vec2(10.0,5.0));//length(p)-10.0;
    float D1 = 0.5;
    float d2 = sin(D1*p.x)*sin(D1*p.y)*sin(D1*p.z);
    return d1+d2;
}

//Material Getting
float mat1sdf(vec3 point)
{
    //return -(length(point)-10.0);
    return -(sdBox(point,vec3(100.0)));
}

float mat2sdf(vec3 point)
{
    return length(point-vec3(20.0*sin(time),0.0,-90.0))-10.0;
}

float mat3sdf(vec3 point)
{
    vec3 rp = (point-vec3(0.0,0.0,-30.0)) * rZ(time) * rY(time) * rX(time);
    //return length(point-vec3(1.0,0.0,-3.0))-1.0;
    return opDisplace(rp);
}

vec3 scdstmat(vec3 p)
{
    float sdf = min(mat1sdf(p),min(mat2sdf(p),mat3sdf(p)));
    float minussdf = max(mat1sdf(p),max(mat2sdf(p),mat3sdf(p)));
    float matnum = 0.0;
    if(mat3sdf(p) == sdf)
        matnum = 3.0;
    else if(mat2sdf(p) == sdf)
        matnum = 2.0;
        else
            matnum = 1.0;
        return vec3(sdf,minussdf,matnum);
}

//Scene Distance Function
float scenesdf(vec3 point)
{
    return scdstmat(point).x;
}

float minussdf(vec3 point)
{
    return scdstmat(point).y;
}

float getmat(vec3 point)
{
    return scdstmat(point).z;
}

//Get length
float veclength(vec3 pos,vec3 dir)
{
    float depth = sta;
    float dist = 0.0;
        for(int i = 0; i < mxmrch; i++)
        {
            dist = scenesdf(pos + dir * depth);
                if(abs(dist) < err)
                {
                    return depth;
                }
            depth += dist;
            if(abs(depth) >= end)
            {
                return end;
            }
        }
    return end;
}

//Normal Estimation
vec3 normal(vec3 p)
{
    return normalize(vec3(
        scenesdf(vec3(p.x + eserr,p.y,p.z)) - scenesdf(vec3(p.x - eserr,p.y,p.z)),
        scenesdf(vec3(p.x,p.y + eserr,p.z)) - scenesdf(vec3(p.x,p.y - eserr,p.z)),
        scenesdf(vec3(p.x,p.y,p.z + eserr)) - scenesdf(vec3(p.x,p.y,p.z - eserr))
        ));
}

//Minus256 Refracting Method
vec4 posMath(vec3 firpos,vec3 firdir)
{
    float leng = veclength(firpos,firdir);
    float minusleng , plusleng = .0;
    float mat = 0.0;
    vec3 pos = firdir*leng;
    vec3 dir = firdir;
    vec3 refvec ,fravec= vec3(.0);
    for(int i = 0;i < 10;i++)
    {
    mat = getmat(pos);
        if(mat == 1.0)
        {
            return vec4(pos,leng);
        }
        else if(mat == 2.0)
        {
            refvec = normalize(reflect(dir,normal(pos)));
            plusleng = (veclength(pos,refvec));
            leng += plusleng;
            pos += refvec*plusleng;
            dir = refvec;
        }
        else if(mat == 3.0)
        {
            if(length(dir+normal(pos))>sqrt(2.0))
            {
                fravec = normalize(refract(dir,normal(pos),refval));
                pos -= (normal(pos)*(3.0*err));
                minusleng = (veclength(pos,-fravec));
                pos += (fravec*minusleng);
            }
            else
            {
                pos -= (normal(pos)*(3.0*err));
                fravec = dir;
            }
            pos += (normal(pos))*(3.0*err);
            fravec = normalize(refract(-fravec,-normal(pos),1.0/refval));
            leng += minusleng;
            dir = fravec;
            pos += dir*veclength(pos,dir);
            leng += veclength(pos,fravec);
        }
    }
    return vec4(pos,leng);
}

//Phong Illumination
vec3 phongContribForLight(vec3 k_d,vec3 k_s,float alpha,vec3 p,vec3 eye,
                          vec3 lightPos, vec3 lightIntensity,vec3 ffff)
    {
    vec3 N = ffff;
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));   
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    if (dotLN < 0.0)
    {
        return vec3(0.0, 0.0, 0.0);
    } 
    
    if (dotRV < 0.0)
    {
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

//Phong Illumination Collect
vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,vec3 ffff) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(-10.0,0.0,-50.0);
    vec3 light1Intensity = vec3(0.6, 0.6, 0.6);
    
    color += phongContribForLight(k_d,k_s,alpha,p,eye,light1Pos,light1Intensity,ffff);
    return color;
}

//Main Image
void main(void)
{
    float fov = 90.0;
    vec3 viewDir = raydir(fov,resolution.xy,gl_FragCoord.xy);
    vec3 point = vec3(0.0,0.0,1.0);
    vec3 center = vec3(0.0,0.0,2.0);
    vec3 roll = vec3(0.0,1.0,0.0);
    mat3 viewToWorld = viewmat(point,center,roll);
    vec3 worldDir = viewToWorld * viewDir;
    vec4 posmap = posMath(point,worldDir);
    vec3 p = point + abs(length(point - posmap.xyz)) * worldDir;
    vec3 sp = point + veclength(point,worldDir) * worldDir;
    vec3 snormal = normal(sp);
    
    vec3 a = vec3(0.3,0.3,0.3);
    vec3 d = vec3(0.5,0.5,0.5);
    vec3 s = vec3(1.0,1.0,1.0);
    float al = 1.0;

    vec3 normal = normal(posmap.xyz);
    vec3 color = phongIllumination(a,d,s,al,p,point,normal);
    vec3 scolor = phongIllumination(vec3(.0),vec3(.0),s,al,sp,point,snormal);
    float shad = posmap.w/(4.0*end);
    glFragColor = vec4(color,al);
       // vec4(vec3(0.5)-normal/2.0,al);
}
