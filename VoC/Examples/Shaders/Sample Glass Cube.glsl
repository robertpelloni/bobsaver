#version 420

// original https://www.shadertoy.com/view/WdSczh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ABSORBTION vec3(0.1, 5.0, 2.0)
#define IOR 1.5
#define TIMESCALE 0.35
#define INTERNAL_REFLECTIONS 5

vec3 rotate ( vec3 p, vec3 r ) {
    p = vec3( p.x,                       p.y*cos(r.x)-p.z*sin(r.x), p.y*sin(r.x)+p.z*cos(r.x) );    // x-axis rotation
    p = vec3( p.x*cos(r.y)+p.z*sin(r.y), p.y,                      -p.x*sin(r.y)+p.z*cos(r.y) );    // y-axis rotation
    p = vec3( p.x*cos(r.z)-p.y*sin(r.z), p.x*sin(r.z)+p.y*cos(r.z), p.z                       );    // z-axis rotation
    return p;                                                                                        // return rotated vector
}

float IntersectCube ( vec3 ro, vec3 rd ) {
    vec3 tmin = (vec3( 0.5)-ro)/rd;                        // distances to positive bounding planes for an axis-aligned unit cube at (0,0,0)
    vec3 tmax = (vec3(-0.5)-ro)/rd;                        // distances to negative bounding planes for an axis-aligned unit cube at (0,0,0)
    vec3 rmin = min(tmin, tmax);                        // distances to front-facing planes
    vec3 rmax = max(tmin, tmax);                        // distances to back-facing planes
    float dback  = min( min(rmax.x, rmax.y), rmax.z );    // distance to nearest back-facing side
    float dfront = max( max(rmin.x, rmin.y), rmin.z );    // distance to furthest front-facing side (possible collision distance)
    return dback>=dfront ? dfront : -1.0;                // distance to front of cube (-1.0 if miss)
}

float InteriorCubeReflection ( vec3 ro, vec3 rd ) {
    vec3 tmin = (vec3( 0.5)-ro)/rd;                        // distances to positive bounding planes for an axis-aligned unit cube at (0,0,0)
    vec3 tmax = (vec3(-0.5)-ro)/rd;                        // distances to negative bounding planes for an axis-aligned unit cube at (0,0,0)
    vec3 rmax = max(tmin, tmax);                        // distances to back-facing planes
    return min( min(rmax.x, rmax.y), rmax.z );            // distance to nearest back-facing side
}

float GetReflectance ( vec3 i, vec3 t, vec3 nor, float iora, float iorb ) {
    float cosi = dot(i,nor);                                                    // cosine of angle between incoming ray and normal
    float cost = dot(t,nor);                                                    // cosine of angle between refracted ray and normal
    float spr = pow( (cosi/iorb - cost/iora) / (cosi/iorb + cost/iora), 2.0 );    // calculate r-polarized Fresnel reflectance
    float spp = pow( (cost/iorb - cosi/iora) / (cost/iorb + cosi/iora), 2.0 );    // calculate p-polarized Fresnel reflectance
    return ( spr + spp ) / 2.0;                                                    // average polarized reflectances for unpolarized light
}

vec3 GetSky ( vec3 rd ) {
    rd = rotate(rd, vec3(3.1415/4.0));                                            // rotate sky (for more interesting reflections in cube)
    vec3 room = vec3( max( max( abs(rd).x, abs(rd).y ), abs(rd).z ) );            // draw quick 'box' (white on axes, darker 'corners')
    room = pow( room, vec3(1.5) );                                                // darken shadows in corners
    if( abs(rd).x>max(abs(rd).y,abs(rd).z) ) room -= vec3(0.5,0.0,1.0);           // paint x-axis walls green
    if( abs(rd).y>max(abs(rd).x,abs(rd).z) ) room -= vec3(0.8,0.3,0.0);           // paint y-axis walls blue
    if( abs(rd).z>max(abs(rd).x,abs(rd).y) ) room -= vec3(0.0,0.0,1.0);           // paint z-axis walls yellow
    return room;                                                                  // return sky colour
}

vec3 GetRenderSample ( vec3 ro, vec3 rd ) {
    float rl = IntersectCube( ro, rd );                                    // find intersection distance between camera ray and cube
    
    if ( rl > 0.0 ) {                                                    // did the camera ray hit the cube?
        
        vec3 xyz = ro + rd*rl;                                            // ray hit the cube - get intersection coordinates
        vec3 nor = round( xyz*1.00001 );                                // calculate surface normal for axis-aligned unit cube
        vec3 power = vec3(1.0);                                            // attenuated contribution of light path
        vec3 refractd = refract( rd, nor, 1.0/IOR );                    // get ray vector refracted into cube
        vec3 reflectd = reflect( rd, nor );                                // get ray vector reflected off of cube
        float refl = GetReflectance ( rd, refractd, nor, 1.0, IOR );    // get fraction of light that is reflected
        vec3 c = GetSky(reflectd) * refl;                                // calculate colour of ray reflected off surface of cube
        power *= 1.0-refl;                                                // attenuate influence of refracted ray
        rd = refractd;                                                    // reorient camera ray along refracted ray path

        for ( int i=0; i<INTERNAL_REFLECTIONS; i++ ) {                    // for each light ray traced inside of the cube...
            rl = InteriorCubeReflection( xyz, rd );                        // get length of reflected ray inside cube
            xyz += rd*rl;                                                // move to new intersection coordinates
            nor = round( xyz*1.00001 );                                    // calculate surface normal for axis-aligned unit cube
            refractd = refract( rd, -nor, 1.0/IOR );                    // get refracted ray direction
            reflectd = reflect( rd, -nor );                                // get reflected ray direction
            refl = GetReflectance ( rd, refractd, -nor, IOR, 1.0 );        // get fraction of light that is reflected
            power *= pow( vec3(2.71828), -ABSORBTION*vec3(rl) );        // calculate absorbtion with Beer's Law
            c += GetSky(refractd) * (1.0-refl) * power;                    // add light that is refracted out of cube
            power *= refl;                                                // attenuate influence of next reflected ray
            rd = reflectd;                                                // move to reflected path for next calculation
        }
        return c;                                                        // return cube colour along camera ray
    } else {
        return GetSky(rd);                                                // ray missed the cube - return background colour
    }
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy*2.0 - 1.0;                    // get camera-space position of pixel (-1 => 1)
    uv.y *= resolution.y/resolution.x;                                // stretch y-axis to equalize length of x and y units
    
    vec3 campos = vec3(0.0, 0.0, -2.5);                                    // set camera back -2.5 units from center of cube
    vec3 camray = normalize( vec3(uv,1.0) );                            // get camera ray vector for camera pointed at origin (FOV = PI/2)
    campos = rotate(campos, vec3(time*TIMESCALE));                        // rotate camera around cube
    camray = rotate(camray, vec3(time*TIMESCALE));                        // rotate camera rays to face cube
    
    vec3 col = GetRenderSample( campos, camray );                        // get pixel colour along camera ray path
    col = pow( col, vec3(0.4545) );                                        // gamma correction
    glFragColor = vec4( col, 1.0 );                                        // return final pixel colour
}
