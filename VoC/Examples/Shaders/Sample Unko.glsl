#version 420

// original https://www.shadertoy.com/view/ttcSRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float sdSphere( vec3 p, float r )
{
    r/=5.0;
  float q1 = length(vec2(length(p.xz)-r,p.y+0.2)) - r;
  float q2 = length(vec2(length(p.xz)-r,p.y+0.5)) - r-0.1;
  float q3 = length(vec2(length(p.xz)-r,p.y+0.8)) - r-0.2;
  

  float q = length(vec2(p.x,p.z));
 // float q4 = p.y>2 ? dot(2,float2(q,p.y-1.2))<0.1 :100000000;

  float q4 =0.0;
    if(p.y>-0.1){
        q4=dot(vec2(2.0,2.0),vec2(q,p.y))-0.1;
    } else {
        q4=10000000.0;
    }

  //return length(q1)<_Threshold || length(q2)<_Threshold-0.1|| length(q3)<_Threshold-0.2 || (dot(2,float2(q,p.y-1.2))<0.1 && p.y>0.8);

  return min(q1, min(q2,min(q3,q4)));
} 

float map(vec3 p)
{
    float d = 2.0;
    for (int i = 0; i < 16; i++)
    {
        float fi = float(i);
        float time = time * (fract(fi * 412.531 + 0.513) - 0.5) * 2.0;
        d = opSmoothUnion(
            sdSphere(p + sin(time + fi * vec3(52.5126, 64.62744, 632.25)) * vec3(2.0, 2.0, 0.8), mix(0.5, 1.0, fract(fi * 412.531 + 0.5124))),
            d,
            0.4
        );
    }
    return d;
}

vec3 calcNormal( in vec3 p )
{
    const float h = 1e-5; // or some other value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*map( p + k.xyy*h ) + 
                      k.yyx*map( p + k.yyx*h ) + 
                      k.yxy*map( p + k.yxy*h ) + 
                      k.xxx*map( p + k.xxx*h ) );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    // screen size is 6m x 6m
    vec3 rayOri = vec3((uv - 0.5) * vec2(resolution.x/resolution.y, 1.0) * 6.0, 3.0);
    vec3 rayDir = vec3(0.0, 0.0, -1.0);
    
    float depth = 0.0;
    vec3 p;
    
    for(int i = 0; i < 64; i++) {
        p = rayOri + rayDir * depth;
        float dist = map(p);
        depth += dist;
        if (dist < 1e-6) {
            break;
        }
    }
    
    depth = min(6.0, depth);
    vec3 n = calcNormal(p);
    float b = max(0.0, dot(n, vec3(0.577)));
    vec3 col = (0.5 + 0.5 * cos((b + time * 3.0) + uv.xyx * 2.0 + vec3(0,2,4))) * (0.85 + b * 0.35);
    col *= exp( -depth * 0.15 );
    
    // maximum thickness is 2m in alpha channel
    glFragColor = vec4(col, 1.0 - (depth - 0.5) / 2.0);
}
