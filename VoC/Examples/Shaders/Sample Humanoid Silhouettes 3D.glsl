#version 420

// original https://www.shadertoy.com/view/MdtfDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cheap 2D humanoid SDF for dropping into scenes to add a sense of scale.
// Hazel Quantock 2018
// This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. http://creativecommons.org/licenses/by-nc-sa/4.0/

float RoundMax( float a, float b, float r )
{
    a += r; b += r;
    
    float f = ( a > 0. && b > 0. ) ? sqrt(a*a+b*b) : max(a,b);
    
    return f - r;
}

float RoundMin( float a, float b, float r )
{
    return -RoundMax(-a,-b,r);
}

// Humanoid, feet placed at <0,0>, with height of ~1.8 units on y
float Humanoid( in vec2 uv, in float phase )
{
    #define Rand(idx) fract(phase*pow(1.618,float(idx)))
    float n3 = sin((uv.y-uv.x*.7)*11.+phase)*.014; // "pose"
    float n0 = sin((uv.y+uv.x*1.1)*23.+phase)*.007;
    float n1 = sin((uv.y-uv.x*.8)*37.+phase)*.004;
    float n2 = sin((uv.y+uv.x*.9)*71.+phase)*.002;
    //uv.x += n0+n1+n2; uv.y += -n0+n1-n2;
    
    float head = length((uv-vec2(0,1.65))/vec2(1,1.2))-.15/1.2;
    float neck = length(uv-vec2(0,1.5))-.05;
    float torso = abs(uv.x)-.25;
    //torso += .2*(1.-cos((uv.y-1.)*3.));
    //torso = RoundMax( torso, abs(uv.y-1.1)-.4, .2*(uv.y-.7)/.8 );
    torso = RoundMax( torso, uv.y-1.5, .2 );
    torso = RoundMax( torso, -(uv.y-.5-.4*Rand(3)), .0 );

    float f = RoundMin(head,neck,.04);
    f = RoundMin(f,torso,.02);
    
    float leg =
        Rand(1) < .3 ?
        abs(uv.x)-.1-.1*uv.y : // legs together
        abs(abs(uv.x+(uv.y-.8)*.1*cos(phase*3.))-.15+.1*uv.y)-.05-.04*Rand(4)-.07*uv.y; // legs apart
    leg = max( leg, uv.y-1. );
    
    f = RoundMin(f,leg,.2*Rand(2));
    
    f += (-n0+n1+n2+n3)*(.1+.9*uv.y/1.6);
    
    return max( f, -uv.y );
}

// return: distance to intersection, sdf value (negative = solid)
vec2 StandIn( in vec3 footPos, in float seed, in vec3 rayStart, in vec3 rayDir )
{
    footPos -= rayStart; // do everything relative to rayStart
    
    // construct a vertical plane through footPos, facing the camera
    vec3 n = normalize( vec3(1,0,1)*footPos );
    float d = dot(n,footPos);
    
    float intersectionDistance = d/dot(n,rayDir);
    
    vec3 pos = rayDir*intersectionDistance;
    pos -= footPos;
    vec2 uv = vec2( dot(pos,normalize(cross(vec3(0,1,0),rayDir))), pos.y );
    float sdfValue = Humanoid( uv, seed );
    
    return vec2( intersectionDistance, sdfValue );
}

struct Camera {
    vec3 pos;
    vec3 target;
    float zoom;
};

void main(void)
{
    Camera cam;
    cam.pos = vec3(sin(time/4.)*4.,3.+1.*sin(time*1.618/5.),-6.+2.*cos(time*.618/2.));
    cam.target = vec3(1,1,6.);//-4.*cos(time/4.));
    cam.zoom = 1.7;
    
    vec3 ray = vec3( ( gl_FragCoord.xy-resolution.xy*.5 ) / resolution.y, cam.zoom );
    
    vec3 k = normalize( cam.target - cam.pos );
    vec3 i = normalize( cross( vec3(0,1,0), k ) );
    vec3 j = cross(k,i);
    
    ray = ray.x*i + ray.y*j + ray.z*k;

    vec3 standIns[] = vec3[](
        vec3(7,1,11),
        vec3(6.5,1,10.8),
        vec3(8,1,10),
        vec3(-1.7,1,5),
        vec3(-1.2,1,4.5),
        vec3(-2,1,4),
        vec3(-2.5,.5,3),
        vec3(2,1,3),
        vec3(1,1,2),
        vec3(0,1,2),
        vec3(4,0,3),
        vec3(4,0,1.5),
        vec3(3,0,2),
        vec3(3,0,1),
        vec3(1,0,.5),
        vec3(0)
    );
    
    vec4 fragColour = vec4(1);
    for ( int i=0; i < standIns.length(); i++ )
    {
        vec2 hit = StandIn( standIns[i], float(i), cam.pos, ray );
        float aa = hit.x*2./(resolution.x*cam.zoom); // soften the edges proportional to pixel size
        // this blend assumes we've depth-sorted the things, because I'm being lazy
        fragColour = mix( fragColour, vec4(1.-exp2(-hit.x/12.)), smoothstep(aa,-aa,hit.y) );// .5-.5*(hit.y/(abs(hit.y)+.002)) );
    }
    glFragColor=fragColour;
}
