#version 420

// original https://www.shadertoy.com/view/7ls3z2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 10
#define MAX_DIST 10.
#define SURF_DIST .1

float julia( vec2 p, float time )
{
    float ltime = 0.5-0.5*cos(time*0.36);
    float zoom = pow( 0.9, 30.0*ltime );
    vec2 cen = vec2( 0.2055,0.01) + zoom*1.8;//*cos(4.0+2.0*ltime); 
    vec2 c = vec2( -0.745, 0.186 ) - 0.245*zoom*(1.0-ltime*0.5);
    vec2 z = cen + (p-cen)*zoom;
   
    vec2 dz = vec2( 1.0, 0.0 );
    for( int i=0; i<60; i++ )
    {
        dz = 2.0*vec2(z.x*dz.x-z.y*dz.y, z.x*dz.y + z.y*dz.x );
        z = vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + c;
        if( dot(z,z)>200.0 ) break;
    }
    float d = sqrt( dot(z,z)/dot(dz,dz) )*log(dot(z,z));
    
    return sqrt( clamp( (1.0/zoom)*d, 0.0, 1.0 ) );
}

float GetDistance(vec3 point) {
    return julia(vec2(point.x,point.y), point.z+time);
}

float RayMarch(vec3 rayOrgin, vec3 rayDirection) {
    float distance=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 point = rayOrgin + rayDirection * distance;
        float surfaceDistance = GetDistance(point);
        distance += surfaceDistance;
        // Stop marching if we go too far or we are close enough of surface
        if(distance>MAX_DIST || surfaceDistance<SURF_DIST) break;
    }
    
    return distance;
}

void main(void)
{
    // put 0,0 in the center
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
       
    // camera   
    vec3 rayOrgin = vec3(0, 1, 0);
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1));

    float d = RayMarch(rayOrgin, rayDirection);
    
    vec3 col = vec3(d/100.,d/15.+uv.y,d/5.);
    
    glFragColor = vec4(col,1.0);
}
