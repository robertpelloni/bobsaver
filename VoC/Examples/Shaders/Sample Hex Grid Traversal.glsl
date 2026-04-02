#version 420

// original https://www.shadertoy.com/view/XdSyzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Hex grid marching, by mattz
   License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

   Click and drag to set ray direction.

   Much of the code below could be simplified/optimized. 

*/

// square root of 3 over 2
const float hex_factor = 0.8660254037844386;

//////////////////////////////////////////////////////////////////////
// Given a 2D position, find center of nearest hexagon in plane.

vec2 nearestHexCenter(in vec2 pos) {
    
    // integer coords in hex center grid -- will need to be adjusted 
    vec2 hex_int = floor(vec2(pos.x/hex_factor, pos.y));

    // adjust integer coords
    float sy = step(2.0, mod(hex_int.x+1.0, 4.0));
    hex_int += mod(vec2(hex_int.x, hex_int.y + sy), 2.0);

    // cartesian center of hexagon
    vec2 hex_pos = hex_int * vec2(hex_factor, 1.0);

    // difference vector
    vec2 diff = pos - hex_pos;

    // figure out which side of line we are on and modify
    // hex center if necessary
    if (dot(abs(diff), vec2(hex_factor, 0.5)) > 1.0) {
        vec2 delta = sign(diff) * vec2(2.0, 1.0);
        hex_int += delta;
        hex_pos = hex_int * vec2(hex_factor, 1.0);
    }

    return hex_pos;
    
}

//////////////////////////////////////////////////////////////////////
// Flip normal if necessary to have positive dot product with d

vec2 alignNormal(vec2 n, vec2 d) {
    return n*sign(dot(n, d));
}

//////////////////////////////////////////////////////////////////////
// Intersect a ray with a hexagon wall with normal n

vec3 rayHexIntersect(vec2 ro, vec2 rd, vec2 n) {

    // solve for u such that dot(n, ro+u*rd) = 1.0
    float u = (1.0 - dot(n, ro)) / dot(n, rd);

    // return the 
    return vec3(n, u);

}

//////////////////////////////////////////////////////////////////////
// Choose the vector whose z coordinate is minimal

vec3 rayMin(vec3 a, vec3 b) {
    return a.z < b.z ? a : b;
}

//////////////////////////////////////////////////////////////////////
// Triangle wave - used only for visualization

float tri(float x) {
    return abs(0.5*x-floor(0.5*x)-0.5)*2.0;
}

//////////////////////////////////////////////////////////////////////
// Used only for visualization

float hexDist(vec2 p) {
    p = abs(p);
    return max(dot(p, vec2(hex_factor, 0.5)), p.y) - 1.0;
}

//////////////////////////////////////////////////////////////////////
// From Dave Hoskins' https://www.shadertoy.com/view/4djSRW

#define HASHSCALE1 .1031

float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//////////////////////////////////////////////////////////////////////
// Main function

void main(void) {

    float scl = 10.5 / resolution.y;

    float ray_width = max(0.04, 0.5*scl);
    float dot_size = max(0.125, 4.0*scl);
    float gridline_width = max(0.01, 0.125*scl);
    float outline_dist = max(0.15, 3.0*scl);

    //////////////////////////////////////////////////
    // get fragment position
    vec2 pos = (gl_FragCoord.xy + 0.5 - .5*resolution.xy) * scl;

    //////////////////////////////////////////////////
    // get ray origin and direction
    
    float t = 0.2*time;
    vec2 ro = vec2(2.5*sin(1.732*t), -2.5*sin(1.0532*t));

    vec2 mouse = mouse*resolution.xy.xy;
    if (mouse*resolution.xy.x == 0.0) {
        mouse = 0.5*resolution.xy;
    }

    vec2 rd = (mouse - 0.5*resolution.xy) * scl - ro;

    //////////////////////////////////////////////////
    // start visualizing ray

    float u_vis = max(0.0, dot(pos-ro, rd) / dot(rd, rd));

    float ray_line_dist = length(pos - ro - u_vis*rd);
    float ray_dot_dist = length(pos - ro);
    
    //////////////////////////////////////////////////
    // set up ray hex grid traversal

    // find nearest hex center to ray origin
    vec2 ro_hex_pos = nearestHexCenter(ro);

    // get the three candidate wall normals for this ray (i.e. the
    // three hex side normals with positive dot product to the ray
    // direction)

    vec2 n0 = alignNormal(vec2(0.0, 1.0), rd);
    vec2 n1 = alignNormal(vec2(hex_factor, 0.5), rd);
    vec2 n2 = alignNormal(vec2(hex_factor, -0.5), rd);

    // instead of moving the hexagon center as we traverse the hex
    // grid, we will translate the ray origin in the opposite
    // direction
    vec2 rdelta = ro_hex_pos;

    // march along ray, one iteration per cell
    for (int i=0; i<8; ++i) {

        // after three tests, nt.xy holds the normal, nt.z holds the
        // ray distance parameter
        vec3 nt = rayHexIntersect(ro-rdelta, rd, n0);
        nt = rayMin(nt, rayHexIntersect(ro-rdelta, rd, n1));
        nt = rayMin(nt, rayHexIntersect(ro-rdelta, rd, n2));

        // we will always move by twice the unit normal of the
        // intersection
        rdelta += 2.0*nt.xy;

        // get the ray intersection point for visualization
        vec2 p_intersect = ro + rd*nt.z;

        // visualization
        ray_dot_dist = min(ray_dot_dist, length(pos - p_intersect));

    }

    //////////////////////////////////////////////////
    // visualization

    vec2 hex_pos = nearestHexCenter(pos);
    
    float d = abs(hexDist(pos - hex_pos));

    vec3 c;

    // hex color
    if (hex_pos == ro_hex_pos) {
        float k = tri(7.0*d  - 2.0*time);
        c = mix(vec3(0.7, 0.2, 0.5), vec3(0.2), 0.3*k);
    } else {
        float k = tri(7.0*d + 1.0);
        c = mix(vec3(0.45, 0.55, 0.6), vec3(0.6), hash12(hex_pos + 14.0));
        c = mix(c, vec3(0.8), k*0.25);
    }

    // grid lines
    c *= smoothstep(0.0, scl, d-gridline_width);

    const vec3 ray_color = vec3(1.0, 0.85, 0);

    // line shadow
    c = mix(c, vec3(0),
            0.5*smoothstep(outline_dist, 0.0, ray_line_dist-ray_width));

    // line 
    c = mix(c, ray_color,
            smoothstep(scl, 0.0, ray_line_dist-ray_width));
    
    // dot shadow
    c = mix(c, vec3(0),
            0.5*smoothstep(outline_dist, 0.0, ray_dot_dist-dot_size));

    // dot
    c = mix(ray_color, c, smoothstep(0.0, scl, ray_dot_dist-dot_size));
    
    glFragColor = vec4(c, 1.0);
            
}
