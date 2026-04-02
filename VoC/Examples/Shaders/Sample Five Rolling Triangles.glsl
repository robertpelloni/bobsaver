#version 420

// original https://www.shadertoy.com/view/4tVfDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 R;
float t, PI=3.14159;

#define wrap(a) ( mod( 3.*a +PI, 2.*PI ) - PI ) /3.
#define ofs(t)    2.* cos( wrap(t) )
#define S(v)      smoothstep( 0., 9./R.y, v )

float tri(float x, float y) {
    float a = atan(y,x) - t, l = length(vec2(x,y));
    a = wrap(a); // U = l * cos(a - vec2(0,1.57) );
    return S( .5 - l*cos(a) ); 
}

void main(void) //WARNING - variables void ( out vec4 O, vec2 U ) need changing to glFragColor and gl_FragCoord
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;

    R = resolution.xy;
    t = time;

    U = 3.* ( U+U - R ) / R.y;
    float x = U.x, y = U.y;
    
    O-=O;
    O.gb += tri(  x            , y  );               // center
    O.rb += tri(  ofs(t+PI) -x , y  );               // right
    O.rg += tri( -ofs(t)    -x , y  ) * vec2(1,.5);  // left
    O.rg += tri(  x ,  ofs(t-PI/2.) -y  );           // top
    O.g  += tri(  x , -ofs(t+PI/2.) -y  );           // bottom

    glFragColor = O;
}
