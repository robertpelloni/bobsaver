#version 420

// original https://www.shadertoy.com/view/tlKGzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318

mat2 rot(float a)
{
    float ca = cos(a);
    float sa = sin(a);
    return mat2(ca,-sa,sa,ca);
}

vec2 spiralize(vec2 uv)
{
    float len = length(uv);
    
    uv *= 128.;
    float r = .045;
    mat2 mr = rot(r);
    
    float a;
    float acc = 1.;
    
    a = atan(uv.y, uv.x) / TAU + .5;
    a = fract(a + time * .05);
    
//    a *= (sin( time) * .5 + .5);
    uv *= 1. - a * .50;
  
    for(int i = 0; i < 7; ++i)
    {
        
        if(abs(uv.x) < 1. && abs(uv.y) < 1.)
//        if(length(uv) < 1.)
        {
            break;
        }
        
        uv *= .5;
        
        /*
        uv.x += 1.;
        uv *= mr;
        uv.x -= 1.;
        */
    }
    
    return uv;
}

float fbm(vec2 p)
{
  mat2 m = mat2(.8,-.6,.6,.8);
  float acc = 0.;
  p *= -m * m * .5;
  for(float i = 1.; i < 6.; ++i)
  {
    p += vec2(i * 12.675, i * 65.457) + vec2(time * .15);
    p *= m;
    acc += (sin(p.x * i) + cos(p.y * i)) * 1./(i * .5);
  }

  return acc;
}

float sdCube(vec3 p)
{
  vec3 q = abs(p) - vec3(1.);
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map(vec3 p)
{
    vec3 cp = p;
    
    
    float dist = p.y + fbm(p.xz *1.5) * .1 + 3.;
    
    p = cp;
    
    p.xy *= .515;
    float cu = sdCube(p) - .1;
    
    dist = min(dist,cu);
    
    p = cp;
    
    float r = 4.;
    p.xz = mod(p.xz + r *.5, r) - r * .5;
    p.y -= 20.;
    cu = sdCube(p);
    dist = min(dist,cu);
    
    return dist;
}

float ray(vec3 ro, vec3 rd, out float st)
{
    float cd = 0.;
    float FAR = 100.;
    for(st = 0.; st < 1.; st += 1. / 100.)
    {
        float d = map(ro + rd * cd);
        if(abs(d) < .01)
            break;
        cd += d * .85;
    }
    
    return cd;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5)/resolution.y;
    
     uv = spiralize(uv);
    
    float f = max(abs(uv.x),abs(uv.y));
    f = smoothstep(.0,0.05, abs(f - 1.));
    //f = mouse*resolution.xy.z < 0. ? 1. : f;
    
    vec3 ro = vec3(0.,0.,-5.);
    vec3 rd = normalize(vec3(uv, 1.));
    float st;
    float dist = ray(ro, rd, st);
    
    vec3 col = vec3(1. - st);
    if(st < 1.)
    {
        vec3 cp = ro + rd * dist;
        vec3 lp = vec3(4. * sin(time *.25),3. + 1.* cos(time * .125),-5. );
        vec3 ld = normalize(lp - cp);
        cp += ld * .1;
        float ldist = ray(cp, ld, st);
        
        if(ldist < length(cp - ld))
        {
            col *= .25;
        }
    }
    
    uv = (uv +1.) * .5;
    // col = texture(iChannel0,uv).rgb;
    
    glFragColor = vec4(col, 0.) * f;
}
