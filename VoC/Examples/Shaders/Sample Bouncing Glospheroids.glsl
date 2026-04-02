#version 420

// original https://www.shadertoy.com/view/7ltSW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int DIST = 0;
const int MAT = 1;

vec2 map(in vec3 p)
{
    vec2 d0 = vec2( dot(p,vec3(0.0,1.0,0.0)), 1.0 );
    vec2 res = d0;
    
    float time = time;
    
    vec3 d1pos = vec3(cos(time)*2.0,abs(sin(time)*4.0)*1.5+0.5,0.0);
    vec2 d1 = vec2( length(p-d1pos)-0.5, 0.0 );
    if (d1[DIST] < res[DIST]) { res = d1; }
    
    time -= 0.4;
    
    vec3 d2pos = vec3(cos(time),abs(sin(time)*4.0)+0.5,0.0);
    vec2 d2 = vec2( length(p-d2pos)-0.5, 0.0 );
    if (d2[DIST] < res[DIST]) { res = d2; }
    
    time -= 0.4;
    
    vec3 d3pos = vec3(cos(time)*0.5,abs(sin(time)*4.0)*0.5+0.5,0.0);
    vec2 d3 = vec2( length(p-d3pos)-0.5, 0.0 );
    if (d3[DIST] < res[DIST]) { res = d3; }
    
    time -= 0.4;
    
    vec3 d4pos = vec3(cos(time)*2.0,abs(sin(time)*4.0)*2.5+0.5,0.0);
    vec2 d4 = vec2( length(p-d4pos)-0.5, 0.0 );
    if (d4[DIST] < res[DIST]) { res = d4; }
    
    time -= 0.4;
    
    vec3 d5pos = vec3(cos(time)*3.5,abs(sin(time)*4.0)+0.5,0.0);
    vec2 d5 = vec2( length(p-d5pos)-0.5, 0.0 );
    if (d5[DIST] < res[DIST]) { res = d5; }
    
    return res;
}

float checkersTexture( in vec2 p )
{
    vec2 q = floor(p);
    return mod( q.x+q.y, 2.0 );            // xor pattern
}

vec3 planeMat(in vec3 ray)
{
    return vec3( checkersTexture(ray.xz)*0.5+0.5 );
}

vec3 calcNormal( in vec3 p )
{
    const float h = 0.01;
    const vec2 k = vec2(1,-1)*0.5773;
    return normalize( k.xyy*map( p + k.xyy*h )[DIST] + 
                      k.yyx*map( p + k.yyx*h )[DIST] + 
                      k.yxy*map( p + k.yxy*h )[DIST] + 
                      k.xxx*map( p + k.xxx*h )[DIST] );
}

vec3 calcColor(in float matID, in vec3 pos)
{
    vec3 mate = vec3(0.0);
    
    if(matID < 0.5) { mate = vec3(1.0); } // sphere
    else if(matID < 1.5) { mate = planeMat(pos); }
    return mate;
}

vec2 raymarch(in vec3 ro, in vec3 rd, out vec3 ray)
{
    float total_dist = 0.0;
    
    for (int i=0; i<100; i++)
    {
        vec3 ray_pos = (rd*total_dist)+ro;
        
        vec2 dist_march = map(ray_pos);
        
        if (dist_march[DIST] < 0.01){
            ray = ray_pos;
            return vec2(total_dist,dist_march[MAT]);
        }
        
        if (dist_march[DIST] > 100.0){
            break;
        }
        
        total_dist += dist_march[DIST];
    }
    
    ray = vec3(-1.0);
    return vec2(-1.0);
}

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}

int AO_SAMPS = 20;
float ao(in vec3 pos, in vec3 normal, in vec2 screenuv)
{
    vec3 tn = normalize(cross(normal,vec3(0.0,1.0,0.0)));
    vec3 bitn = normalize(cross(tn,normal));
    
    float occ = 0.0;
    for (int i=0;i<AO_SAMPS;i++)
    {
        vec2 aa = hash22(screenuv*float(i+1)+time);
        float ra = sqrt(aa.y);
        float rx = ra*cos(6.2831*aa.x);
        float ry = ra*sin(6.2831*aa.x);
        float rz = sqrt(1.0-aa.y);
        vec3 dir = vec3(tn*rx + bitn*ry + rz*normal);
        vec3 y;
        occ += step(0.0,raymarch(pos+dir*0.3, dir, y)[DIST]);
    }
    return occ/float(AO_SAMPS);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec3 ro = vec3(0.0,1.0,-6.0);
    //ro.y = abs(cos(time)*1.0)+1.0;
    vec2 uvrd = (uv-0.5)*3.0;
    uvrd.y *= resolution.y/resolution.x;
    //float yes = (uvrd.x*uvrd.x)+(uvrd.y*uvrd.y);
    //uvrd *= 1.0 + yes * 0.5;
    
    vec3 rd = vec3(uvrd,1.0);
    rd = normalize(rd+vec3(0.0,abs(sin(time)*0.4)+0.1,0.0));
    
    vec3 ray;
    vec2 rayr = raymarch(ro,rd,ray);
    
    vec3 color = vec3(0.0);
    color = calcColor(rayr[MAT],ray);
    
    vec3 normal = calcNormal(ray);
    color *= ao(ray,calcNormal(ray),gl_FragCoord.xy)*3.0;
    
    
    color *= exp(rayr[DIST]*-0.1);
    if (rayr[DIST] < 0.0) { color = vec3(0.0); }
    
    glFragColor = vec4(vec3( color ),1.0);
}
