#version 420

// original https://www.shadertoy.com/view/XsBczc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* hexwaves, by mattz
   License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

   Uses the hex grid traversal code I developed in https://www.shadertoy.com/view/XdSyzK

*/

// square root of 3 over 2
const float hex_factor = 0.8660254037844386;

const vec3 fog_color = vec3(0.9, 0.95, 1.0);

//////////////////////////////////////////////////////////////////////
// Used to draw top borders

float hexDist(vec2 p) {
    p = abs(p);
    return max(dot(p, vec2(hex_factor, 0.5)), p.y) - 1.0;
}

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
// From Dave Hoskins' https://www.shadertoy.com/view/4djSRW

#define HASHSCALE3 vec3(.1031, .1030, .0973)

vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

//////////////////////////////////////////////////////////////////////
// Return the cell height for the given cell center

float height_for_pos(vec2 pos) {
    
    // shift origin a bit randomly
    pos += vec2(2.0*sin(time*0.3+0.2), 2.0*cos(time*0.1+0.5));
    
    // cosine of distance from origin, modulated by Gaussian
    float x2 = dot(pos, pos);
    float x = sqrt(x2);
    
    return 6.0 * cos(x*0.2 + time) * exp(-x2/128.0);
    
}

vec4 surface(vec3 rd, vec2 rdelta, vec4 hit_nt, float bdist) {

    // fog coefficient is 1 near origin, 0 far way
    float fogc = exp(-length(hit_nt.w*rd)*0.02);

    // get the normal
    vec3 n = hit_nt.xyz;

    // add some noise so we don't just purely reflect boring flat cubemap
    // makes a nice "disco ball" look in background
    vec3 noise = (hash32(nearestHexCenter(rdelta))-0.5)*0.15;
    n = normalize(n + noise);

    // gotta deal with borders

    // need to antialias more far away
    float border_scale = 2.0/resolution.y;

    const float border_size = 0.04;

    float border = smoothstep(0.0, border_scale*hit_nt.w, abs(bdist)-border_size);

    // don't even try to draw borders too far away
    border = mix(border, 0.75, smoothstep(18.0, 45.0, hit_nt.w));

    // light direction
    vec3 L = normalize(vec3(3, 1, 4));

    // diffuse + ambient term
    float diffamb = (clamp(dot(n, L), 0.0, 1.0) * 0.8 + 0.2);

    // start out white
    vec3 color = vec3( 1.0 );

    // add in border color
    color = mix(vec3(0.1, 0, 0.08), color, border);

    // multiply by diffuse/ambient
    color *= diffamb;

    // cubemap fake reflection
    color = mix(color, vec3(0.0,0.0,0.0), 0.4*border);

    // fog
    color = mix(fog_color, color, fogc);
    
    return vec4(color, border);

}

//////////////////////////////////////////////////////////////////////
// Return the color for a ray with origin ro and direction rd

vec3 shade(in vec3 ro, in vec3 rd) {
        
    // the color we will return
    vec3 color = fog_color;

    // find nearest hex center to ray origin
    vec2 rdelta = nearestHexCenter(ro.xy);

    // get the three candidate wall normals for this ray (i.e. the
    // three hex side normals with positive dot product to the ray
    // direction)

    vec2 n0 = alignNormal(vec2(0.0, 1.0), rd.xy);
    vec2 n1 = alignNormal(vec2(hex_factor, 0.5), rd.xy);
    vec2 n2 = alignNormal(vec2(hex_factor, -0.5), rd.xy);

    // initial cell height at ray origin
    float cell_height = height_for_pos(rdelta);
    
    // reflection coefficient
    float alpha = 1.0;

    // march along ray, one iteration per cell
    for (int i=0; i<80; ++i) {
        
        // we will set these when the ray intersects
        bool hit = false;
        vec4 hit_nt;
        float bdist = 1e5;

        // after three tests, nt.xy holds the normal, nt.z holds the
        // ray distance parameter
        vec3 nt = rayHexIntersect(ro.xy-rdelta, rd.xy, n0);
        nt = rayMin(nt, rayHexIntersect(ro.xy-rdelta, rd.xy, n1));
        nt = rayMin(nt, rayHexIntersect(ro.xy-rdelta, rd.xy, n2));

        // try to intersect with top of cell
        float tz = (cell_height - ro.z) / rd.z;

        // if ray sloped down and ray intersects top of cell before escaping cell
        if (ro.z > cell_height && rd.z < 0.0 && tz < nt.z) {

            // set up intersection info
            hit = true;
            hit_nt = vec4(0, 0, 1.0, tz);   
            vec2 pinter = ro.xy + rd.xy * tz;

            // distance to hex border
            bdist = hexDist(pinter - rdelta);

        } else { // we hit a cell wall before hitting top.

            // update the cell center by twice the normal of intersection
            rdelta += 2.0*nt.xy;

            float prev_cell_height = cell_height;
            cell_height = height_for_pos(rdelta);

            // get the ray intersection point with cell wall
            vec3 p_intersect = ro + rd*nt.z;

            // if we intersected below the height, it's a hit
            if (p_intersect.z < cell_height) {

                // set up intersection info
                hit_nt = vec4(nt.xy, 0.0, nt.z);
                hit = true;

                // distance to wall top
                bdist = cell_height - p_intersect.z;

                // distance to wall bottom
                bdist = min(bdist, p_intersect.z - prev_cell_height);

                // distance to wall outer side corner
                vec2 p = p_intersect.xy - rdelta;
                p -= nt.xy * dot(p, nt.xy);
                bdist = min(bdist, abs(length(p) - 0.5/hex_factor));

            }

        }                      
        
        if (hit) {
            
            // shade surface
            vec4 hit_color = surface(rd, rdelta, hit_nt, bdist);
            
            // mix in reflection
            color = mix(color, hit_color.xyz, alpha);
            
            // decrease blending coefficient for next bounce
            alpha *= 0.17 * hit_color.w;
            
            // re-iniitialize ray position & direction for reflection ray
            ro = ro + rd*hit_nt.w;
            rd = reflect(rd, hit_nt.xyz);
            ro += 1e-3*hit_nt.xyz;
            
            // re-initialize hex marching params
            rdelta = nearestHexCenter(ro.xy);

            n0 = alignNormal(vec2(0.0, 1.0), rd.xy);
            n1 = alignNormal(vec2(hex_factor, 0.5), rd.xy);
            n2 = alignNormal(vec2(hex_factor, -0.5), rd.xy);

            cell_height = height_for_pos(rdelta);
            
        }

    }
    
    // use leftover ray energy to show sky
    color = mix(color, fog_color, alpha);
    
    return color;
    
}    

//////////////////////////////////////////////////////////////////////
// Pretty much my boilerplate rendering code, just a couple of 
// fancy twists like radial distortion and vingetting.

void main(void) {
    
    const float yscl = 720.0;
    const float f = 500.0;
    
    vec2 uvn = (gl_FragCoord.xy - 0.5*resolution.xy) / resolution.y;
    vec2 uv = uvn * yscl;
    
    vec3 pos = vec3(-12.0, 0.0, 10.0);
    vec3 tgt = vec3(0.);
    vec3 up = vec3(0.0, 0.0, 1.0);
    
    vec3 rz = normalize(tgt - pos);
    vec3 rx = normalize(cross(rz,up));
    vec3 ry = cross(rx,rz);
    
    // compute radial distortion
    float s = 1.0 + dot(uvn, uvn)*1.5;
     
    vec3 rd = mat3(rx,ry,rz)*normalize(vec3(uv*s, f));
    vec3 ro = pos;

    float thetax = -0.35 - 0.2*cos(0.031513*time);
    float thetay = -0.02*time;
    
    //if (mouse.xy*resolution.y > 10.0 || mouse.xy*resolution.x > 10.0) { 
    //    thetax = (mouse*resolution.xy.y - 0.5*resolution.y) * -1.25/resolution.y;
    //    thetay = (mouse*resolution.xy.x - 0.5*resolution.x) * 6.28/resolution.x; 
    //}

    float cx = cos(thetax);
    float sx = sin(thetax);
    float cy = cos(thetay);
    float sy = sin(thetay);
    
    mat3 Rx = mat3(1.0, 0.0, 0.0, 
                   0.0, cx, sx,
                   0.0, -sx, cx);
    
    mat3 Ry = mat3(cy, 0.0, -sy,
                   0.0, 1.0, 0.0,
                   sy, 0.0, cy);
    
    mat3 R = mat3(0.0, 0.0, 1.0,
                  -1.0, 0.0, 0.0,
                  0.0, 1.0, 0.0);
    
    rd = transpose(R)*Ry*Rx*R*rd;
    ro = transpose(R)*Ry*Rx*R*(pos-tgt) + tgt;

    vec3 color = shade(ro, rd);
    color = sqrt(color);
    
    vec2 q = gl_FragCoord.xy / resolution.xy;
    
    // stole iq's vingette code
    color *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );       

    glFragColor = vec4(color, 1.0);
    
}
