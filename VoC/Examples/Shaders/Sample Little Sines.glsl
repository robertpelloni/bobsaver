#version 420

// original https://www.shadertoy.com/view/Nl2Szw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926538

void main(void)
{
    vec2 uv = gl_FragCoord.xy/(resolution.xy / 2.0);  // range from 0 to 2, so we can have x in [-1,1], y in [-1,1]
    uv = uv - vec2(1.0,1.0); // move the origin to the centre of the circle/noramlised space
    
    float frequency = 8.0; // number of cycles for sine wave, matches crest & dip counts
    float amplitude = 0.10; // we actually experience +/- of this value so 2 of it in length
    
    float circle_radius = 0.8; // this is the radius of the circle before the sine wave gets involved, account for +/- 1 of the amplitude
    float edge_width = 0.02; // On a disk this is the fade off at the edge, on a line, this the fade off either side
    
    
    
    // Disc Version
    //float colour = smoothstep(circle_radius - edge_width, circle_radius, length(uv) + (sin(atan(uv.y, uv.x) * frequency - 3.141 / 2.0) * amplitude));
    // NOTE: PI/2 is just a constant that aligns the crests with the x/y axis by rotating in x/y, space, but really just offseting our angle that the sine is driven by
    
    // Line Version
    //colour = smoothstep( 0.0, edge_width, abs( circle_radius - length(uv) + (sin(atan(uv.y, uv.x) * frequency - 3.141 / 2.0) * amplitude)));
    
    

    // Lines & Discs
    // A line we want to be a certain distance either side of the radius
    // A disc we want to be above and below the radius
    // Essentially the core difference is either just using the distance from the centre, or the the distance from the radius itself
    
    // Circle Line
    // colour = smoothstep(0.0, 0.01, abs(circle_radius- length(uv)));
    // This essentially says we only accept points 0.01 from our
    
    // Circular Disc
    // colour = smoothstep(circle_radius - 0.01, circle_radius, length(uv));
    // 0.01 is the distance of the fade at the egdes for both
    
    
    // Smooth step
    // everything less than first edge is 0
    // everything greater than second edge is 1
    // when inbetween, the interpolate between the two edges to give you values between 0 & 1
   
    
    
    float centre_angle = atan(uv.y, uv.x);
    // Using the two argument of atan gives nicer results as it handles some of the jankeness around +/- axes and the undefined point
    // https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/atan.xhtml

    
    float sine_distortion_1 =  (sin(centre_angle *  frequency        + time) * amplitude);
    float sine_distortion_2 = -(sin(centre_angle * (frequency / 2.0) + time) * amplitude); 
    float sine_distortion_3 =  (sin(centre_angle * (frequency / 4.0) + time) * amplitude);
    float sine_distortion_4 = -(sin(centre_angle * (frequency / 8.0) + time) * amplitude);
    // Can cause desync (disconnect in graph) when uv.x = 0. Depends on if they even or odd frequency divisors and if they sync up or not at that value
    // Sticking to even divisors of an even frequency is kosher!

    float flare_shape_1 = smoothstep(edge_width, 0.0, abs(circle_radius - 0.25 - length(uv) - sine_distortion_1 + sine_distortion_2));
    float flare_shape_2 = smoothstep(edge_width, 0.0, abs(circle_radius - 0.18 - length(uv) + sine_distortion_1 + sine_distortion_4));
    float flare_shape_3 = smoothstep(edge_width, 0.0, abs(circle_radius - 0.11 - length(uv) + sine_distortion_2 + sine_distortion_3));
    float flare_shape_4 = smoothstep(edge_width, 0.0, abs(circle_radius - 0.03  - length(uv) + sine_distortion_1 + sine_distortion_2 + sine_distortion_3 + sine_distortion_4));
    
    //flare_shape_1 = 1. - (1.-flare_shape_1)*(1.-flare_shape_1)*(1.-flare_shape_1)*(1.-flare_shape_1);
    
    // Colouring
    vec4 flare_1 = vec4(flare_shape_1 * vec3(0.1,1.0,1.0), 1.0); // blue
    vec4 flare_2 = vec4(flare_shape_2 * vec3(0.9,0.1,0.5), 1.0); // pink
    vec4 flare_3 = vec4(flare_shape_3 * vec3(1.0,1.0,1.0), 1.0); // white
    vec4 flare_4 = vec4(flare_shape_4 * vec3(1.0,0.9,0.1), 1.0); // yellow
    
    
    // Segment
    
    //float moving_angle = mod(time, 2. * PI) - PI; // want a value that runs from -PI to PI with time
    
    float flare_length = PI;
    float angle_offset = PI / 6.;
    
    float min_angle = mod(time * 1.2, 2. * PI) - PI;
    float max_angle = mod(time * 1.2 + flare_length, 2. * PI) - PI;
    
    if(min_angle > max_angle)
    {
        if(centre_angle < max_angle) centre_angle += 2. * PI;
        
        max_angle += 2.* PI;
    }
    
    float visible_angle_distance = (max_angle - min_angle);
    float t = (centre_angle - min_angle) / visible_angle_distance;
    
    t *= t *t; // effect the tail drop off
    
    flare_1 *= t* step(min_angle, centre_angle) *step(centre_angle, max_angle);
    flare_2 *= t* step(min_angle, centre_angle) *step(centre_angle, max_angle);
    flare_3 *= t* step(min_angle, centre_angle) *step(centre_angle, max_angle);
    flare_4 *= t* step(min_angle, centre_angle) *step(centre_angle, max_angle);
   
    
    glFragColor = flare_1 + flare_2 + flare_3 + flare_4;
}
