#version 420

// original https://www.shadertoy.com/view/lssfWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float time2 = 0.1;
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

 mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

float map(vec3 p)
{

    vec3 q = p;

    float rep = 0.1;
    vec3 c = vec3(rep);
    p.z = mod(p.z,c.z)-0.5*c.z;

    
    vec3 p_s;
    p = p * rotationMatrix(vec3(0.0, 0.0, 1.0), sin(q.z  +time2) + sin(time2/10.0));

    float inner = 1000.0;
    float outer = 1000.0;
    
    
    int sides = 5;
    float angle = 3.1415 * 2.0 / float(sides);
    
    for ( int i = 0; i < sides; i ++)
    {
        
        p_s = p * rotationMatrix(vec3(0.0, 0.0, 1.0), angle * float(i));
        
           p_s += vec3(
            cos(q.z)* 2.0,
            sin(q.z)* 2.0,
            -0.0);
            
       // p_s = p_s * rotationMatrix(vec3(0.0, 0.0, 1.0), 4.0 * angle * float(i));
        
        float rad = cos(q.z* 1.0 - time2) * 0.5 + 0.6;
        
        outer = min(outer, length(p_s) - rad);  
        
        vec3 p_fac = p_s.yxz;
        
        p_fac += vec3(
            sin(time2 + q.z)* 0.4 , 
            cos(q.z)* 0.9 , 
            0.1 * sin(q.z));
        
        float tt = 0.01 * sin(q.z * 10.0 + time2 * 10.0) + 0.01;
        float facet = sdCylinder(p_fac, vec3(sin(q.z), tt, tt));
            

        inner = min(inner, facet);  
    
        
    }
    
    float result = min(outer, inner);   
    return result;
}

void getCamPos(inout vec3 ro, inout vec3 rd)
{
    ro.z = time2;

}

 vec3 gradient(vec3 p, float t) {
            vec2 e = vec2(0., t);

            return normalize( 
                vec3(
                    map(p+e.yxx) - map(p-e.yxx),
                    map(p+e.xyx) - map(p-e.xyx),
                    map(p+e.xxy) - map(p-e.xxy)
                )
            );
        }

void main(void)
{
    time2 = time * 0.5;
    vec2 _p = (-resolution.xy + 2.0*gl_FragCoord.xy) / resolution.y;
    vec3 ray = normalize(vec3(_p, 1.0));
    vec3 cam = vec3(0.0, 0.0, 0.0);
    bool hit = false;
    getCamPos(cam, ray);
    
    float depth = 0.0, d = 0.0, iter = 0.0;
    vec3 p;
    
    for( int i = 0; i < 80; i ++)
    {
        p = depth * ray + cam;
        d = map(p);
                  
        if (d < 0.001) {
            hit = true;
            break;
        }
                   
        depth += d * 0.5 ;
        iter++;
                   
    }
    
    vec3 col = vec3(1.0 - iter / 80.0);

    if(hit)
    col = pow(col, vec3(
        0.2 + 0.5 * sin(p.z * 33.0),
        0.7 + 0.5 * sin(p.z * 10.0),
        0.6)).bgr;
    
    glFragColor = vec4(sqrt(col), hit? length(p.xy) : 0.0 );
    
}
