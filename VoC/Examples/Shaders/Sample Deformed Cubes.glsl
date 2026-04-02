#version 420

// original https://www.shadertoy.com/view/WtKSDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//thanks IQ ! http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
//thanks for Poulet_vert tutorial

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere(vec3 p, float s){
 return length(p)-s;   
}

float Union (float d1,float d2){ return min (d1,d2);}
float Substract (float d1,float d2){ return max (-d1,d2);}

vec3 opRepet(vec3 pos,vec3 bound){
    return mod(pos+0.5*bound,bound)-0.5*bound;
}

float map(vec3 pos){
    
    pos = opRepet(pos, vec3(3.0,0.0,3.0));
    
    float cube = sdBox( pos, vec3(1.0));
    float sphere = sdSphere(pos, 1.3);
        
    return Substract(sphere,cube);
    
}

float castRay(vec3 ro, vec3 rd ){
    
    float c = 0.0;
    
    for(int i = 0; i < 64; i++){
     float ray = map(ro + rd *c);
        
        if(ray < (0.0001*c))
        {
            return 1.0-float(i)/32.0;
        }
        
        c+= ray;
        
        
    }
    
    
    return -1.0;
}

vec3 render(vec3 ro, vec3 rd){
    float contact = castRay(ro,rd);
    
    vec3 col = vec3(0.0,1.0,0.0);
    
    if(contact == -1.0)
    {
        col = vec3(0.0,0.0,0.0);
    }
    else
    {
        col = vec3(contact);
    }
    
    return col;
}

void main(void)
{

    vec2 uv = gl_FragCoord.xy/resolution.xy*2.0-1.0;
    uv.x *=resolution.x/resolution.y;
    
    //cam
    vec3 camePos = vec3 (sin(time)*2.0,0.0,4.9-time);
    vec3 camTarget =vec3 (0.0,0.0,-time);
    
    //vec dir camera
    vec3 forward = normalize(camTarget-camePos);
    
    vec3 right = normalize(cross(vec3(0.0,-1.0,0.0),forward));
    vec3 up = normalize(cross(cos(right+1.0)*0.5,forward));
    
    vec3 viewDir = normalize (uv.x * right + uv.y * up +2.0*forward);
    viewDir = vec3(viewDir.x,viewDir.y,viewDir.z);

    vec3 col = render(camePos,viewDir);
    
    col.x *= uv.y*2.0;

    glFragColor = vec4(col,1.0);
}
