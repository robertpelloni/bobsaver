#version 420

// original https://www.shadertoy.com/view/llKczz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float min3(float a,float b,float c){return min(min(a,b),c);}
float min4(float a,float b,float c,float d){return min(min(a,b),min(c,d));}
float min8(float a,float b,float c,float d,float e,float f,float g,float h){return min(min4(a,b,c,d),min4(e,f,g,h));}

float noise(float t)
{
    return fract(sin(t*124.1231)*432.423432)*.15+.1;
}

float scene(vec3 p)
{
    float t=floor(time*4.);
    float r1 = noise(t+.1);
    float r2 = noise(t+.2);
    float r3 = noise(t+.3);
    float r4 = noise(t+.4);
    float r5 = noise(t+.5);
    float r6 = noise(t+.6);
    float r7 = noise(t+.7);
    float r8 = noise(t+.8);
    return min8(
        sdBox(p+vec3( .2, .2, .2),vec3(r1)),
        sdBox(p+vec3( .2, .2,-.2),vec3(r2)),
        sdBox(p+vec3( .2,-.2, .2),vec3(r3)),
        sdBox(p+vec3( .2,-.2,-.2),vec3(r4)),
        sdBox(p+vec3(-.2, .2, .2),vec3(r5)),
        sdBox(p+vec3(-.2, .2,-.2),vec3(r6)),
        sdBox(p+vec3(-.2,-.2, .2),vec3(r7)),
        sdBox(p+vec3(-.2,-.2,-.2),vec3(r8))
    );
    
    return max(
        sdBox(p,vec3(.5)),
        -min3(
            sdBox(p,vec3(.6,.3,.3)),
            sdBox(p,vec3(.3,.6,.3)),
            sdBox(p,vec3(.3,.3,.6))
        )
    );
}

vec2 rotate(vec2 a, float b)
{
      float c = cos(b);
      float s = sin(b);
      return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
      );
}

void main(void)
{
      vec2 uv = (gl_FragCoord.xy / resolution.xy) - .5;
      uv.x *= resolution.x / resolution.y;

    vec3 cam = vec3(0,0,-10);
    vec3 dir = normalize(vec3(uv, 7));

    cam.yz = rotate(cam.yz, sin(time*.5)*.5+.5);
    dir.yz = rotate(dir.yz, sin(time*.5)*.5+.5);

    cam.xz = rotate(cam.xz, time*.5);
    dir.xz = rotate(dir.xz, time*.5);
    
    float t = 0.;
    float k = 0.;
    for (int i = 0; i< 100; ++i)
    {
        k = scene(cam + dir * t);
        t += k;
        if(k < .001)
            break;
    }
    vec3 h = cam + dir * t;

    vec2 o = vec2(.001, 0);
    vec3 n = normalize(vec3(
        scene(h+o.xyy)-scene(h-o.xyy),
        scene(h+o.yxy)-scene(h-o.yxy),
        scene(h+o.yyx)-scene(h-o.yyx)
    ));

    const float aoMaxDist = .1;
    float aoDist = scene(h+n*aoMaxDist);
    aoDist = max(0.,aoDist);
    float ao = pow(aoDist/aoMaxDist, .7)*.15+.85;
    
    float light = smoothstep(-1.,1.,dot(n,normalize(vec3(1,2,3))))*.15+.85;
    glFragColor = vec4(k < .001 ? ao * light : 1.);
}
