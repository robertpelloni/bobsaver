#version 420

// original https://www.shadertoy.com/view/McVSDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 palette(float t) 
{
    return .5+.5*cos(6.28318*(t+vec3(.3,.416,.557)));
}

float sdBoxFrame( vec3 p, vec3 b, float e, float scale  )
{
       p *= scale;
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e; 
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float repeat = 1.0;

float map(vec3 p) {
    p.z += abs((time)) * .4; 
    
    p = mod(p, repeat) - repeat * 0.5;
   
    return sdBoxFrame(p, vec3(0.3,0.2,0.3), 0.025, 1.05);
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(.001, 0);
    vec3 n = map(p) - 
        vec3(map(p-e.xyy), map(p-e.yxy),map(p-e.yyx));
    
    return normalize(n);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;
    vec2  m = (mouse*resolution.xy.xy * 2. - resolution.xy) / resolution.y;
    
    m = vec2(cos(time*.2), sin(time*.2));

    vec3 ro = vec3(0, 0, -3);         
    vec3 rd = normalize(vec3(uv, 1)); 
    vec3 col = vec3(0);               

    float t = 0.; 

    vec3 p;
    float i; 
    for (i = 0.; i < 80.; i++) {
        p = ro + rd * t; 
        
        p.xy += m.xy * 4.;
        //p.y += sin(t*time*.0005)*.5; 

        float d = map(p);     

        t += d;              

        if (d < .001 || t > 100.) break; 
    }
    
     vec3 n = GetNormal(p);
     vec3 r = reflect(rd, n);

    float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;

    col = palette(t*.04 + float(i)*.005);
    col *= dif * (i) / 40.;
    col = pow(col, vec3(.4545));    // gamma correction

    glFragColor = vec4(col, 1);
}