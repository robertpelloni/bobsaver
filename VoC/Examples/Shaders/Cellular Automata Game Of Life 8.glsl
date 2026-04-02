#version 420

// original https://neort.io/art/bpit5843p9fbkbq82usg

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;
#define tile 2.
#define tau (2.*3.141592653589793238462643383279)

void main( void ) {
    vec2 uv = gl_FragCoord.xy / resolution;
    vec2 p = (2.*gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.,(1.-uv.x)*.2+.1*sin(time),(1.-uv.y)*.5+.3*cos(time));
    
    float ln = 0.;
    
    vec3 col1 = vec3(.7+.3*sin(time*.2),.2+.2*sin(uv.x*10.+time),.2+.2*sin(uv.y*10.+time));
    
    vec2 tiling = resolution/tile;
    
    vec2 i = floor(uv*tiling+.5)/tiling;
    
    ln += texture2D(backbuffer, i + vec2(-1./tiling.x,-1./tiling.y)).r>.1?1.:0.;
    ln += texture2D(backbuffer, i + vec2( 0./tiling.x,-1./tiling.y)).r>.1?1.:0.;
    ln += texture2D(backbuffer, i + vec2( 1./tiling.x,-1./tiling.y)).r>.1?1.:0.;
    ln += texture2D(backbuffer, i + vec2(-1./tiling.x, 0./tiling.y)).r>.1?1.:0.;
    ln += texture2D(backbuffer, i + vec2( 1./tiling.x, 0./tiling.y)).r>.1?1.:0.;
    ln += texture2D(backbuffer, i + vec2(-1./tiling.x, 1./tiling.y)).r>.1?1.:0.;
    ln += texture2D(backbuffer, i + vec2( 0./tiling.x, 1./tiling.y)).r>.1?1.:0.;
    ln += texture2D(backbuffer, i + vec2( 1./tiling.x, 1./tiling.y)).r>.1?1.:0.;
    
    bool h = texture2D(backbuffer, i).r>.1?true:false;
    
    color = (h && (ln == 2. || ln == 3.)) || (!h && ln == 3.) ? col1 : color;
    
    
    vec2 dp = (2.*floor(gl_FragCoord.xy/tile+.5) - tiling) / min(tiling.x, tiling.y);
    float a = atan(dp.y,dp.x)/tau;
    float kt = .5*time;
    float r = 1. + sin(tau*fract(a+kt)) + .5*sin(tau*fract(2.*a+.5234*kt)) + .25*sin(tau*fract(4.*a+.4526*kt));
    color = length(dp)<.25*r ? col1 : color;
    
    
    glFragColor = vec4(color, 1.);
}
