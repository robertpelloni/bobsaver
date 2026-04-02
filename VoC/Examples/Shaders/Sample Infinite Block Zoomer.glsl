#version 420

// original https://www.shadertoy.com/view/md33D2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://twitter.com/zozuar/status/1631115224827691009?s=20

mat2 Rotate(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

void main(void)
{     

    float t = time;
    vec3 p,q,d;
    vec4 o;
    d.zx =(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;d.y--;
    d *= rotate3D(.2,hsv(t/4.,9.,p.y+=.13));
    
    for(
        float i,j,e,S;
        i++ < 90.;
        i > 70. ? e += 2e-4, d/=d, o : o += .01/exp(e*1e4), p += d*e*.6
     ) for(
             j = e = p.y;
             j++ < 8.;
             e = min(e,length(q - clamp(q, -.2, .2))/S)
         )
             q = p*(S=exp2(j-fract(t))),
             q.xz = fract(q.xz)-.5;
             o += log(p.y)*.05;
    
         
    glFragColor = vec4(o.x + (p.y*.05), o.y, o.z + p.x, 1.);
}
