#version 420

// original https://www.shadertoy.com/view/tdtXWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// cleanup by https://www.shadertoy.com/user/FabriceNeyret2
float rand(vec2  n){ return fract(sin(n.x*11.+n.y*17.) * 43758.5453123);}
float rand(float n){ return fract(sin(n)               * 43758.5453123);}

float sdRoundBox( vec2 p, vec2 b, float r )
{
  vec2 q = abs(p) - b;
  return length(max(q,0.)) + min(max(q.x,q.y),0.) - r;
}

void main(void) //WARNING - variables void ( out vec4 O, vec2 u ) need changing to glFragColor and gl_FragCoord
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = vec4(0);
    vec2  R = resolution.xy,
          U = ( u - R*.5 ) / R.y;
    float t = -time;
    for(float i = 0. ; i < 1. ; i += .2) {
        float u = fract(t*.125+i),
              q = rand(i+10.)*9. + u*2. + sin(t*.3)*2.;
        vec2  P = U *u*90. * mat2(cos(q), -sin(q), sin(q), cos(q)),
              f = 2.*fract(P)-1.;
        float rn = rand(floor(P)),
              c = pow( abs(sin( (time*.04+rn)*3.14159 )) ,32. ),
              s = smoothstep(.1, .01, length(f) - c);
        O = max(O, vec4( 1,1, .2*c, 1 ) *s*(1.-u) );
    }

    glFragColor = O;
}
