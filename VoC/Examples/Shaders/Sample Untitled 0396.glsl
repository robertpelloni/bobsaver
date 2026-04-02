#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const  float EPS =0.00001;

vec3 lightDir = normalize(vec3(-0.1,0.2,-0.4));

float dist_func(vec3 pos, float size)
{
    
    return length(pos) -size;
}

vec3 onRap(vec3 p, float interval){
    return mod(p,interval)-interval * 0.5;
}

float distScene(vec3 p){
    return dist_func(onRap(p,0.3),0.1);
    }

vec2 onRep(vec2 p , float interval)
{
    return mod(p,interval)-interval*0.5;
}

float barDist(vec2 p ,float interval, float width)
{
    return length(max(abs(onRep(p,interval)) - width,0.0));
}

float sceneDist1(vec3 p){
    float bar_x = barDist(p.yz,1.0,0.1);
    float bar_y = barDist(p.xz,1.0,0.1);
    float bar_z = barDist(p.xy,1.0,0.1);
    return min(min(bar_x,bar_y),bar_z);
}

float tubeDist(vec2 p,float interval,float width){
    return length(onRep(p,interval)) - width;
}
float sceneDist2(vec3 p){
    float tube_x = tubeDist(p.yz,0.1,0.02);
    float tube_y = tubeDist(p.xz,0.1,0.02);
    float tube_z = tubeDist(p.xy,0.1,0.02);
    return min(min(tube_x,tube_y),tube_z);
}

float sceneDist0(vec3 p){
    
    return min(-sceneDist1(p),sceneDist2(p));
}

vec3 getNormal(vec3 pos)
{
    float ep = 0.0001;
    return normalize(vec3(
        
            sceneDist0(pos) - sceneDist0(vec3(pos.x - ep, pos.y, pos.z)),
            sceneDist0(pos)- sceneDist0(vec3(pos.x, pos.y - ep, pos.z)),
            sceneDist0(pos) - sceneDist0(vec3(pos.x, pos.y, pos.z - ep))
        ));
}
                    
mat2 rotZ(float t){
    float c=cos(t),s=sin(t);
    return mat2(c,s,-s,c);
}
void main( void ) {

    vec2 pos = ( gl_FragCoord.xy * 2.0 - resolution.xy ) / min(resolution.x,resolution.y);
    pos*=rotZ(sin(time));
    vec3 col = vec3(0.0);
    vec3 cameraPos = vec3(0.0,0.0,-5.0);
    vec3 cDir= vec3(0.0,0.0,-1.0);
    vec3 cUp = vec3(0.3,1.0,0.0);
    vec3 cSide = cross(cDir,cUp);
    float targetDepth = 1.0;
    vec3 ray = normalize(cSide * pos.x + cUp*pos.y + cDir * targetDepth);
    vec3 cur = cameraPos;
    
    float size = 0.2 ;
    float dist,depth = 0.0;
    vec3 origin = cur;
    origin.z += time*0.3;
    
    vec3 p = origin;
    
    
    
    for(int i = 0;i < 64;i++)
    {
        
        dist = sceneDist0(p);
        depth += dist;
        p=origin + depth * ray;
        if(abs(dist)<EPS)
        {
            vec3 normal = getNormal(p);
            float diff = dot(normal,lightDir);
            col = vec3(diff) + vec3(0.8);
            break;
        }
        
    }
    
    

    glFragColor = vec4(col, 1.0 );
}
