#version 420

// original https://www.shadertoy.com/view/WsXcWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 pos, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    
    return mat2(c,s,-s,c) * pos;

}

float plane(vec3 pos)
{    
    
    vec3 q = pos;
    
    return q.y;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCross( in vec3 p)
{
  float inf = 12000.;
  float da = sdBox(p.xyz,vec3(inf,1.,1.));
  float db = sdBox(p.yzx,vec3(1.,inf,1.));
  float dc = sdBox(p.zxy,vec3(1.,cos(time),inf));
  return min(da,min(db,dc));
}

float sphere(vec3  pos, float radius)
{    
    pos.y -= 4.0;
    return length(pos) - radius;
}

float map(vec3 pos)
{
    float planeDist = plane(pos);   

    //float d2 = sdBox(pos - 2., vec3(2.0));
    
    pos.x = abs(pos.x) - 1.;
    pos.y = abs(pos.y) - .5;
    
    pos.x += sin(time);
    
       pos.xy = rotate(pos.xy,  time * .05);
    pos.xz = rotate(pos.xz, time * .05);
    pos.yz = rotate(pos.yz,  time * 1.05);
    
    
    float d2 = sdCross(pos);
    float d = sdBox(pos,vec3(2.0));
       float c = sdCross(pos*2.0)/2.0;
           
    pos.xy = rotate(pos.xy, time * .5);
    pos.xz = rotate(pos.xz, time * .5);
    pos.yz = rotate(pos.yz, time * .5);
    
    //d = max( d, -c );
    float s = 1.;
    for( int m=0; m<12; m++ )
       {
      vec3 a = mod( pos*s, 2.0 )-1.0;
      s *= 5.0;
      vec3 r = 2.0 - 5.0*abs(a);

      float c = sdCross(r)/s;
      d = max(d, -c);
       }
    
    
    
    return d;
    
}

float castRay(vec3 ro, vec3 rd)
{
    float t = 0.0;
    for(int i = 0; i < 100; i++)
    {
        vec3 pos = ro + t * rd;
        
        float h = map(pos);
        if(h < 0.001)
        {
            break;
        }
        t += h;
        
        if(t > 100.0) break;
        
    }
    
    if(t > 100.0) t = -1.0;
    
    return t;
}

vec3 computeNormal(vec3 pos)
{
    vec2 eps = vec2(0.1, 0.0);
    return normalize(vec3(
        map(pos + eps.xyy) - map(pos - eps.xyy),
        map(pos + eps.yxy) - map(pos - eps.yxy),
        map(pos + eps.yyx) - map(pos - eps.yyx)
    ));
}

vec3 material(vec3 pos)
{
    return vec3(smoothstep(0.4, 0.41, fract(pos.x + sin(pos.z * 0.4 + time))));
}

void main(void)
{
     vec2 mouse = mouse*resolution.xy / resolution.xy;
    
    vec2 uv = (gl_FragCoord.xy -.5 * resolution.xy) / resolution.y;
       //uv.x = abs(uv.x * .5); 
    float angle = time;
    
    vec3 ro = vec3(0.0, 0.0, -8.);
    
    // Rayon que l'on envoie dans l'espace pour chacuns des pixels
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));    
    
    

     vec3 col = vec3(0.4, 0.75, 1.0) - 0.7 * rd.y;
               
    float t = castRay(ro, rd);

        if(t > 0.)
        {

            vec3 pos = ro + t * rd;
            vec3 nor = computeNormal(pos);
            vec3 sunPosition = vec3(5., 1., 1.);
            vec3 sundir = normalize(sunPosition);
            vec3 mate = vec3(.18);

               float sundif =   clamp(dot(nor, sundir), -1.0, 1.0);
            float sun_sha = smoothstep(castRay(pos + nor * 0.001, sundir), 0.0, 1.0);
            float sky_dif = clamp(0.5 + 0.5 * dot(nor,vec3(3.0,1.0,0.0)), 0.0, 1.0);
            float bou_dif = clamp(0.5 + 0.5 *dot(nor,vec3(0.0,-1.0,0.0)), 0.0, 1.0);

            col = mate * vec3(t * 0.5, t * 0.25, 1.0) * sundif * sun_sha;
            col += mate * vec3(0.75, 0.8, 0.9) * sky_dif;
            col += mate * vec3(0.75, 0.3, 0.2) * bou_dif;
        }

    
    
    // Output to screen
    glFragColor = vec4(sqrt(col), 1.0);
}
