#version 420

// original https://www.shadertoy.com/view/3lsSzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*---------------------------------------------------------------
I dare not comment anything in this one, yet. But in case someone 
believes I know what I'm doing and wants to know it, too, 
just let me know!
---------------------------------------------------------------*/
float sphere(vec3 p, float radius)
{
  return length(p)-radius;
}
float box(vec3 p, vec3 c)
{
  vec3 q = abs(p)-c;
  return min(0.,max(q.x,max(q.y,q.z))) + length(max(q,0.));
}

float map(vec3 p)
{
  float pz = p.z;
  p.x += sin(p.z+time);
  p.y += cos(p.z+time);
  p = mod(p,2.)-1.;
  //return max(box(p,vec3(0.25)),-sphere(p,0.35+sin(time)*0.05));
  return mix(box(p,vec3(0.25)),sphere(p+vec3(cos(time)*.25,0.,sin(time)*0.05),.3+.25*sin(time*1.5)*0.5),sin(pz*3.33+time*.05));
}

vec3 getNormal(vec3 p)
{
  vec2 o = vec2(0.001, 0.);
  return normalize(vec3(  map(p+o.xyy)-map(p-o.xyy),
                          map(p+o.yxy)-map(p-o.yxy),
                          map(p+o.yyx)-map(p-o.yyx)));
}

vec3 lighting(vec3 n, vec3 light)
{
    float lit = dot(n, light);
    float sub = max(0.,0.5+0.5*lit);
    vec3 col = vec3(max(0.,lit))+sub*vec3(0.4,0.1,0.1);
    return col;
}

void main(void)
{
     float time = time;
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec3 ro = vec3(sin(time*1.45)*0.1,5.*(cos(time*0.25)),time);
    vec3 p = ro;
    vec3 rd = vec3(uv.xy*(0.5+1.5*length(uv.xy)),0.5);
    rd = normalize(rd);

    vec3 light = normalize(vec3(sin(time), cos(time), sin(time*0.25)));
    vec3 bgColor = mix(vec3(0.7,0.2,0.6),vec3(0.1,0.05,0.2),length(uv));

    bool hit = false;
    float shading = 0.;
    vec3 color = bgColor;
    
    rd *= 0.25;
    int i = 0;
    p+=vec3(uv.xy,1.);
    float dd;
    while(i<100)
    {
        float d = map(p);
        if(d<0.01)
        {
            hit = true;
            p-=rd*dd;
            rd *=0.1;
        }
        dd = d;
        p+=rd*d;
          i++;
     }

    if(hit)
    {
        vec3 norm = getNormal(p);
        float fog = min(1.0, 0.09*length(p-ro));
        color = mix(lighting(norm, light),bgColor,fog);
    }
    // Output to screen
    glFragColor = vec4(color,1.0);
}
