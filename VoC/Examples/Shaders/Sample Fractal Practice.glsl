#version 420

// original https://www.shadertoy.com/view/XsyfWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FieldOfView 1.
#define gt time * 0.1 // to make tunnel next
//#define sgt(i) abs(sin(i * time))
#define Giter 5 //iterations of the glowing lines fractal

float DE(in vec3 z)
{    
    /* Folding 'tiling' of 3D space;
    z  = abs(1.0-mod(z,2.0));   */

    z = fract(z);// + 0.1*fract(2.*z);

    float d =length(z.xy-vec2(0.5));
    d = min(d, length(z.xz-vec2(0.5)));
    d = min(d, length(z.yz-vec2(0.5)));
    
    return d-0.01;
}
    
vec3 Glow(vec3 z, float b){
    z = fract( z + 2.0) * 2. -1.; // divides plane again

    //z.z = b; // THIS PART MAKES THE FLASHES!
    for( int i = 0; i < Giter; ++i){ 
        float d = clamp( dot(z, z), .05, .65); 
        z = abs( z ) / d - 1.31;
    }
    //z.x += 0.2;
    return z;
}

vec3 fog(float a,vec3 b,float c){ 
    //a *= c;
    return 1. / (( 1. + 2.*b/a + b * b/(a*a))*c ); // must be a fog function
}

// taes vec3 from Glow, v (random), u (ball at end of raytracer), and an int that is the transparency
vec3 W(vec3 fr,float b,float c,float d){
    vec3 e= fog(0.01, abs(fr), d) * 2.; 
    return (e * 7. + e.yzx * 1.5 + e.zxy * 1.5) * max( 1. -c * 200. / d, 0. ) / d * 70.;
}

void main(void) {
    float A = 3. * time;
    vec2 uv = gl_FragCoord.xy / resolution.xy *2. -1.;
    uv.x *= resolution.x/resolution.y;

    vec3 base = vec3(.2, 0.5*sin(0.01*time), 0.5*cos(0.01*time));
    //vec3 base = vec3(1.0, 0.7, 0.8);

    vec3 camPos = 0.5*time * base;
    vec3 target = camPos + base;
    vec3 camUp  = vec3(1.0,1.0,0.0);

    vec3 camDir   = normalize(target-camPos); // direction for center ray
    camUp = normalize(camUp-dot(camDir,camUp)*camDir); // orthogonalize
    vec3 camRight = normalize(cross(camDir,camUp));

    vec3 rayDir = normalize( (camRight * uv.x  + camUp * uv.y + camDir));
    vec3 pos, color; float totalDistance, distance, v;

    for(int i = 0; i < 32; ++i){
        pos = camPos + rayDir * totalDistance;
        distance = min(abs(fract( pos.z ) - 0.5), DE(pos));
        v = sin( A * .01 + pos.z);
        vec3 x = Glow( pos, v);
        totalDistance += distance  + .001; 
        color += ( W( x, v, distance, 0.5) ) * (distance + 0.001);
    }
    glFragColor = vec4( pow( color, vec3( .45 )), .5);
}
