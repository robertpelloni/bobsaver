#version 420

// original https://www.shadertoy.com/view/WtyGDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define box(p,s)       length(max(abs(p)-(s),0.))
#define sphere(p,s)  ( length(p)-(s) )   
#define rot(a)         mat2(cos(a),-sin(a),sin(a),cos(a))

float trace (vec3 o, vec3 r)
{
      float t = 0.0;
      for(int i = 0;i < 100;i++)
      {
          vec3 p = o+r*t,
               q = fract(p)*2.-1.;

          float d0 = box(q,.45),
                d1 = sphere(q,mix( .6, .73, sin(time*.35) *.5 + .5 ) ),
                 d = max(-d1,d0);
          t += d*.13;
      }
      return t;
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = glFragColor;

    vec2 R = resolution.xy,
        uv = (u- .5*R) / R.y;
     uv.x += ( sin(uv.y*12.+time*.1) *.5 + .5 ) / 10.;

      vec3 o = -time*0.25/4.*vec3(1,0,1),
         r = normalize(vec3(uv,1));
    r.xz *= rot(8.65); 
    r.xy *= rot(time*.25); 
      float t = trace(o,r), 
          fog = 1./(1.+t*t*.75);

    O = ( fog+vec4(0,0,.2,0) )  * vec4(0,.8,1.6, 0);
    glFragColor = O;
}
