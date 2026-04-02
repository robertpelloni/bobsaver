#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Lens Refraction Test

struct Material
{
    int type;
    vec3 col;
    float spec;
};
    
struct Surface
{
    vec3 pos;
    vec3 norm;
    float dist;
    Material mat;    
};
    
mat2 Rotate(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));    
}
    
Material black, white, red, green, glass;

Surface Invert(Surface a)
{
    a.dist = -a.dist;
    return a;
}    
    
Surface Union(Surface a,Surface b)
{
    return (a.dist < b.dist) ? a : b;
}

Surface Intersect(Surface a,Surface b)
{
    return (a.dist > b.dist) ? a : b;
}

Surface Subtract(Surface a,Surface b)
{
    a = Invert(a);
    return (a.dist > b.dist) ? a : b;
}
    
Surface Sphere(vec3 p,float r,Material mat)
{
    Surface object;
    object.dist = length(p) - r;
    object.mat = mat;
    
    return object;
}

Surface Plane(vec3 p,vec3 n,float d,Material mat)
{
    Surface object;
    object.dist = dot(p,normalize(n)) + d;
    object.mat = mat;
    
    return object;
}

Surface Map(vec3 p)
{
    Surface scene = Invert(Sphere(p,8.0,white));
    
    scene = Union(scene,Plane(p,vec3(-1,0,0),1.0,green));
    scene = Union(scene,Plane(p,vec3(1,0,0),1.0,red));
    scene = Union(scene,Plane(p,vec3(0,1,0),1.0,white));
    scene = Union(scene,Plane(p,vec3(0,-1,0),1.0,white));
    scene = Union(scene,Plane(p,vec3(0,0,-1),4.0,white));
    
    scene = Intersect(Plane(p,vec3(0,0,-1),1.0,black),scene);
    
    scene = Union(scene,Sphere(p - vec3(-0.5,-0.75,3.0),0.25,white));
    
    vec3 lensPos = p- vec3(cos(time*0.2)*0.5,sin(time*0.2)*0.5,2.0);
    
    lensPos.xz *= Rotate(time*0.5);
    
    Surface lens = Sphere(lensPos - vec3(0.0,0.0,-0.3),0.5,glass);
    
    lens = Intersect(lens,Sphere(lensPos - vec3(0.0,0.0,0.3),0.5,glass));
    
    scene = Union(scene,lens);
    
    return scene;
}

vec3 Normal(vec3 p)
{
    vec3 off = vec3(0.01,0,0);
    return normalize(vec3(
        Map(p + off.xyz).dist - Map(p - off.xyz).dist,
        Map(p + off.zxy).dist - Map(p - off.zxy).dist,
        Map(p + off.yzx).dist - Map(p - off.yzx).dist
    ));
}
        
Surface TraceRay(vec3 orig,vec3 dir,bool inside)
{
    float curDist = 0.0;
    Surface curSurf;
    for(int i = 0;i < 64;i++)
    {
        curSurf = Map(orig + normalize(dir) * curDist);
        float scDist = inside ? -curSurf.dist : curSurf.dist;
        
        if(scDist < 0.001)
        {
            break;
        }
        
        curDist += scDist;
    }
    
    curSurf.pos = orig + dir * curDist;
    curSurf.norm = Normal(curSurf.pos);
    curSurf.dist = curDist;
    
    return curSurf;
    
}

float PointLightDiffuse(vec3 pos,Surface scene)
{
    return max(0.0,dot(-scene.norm,normalize(scene.pos-pos))) / pow(distance(scene.pos,pos),2.0);
}

void main( void ) {

    vec2 res = resolution/resolution.y;
    vec2 uv = ( gl_FragCoord.xy / resolution.y );
    
    black.type = 1;
    white.type = 1;
    green.type = 1;
    red.type = 1;
    glass.type = 2;
    
    black.col = vec3(0.2);
    white.col = vec3(0.9);
    green.col = vec3(0,0.9,0);
    red.col = vec3(0.9,0,0);
    glass.col = vec3(0.9,1,0.9);
    
    vec3 dir = normalize(vec3(uv-res/2.0,1.0));
    
    vec3 orig = vec3(0,0,-1);
    
    Surface scene = TraceRay(orig,dir,false);
    
    vec3 light = vec3(0.0,0.2,3.0);
    
    vec3 color = vec3(0.0);
    
    if(scene.mat.type == 1)
    {
        color = scene.mat.col;
        color *= PointLightDiffuse(light,scene);
    }
    
    if(scene.mat.type == 2)
    {
        color = scene.mat.col;
        
        float refidx = 0.6;
        
        vec3 refdir = refract(dir,scene.norm,refidx);
        Surface refraction = TraceRay(scene.pos+refdir*0.02,refdir,true);
        
        refdir = refract(dir,-refraction.norm,refidx);
        Surface final = TraceRay(refraction.pos+refraction.norm*0.02,refdir,false);
        
        color *= (final.mat.col * PointLightDiffuse(light,final));
        color *= dot(-dir,scene.norm);
    }
    
    glFragColor = vec4( color, 1.0 );

}
