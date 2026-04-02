#version 420

// original https://www.shadertoy.com/view/lcXfW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Thanks IQ for the following three functions
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdEgg( in vec2 p, in float ra, in float rb )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x);
    float r = ra - rb;
    return ((p.y<0.0)       ? length(vec2(p.x,  p.y    )) - r :
            (k*(p.x+r)<p.y) ? length(vec2(p.x,  p.y-k*r)) :
                              length(vec2(p.x+r,p.y    )) - 2.0*r) - rb;
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

void main(void)
{
   vec2 uv = ( gl_FragCoord.xy - .5* resolution.xy ) /resolution.y;
   vec3 col = vec3(0.);   
   float tt = fract(.5*time);
 
   float numCol = 10.;       
   uv *= numCol;
   float cellID = floor(uv.x);
   float tOff = fract(324.6*sin(46.7*cellID));
   float t = fract(tt + tOff); 
   uv.x = fract(uv.x) - .5;        
   float box = sdBox(uv - vec2(0,numCol/2.), vec2(1.0,1.4));
   float box2 = sdBox(uv- vec2(0,-numCol/2.), vec2(1.0,1.4));  
   float startPos = numCol/2.4;
   float endPos = numCol;
   float drop = sdEgg(uv - vec2(0.,startPos-endPos*fract(t*t)),.4,.2);
   float circ_box = opSmoothUnion(box, drop, .2);
   circ_box = opSmoothUnion(box2, circ_box, .5);
   col += .02/abs(circ_box);    
   glFragColor = vec4(col,1.0);
} 
