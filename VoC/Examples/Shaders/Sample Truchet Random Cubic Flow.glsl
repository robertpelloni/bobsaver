#version 420

// original https://www.shadertoy.com/view/MtSyRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
    random cubic Truchet flow, by mattz
    License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

    Inspired by:

      Truchet Marbles (Simple) by shau - https://www.shadertoy.com/view/MtlcDs
      Square Truchet Flow by Shane - https://www.shadertoy.com/view/XtfyDX

    Keys:

      D - toggle direction arrows (rotations/reflections of canonical cell)
      M - toggle camera motion
      S - toggle spheres
      T - toggle Truchet torii
      X - toggle X-axis alternation

    Mouse to bottom-left to get default viewing angle.

    Analogous to Shane's 2D shader, this fixes the flow directions along cube faces
    in a repeating fashion. I randomize the torus orientations while confirming to the
    predetermined flow directions.

    See the documentation of the truchet function below for the meat.

    This calls atan to do the shading along each torus segment, but I make sure
    to only call it once per pixel when actually shading. 

*/

// Bunch of globals/constants:
const int rayiter = 60;
const float dmax = 20.0;
vec3 L = normalize(vec3(-0.7, 1.0, -1.0));
mat3 Rview;

float move_camera = 1.0;
float show_spheres = 1.0;
float show_directions = 0.0;
float show_truchet = 1.0;
float alternate_x = 1.0;

const float HALFPI = 1.5707963267948966;
const float TUBE_SIZE = 0.015;
const float SPHERE_SIZE = 0.06;

const float ARROW_RAD = 0.025;
vec2 ARROW_HEAD_SLOPE = normalize(vec2(1, 2));
    
const float ARROW_BODY_LENGTH = 0.3;
const float ARROW_HEAD_LENGTH = 0.1;

/* RGB from hue. */
vec3 hue(float h) {
    vec3 c = mod(h*6.0 + vec3(2, 0, 4), 6.0);
    return h >= 1.0 ? vec3(h-1.0) : clamp(min(c, -c+4.0), 0.0, 1.0);
}

/* Rotate about x-axis */
mat3 rotX(in float t) {
    float cx = cos(t), sx = sin(t);
    return mat3(1., 0, 0, 
                0, cx, sx,
                0, -sx, cx);
}

/* Rotate about y-axis */
mat3 rotY(in float t) {
    float cy = cos(t), sy = sin(t);
    return mat3(cy, 0, -sy,
                0, 1., 0,
                sy, 0, cy);

}

/* From https://www.shadertoy.com/view/4djSRW */
#define HASHSCALE1 .1031

float hash13(vec3 p3) {
    p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

/* Distance to 3D arrow - steal this if you like! */
float sdArrow(vec3 p, vec3 d) {
    
    // component along
    float t = dot(p, d);
    
    // component perp
    float n = length(p - t*d);
    
    // distance to cylinder body
    float dist = n - ARROW_RAD;
    
    // account for arrowhead size
    t += 0.5*ARROW_HEAD_LENGTH;
    
    // body caps
    dist = max(dist, abs(t)-0.5*ARROW_BODY_LENGTH);
    
    // move to end of arrow
    t -= 0.5*ARROW_BODY_LENGTH;
    
    // cone head
    dist = min(dist, max(-t, dot(ARROW_HEAD_SLOPE, vec2(t-ARROW_HEAD_LENGTH, n))));
    
    return dist;
    
}

/* Check distance to an "oriented" torus quadrant in the unit cube with vertices
   at +/- 0.5:

    - p is point in cube
    - src is outward facing normal of flow source side 
    - dst is outward facing normal of flow sink

   Returns a mat3 whose rows are src, dst, and (ux uy d) where:

     - ux is negative distance of p along src axis (so positive inside cube)
     - uy is negative distance of p along dst axis (again, positive inside cube)
     - d is distance to torus.

*/
mat3 checkTorus(vec3 p, vec3 src, vec3 dst) {
    
    vec3 n = cross(dst, src);
    vec3 ctr = 0.5*(src+dst);
    
    p -= ctr;
    
    vec3 u = p * mat3(src, dst, n);
    
    vec2 q = vec2(length(u.xy)-0.5,u.z);
    float d = length(q) - TUBE_SIZE;
    d = max(d, max(u.x, u.y));

    return mat3(src, dst, vec3(-u.xy, d));
    
}

/* Chooses matrix with least last element (useful for comparing checkTorus output) */
mat3 tmin(mat3 a, mat3 b) {
    
    return a[2].z < b[2].z ? a : b;
    
}

/* Distance to ball along torus segment. See sdTorus description above
   for parameter descriptions. */
float sdBall(vec3 p, vec3 src, vec3 dst) {
    
    vec3 ctr = 0.5*(src+dst);
    
    p -= ctr;

    float theta = HALFPI * fract(0.2*time);
    float s = sin(theta);
    float c = cos(theta);
    
    // Need multiple checks to handle ball crossing cube face boundaries!
    float d = length(p + 0.5*(s*src + c*dst));
    d = min(d, length(p + 0.5*(c*src - s*dst)));
    d = min(d, length(p + 0.5*(-c*src + s*dst)));
    
    return d - SPHERE_SIZE;

}

/* This is the workhorse of the Truchet arrangement. Input argument is
   an arbitrary 3D point, which is modified to become relative to cell
   center and orientation upon output. Also outputs a mat3 of the format
   output by sdTorus above. 

   As you can see by enabling cell directions, every cubic cell in the
   Truchet tiling has three flow inputs and three outputs. The "canonical 
   cell" has flow inputs on the +X, -Y, and +Y faces (and flow outputs on
   the -X, -Z, +Z) faces.

   In order to get these to tile space, we need to swap Y with Z in a
   checkerboard pattern along the YZ plane.

   Also, it looks obviously "fake" (in my opinion, at least) to have all 
   of the flow from +X to -X, so I also alternate the X direction on
   successive Y levels. 

   So, we now have the "canonical cell" potentially with Y/Z swapped, and/or
   X negated. There are four possible torus segment arrangements within 
   the canonical cell. The table below shows for each input face (+X, -Y, +Y),
   what output face it connects to:

     case | +X -Y +Y
     -----+----------
        0 | -Z -X +Z
        1 | -Z +Z -X
        2 | +Z -X -Z
        3 | +Z -Z -X
       
   We choose one of these cases at random for each cell, and get the torus 
   distance for the given point.

*/
mat3 truchet(inout vec3 pos) {
    
    // Shift by 0.5 to place world origin at vertex, not cell center
    pos -= 0.5;
    
    // Find center of nearest cell
    vec3 ctr = floor(pos+0.5);
    
    // Subtract off difference
    pos -= ctr;
    
    // Alternating sign on each axis
    vec3 s = sign(mod(ctr, 2.0) - 0.5);
    
    // Swap Y and Z in checkerboard pattern.
    if (s.y * s.z > 0.0) { pos.yz = pos.zy; }

    // Alternate sign on X within cell if desired
    if (alternate_x > 0.0) { pos.x *= -s.y; }

    // Get case and set up destination axes
    float k = hash13(ctr) * 4.0;
    
    mat3 dst = mat3(0, 0, -1, 
                    -1, 0, 0, 
                    0, 0, 1);                
    
    if (k < 2.0) {
        if (k < 1.0) {
            // NOP - just use setup above
            // dst = dst
        } else {
            dst = mat3(dst[0], dst[2], dst[1]); 
        }
    } else {
        if (k < 3.0) {
            dst = mat3(dst[2], dst[0], dst[1]); 
        } else {
            dst = mat3(dst[2], dst[1], dst[0]); 
        }
    }
    
    // Handle +X face
    mat3 t = checkTorus(pos, vec3(1, 0, 0), dst[0]);
    
    // Handle +Y face
    t = tmin(t, checkTorus(pos, vec3(0, 1, 0), dst[1]));
    
    // Handle -Y face
    t = tmin(t, checkTorus(pos, vec3(0, -1, 0), dst[2]));
    
    return t;
    
}

/* Boolean union of solids for map function below */
vec2 dmin(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

/* Distance function to scene */
vec2 map(in vec3 pos) {    
    
    mat3 t = truchet(pos);
    
    vec2 dm = vec2(1e5, -1);
    
    if (show_truchet != 0.0) {
        dm = dmin(dm, vec2(t[2].z, 2.0));
    }
    
    if (show_spheres != 0.0) {
        dm = dmin(dm, vec2(sdBall(pos, t[0], t[1]), 1.1));
    }
    
    if (show_directions != 0.0) {
        dm = dmin(dm, vec2(sdArrow(pos - vec3(0.5, 0, 0), vec3(-1, 0, 0)), 0));
        dm = dmin(dm, vec2(sdArrow(pos + vec3(0.5, 0, 0), vec3(-1, 0, 0)), 0));
        dm = dmin(dm, vec2(sdArrow(pos - vec3(0, 0.5, 0), vec3(0, -1, 0)), 0.3333));
        dm = dmin(dm, vec2(sdArrow(pos + vec3(0, 0.5, 0), vec3(0, 1, 0)), 0.3333));
        dm = dmin(dm, vec2(sdArrow(pos - vec3(0, 0, 0.5), vec3(0, 0, 1)), 0.6666));
        dm = dmin(dm, vec2(sdArrow(pos + vec3(0, 0, 0.5), vec3(0, 0, -1)), 0.6666));
    }

    return dm;

}

/* IQ's normal calculation. */
vec3 calcNormal( in vec3 pos ) {
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

/* IQ's distance marcher. */
vec2 castRay( in vec3 ro, in vec3 rd, in float maxd ) {

    const float precis = 0.002;   
    float h=2.0*precis;

    float t = 0.0;
    float m = -1.0;

    for( int i=0; i<rayiter; i++ )
    {
        if( abs(h)<precis||t>maxd ) continue;//break;
        t += h;
        vec2 res = map( ro+rd*t );
        h = res.x;
        m = res.y;        
    }    

    if (t > maxd) {
        m = -1.0;
    }

    return vec2(t, m);

}

/* Only clever thing about the shading is to postpone the expensive atan call
   until the last possible second. It should buy us a bit of framerate on 
   slower cards, but I was getting 60FPS before I decided to do this. Meh.
 */
vec3 shade( in vec3 ro, in vec3 rd ){

    vec2 tm = castRay(ro, rd, dmax);        

    vec3 c;

    if (tm.y < 0.0) { 

        // miss
        return vec3(1.0);

    } else {        

        // hit
        vec3 pos = ro + tm.x*rd;
        vec3 n = calcNormal(pos);

        
        if (tm.y >= 2.0) { 
            // material 2 means we hit a torus, so use atan-based rainbow map
            mat3 t = truchet(pos);
            tm.y = fract( atan(t[2].y, t[2].x)/HALFPI - 0.25*time );
        }

        vec3 color = hue(tm.y);

        vec3 diffamb = (0.5*clamp(dot(n,L), 0.0, 1.0)+0.5) * color;
        vec3 R = 2.0*n*dot(n,L)-L;
        float spec = 0.3*pow(clamp(-dot(R, rd), 0.0, 1.0), 20.0);
        vec3 c = diffamb + spec;
        
        return mix(c, vec3(1), 1.0-exp(-0.25*tm.x));

    }

}

/* Compare key state to default state. */
float keyState(float key, float default_state) {
    return abs( default_state );
}

const float KEY_D = 68.5/256.0;
const float KEY_M = 77.5/256.0;
const float KEY_S = 83.5/256.0;
const float KEY_T = 84.5/256.0;
const float KEY_X = 88.5/256.0;

/* Finally, our main function: */
void main(void) {
    
    show_directions = keyState(KEY_D, show_directions);
    move_camera = keyState(KEY_M, move_camera);
    show_truchet = keyState(KEY_T, show_truchet);
    show_spheres = keyState(KEY_S, show_spheres);
    alternate_x = keyState(KEY_X, alternate_x);

    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) * 0.8 / (resolution.y);
    
    const vec3 tgt = vec3(0.0, 0.0, 0.0);
    const vec3 cpos = vec3(0, 0, 5);
    const vec3 up = vec3(0, 1, 0);

    vec3 rz = normalize(tgt - cpos),
        rx = normalize(cross(rz,vec3(0,1.,0))),
        ry = cross(rx,rz);

    vec2 mpos;

    //if (max(mouse*resolution.xy.x, mouse*resolution.xy.y) > 20.0) { 
    //    mpos.xy = mouse*resolution.xy.xy;
    //} else {
        mpos = resolution.xy * vec2(0.432, 0.415);
    //}
    
    float thetax = (mpos.y - .5*resolution.y) * -4.0*HALFPI/resolution.y; 
    float thetay = (mpos.x - .5*resolution.x) * 8.0*HALFPI/resolution.x; 

    Rview = mat3(rx,ry,rz)*rotY(thetay)*rotX(thetax); 
    L = Rview*L;

       /* Render. */
    vec3 rd = Rview*normalize(vec3(uv, 1.)),
        ro = tgt + Rview*vec3(0,0,-length(cpos-tgt));
    
    if (move_camera != 0.0) {
        ro -= 0.15*time;
    }

    glFragColor.xyz = shade(ro, rd);

}
